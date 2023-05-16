#!/bin/bash

echo "Inicio do script."

# Obter o dia atual formatado
dia_atual=$(date +%Y%m%d)

echo "Dia de execuxão: $dia_atual"

#caminho para o arquivo de conexões dé de 15 min em 15 min
arquivo="/ext3/backup_logs/sgtela/$dia_atual/conexoes.log"

arquivo_sgtela="/ext3/backup_logs/sgtela/$dia_atual/sgtela.log"

echo "Iniciando buscas."
echo "Iniciando busca por ramais"

# Array para armazenar as linhas do arquivo
ramais=()
# Loop para ler cada linha do arquivo e adicionar o ramal à array
while IFS= read -r linha; do
  ramais+=("$linha")

# Filtrar os dados
done < <(cat "$arquivo" |grep "Canal" | awk '{print $3}' |sed -e 's/Canal=//g ; s/,//g')

echo "Organizando..."

# Ordenar a array com base no segundo valor de cada linha
ramais_ordenados=($(printf '%s\n' "${ramais[@]}" | sort -t ';' -k2))

echo "Removendo duplicatas."
# remover todos as linhas duplicadas
ramais_unicos=($(printf '%s\n' "${ramais_ordenados[@]}" | awk -F ';' '!x[$1]++'))

# Com o ramal em mãos vamos buscar a ultima et registrada
echo "Lendo o arquivo pela ultima conexão registrada."
linhas=()

for linha in "${ramais_unicos[@]}"; do

  IFS=';' read -ra colunas <<< "$linha"
  echo "Buscando ET do ramal ${colunas[0]}"

  #sleep 1

  valor_ramal=$(cat "$arquivo" | grep "${colunas[0]}" | awk '{print $7}' |sed -e 's/Computador=//g' |tail -n 1)
  echo "ET do ramal ${colunas[0]}: $valor_ramal"

  # Adicionar o valor na array
  colunas[1]=$valor_ramal
  echo ""

  linha_modificada=$(IFS=';'; echo "${colunas[*]}")
  linhas+=("$linha_modificada")

done

echo "Fim da busca por et e ramal."

# Buscar os NaoDefinidoArquivo e substituir pelo valor mais recente do sgtela.
# Nova array para armazenar as linhas modificadas

echo "Inicio da busca profunda para achar as máquinas não registradas."

for linha in "${linhas[@]}"; do
 IFS=';' read -ra colunas <<< "$linha"


 if [ "${colunas[1]}" = "NaoDefinidoArquivo" ]; then

  echo "Buscando ET do Ramal: ${colunas[0]}"

  valor_sgtela=$(cat "$arquivo_sgtela" | grep -A10 "ChannelId: ${colunas[0]}" | grep "Computador:" |awk '{print $2}' |tail -n 1)
  echo "Nova ET do ramal ${colunas[0]}: $valor_sgtela"

  # Substituir o valor NaoDefinidoArquivo pelo novo valor
  colunas[1]=$valor_sgtela
  echo ""

 fi

 linha_modificada=$(IFS=';'; echo "${colunas[*]}")
 linhas_modificadas+=("$linha_modificada")

done

echo "Fim da busca profunda."

# Este bloco do script era apenas para debug ###############
#echo "Escrevendo no arquivo."
# Vamos excluir o arquivo se existir
#if [ -f "relatorio_et.csv" ]; then
#  rm relatorio_et.csv
#fi
#imprimir as linhas armazenadas na array
#for linha in "${linhas_modificadas[@]}"; do
#  echo "$linha" >> relatorio_et.csv
#done
#############################################################

# Agora vamos atualizar as informações

echo "Iniciando a atualização dos dados no banco."

# Configurações do banco de dados
host=""
usuario=""
senha=""
banco_dados=""

for linha in "${linhas[@]}"; do
  IFS=';' read -ra colunas <<< "$linha"

  comando_sql="UPDATE acs_uni SET id_hostname = (SELECT id FROM hosts WHERE hostname = '${colunas[1]}')  WHERE id_ramal_baia = (SELECT id FROM ramal_baia WHERE ramal = ${colunas[0]});"
  saida_erro=$(mysql -h "$host" -u "$usuario" -p"$senha" "$banco_dados" -e "$comando_sql" 2>&1)

  if [ $? -ne 0 ]; then
    echo "Ocorreu um erro ao executar o comando SQL:"
    echo "$saida_erro"
    else
        echo "Comando SQL executado com sucesso."
    fi

done
echo "Fim do script"
