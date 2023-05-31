#!/bin/bash

echo "Inicio do script."

# Obter o dia atual formatado
dia_atual=$(date +%Y%m%d)

caminho_log="logs/log_de_execuxao_dia_$dia_atual.txt"

echo "Dia de execuxão: $dia_atual"
echo "-///////////////////////// INICIO DO LOG /////////////////////////-" >> "$caminho_log"

#caminho para o arquivo de conexões.
arquivo="/ext3/backup_logs/sgtela/$dia_atual/conexoes.log"

arquivo_sgtela="/ext3/backup_logs/sgtela/$dia_atual/sgtela.log"

echo "Iniciando buscas."
echo -e "\nIniciando busca por ramais" | tee -a "$caminho_log"

# Array para armazenar as linhas do arquivo
ramais=()
# Loop para ler cada linha do arquivo e adicionar o ramal à array
while IFS= read -r linha; do

  # A variável IFS (Internal Field Separator) é usada no shell scripting para definir,
  # o caractere ou conjunto de caracteres que serão usados como separadores de campo,
  # ao ler dados comandos como read ou ao iterar em uma string usando loops como for.
  # Por padrão, o valor de IFS é definido como espaço em branco (espaço, tabulação e nova linha), 
  # o que significa que o comando read separa os campos com base nesses caracteres. 
  # No entanto, é possível alterar o valor de IFS para que o comando read divida os campos com base em outros caracteres.
  # Usamos IFS= antes do comando read -r linha. Isso significa que estamos temporariamente definindo IFS como vazio, 
  # o que faz com que o comando read leia toda a linha, incluindo espaços em branco, em vez de dividir os campos por espaços em branco.
  # Essa configuração é usada para garantir que o comando read leia corretamente linhas com espaços em branco. 
  # Sem essa definição, o comando read dividiria a linha em campos separados por espaços em branco, 
  # o que não seria adequado quando queremos armazenar a linha completa em uma única posição da array.
  # É importante observar que essa configuração de IFS é temporária e é aplicada apenas para o comando read dentro do loop for. 
  # Não afetará o valor de IFS fora do loop.

  ramais+=("$linha")

# Filtrar os dados
done < <(cat "$arquivo" |grep "Canal" | awk '{print $3}' |sed -e 's/Canal=//g ; s/,//g')

echo -e "\nOrganizando..." | tee -a "$caminho_log"

# Ordenar a array com base no segundo valor de cada linha
ramais_ordenados=($(printf '%s\n' "${ramais[@]}" | sort -t ';' -k2))

echo -e "\nRemovendo duplicatas." | tee -a "$caminho_log"

# remover todos as linhas duplicadas
ramais_unicos=($(printf '%s\n' "${ramais_ordenados[@]}" | awk -F ';' '!x[$1]++'))

# Com o ramal em mãos vamos buscar a ultima et registrada
echo -e "\nLendo o arquivo pela ultima conexão registrada." | tee -a "$caminho_log"
linhas=()

# Vamos usar um laço for para ler cada linha da array de dados.
for linha in "${ramais_unicos[@]}"; do

  # Aqui usaremos o IFS diferente, identificamos que o separador será o ponto e virgula, tabulação padrão CSV.
  # E no comando read pedimos para que identifique cada coluna como uma array "colunas" da qual acessamos o valor pelo index [valor]
  # Apartir de agora será comum o uso deste comando.
  IFS=';' read -ra colunas <<< "$linha"
  echo "Buscando ET do ramal ${colunas[0]}"

  # Para cada ramal vamos ler novamente o conexões para garantir que vamos pegar sempre o ultimo valor atualizado.
  valor_ramal=$(cat "$arquivo" | grep "${colunas[0]}" | awk '{print $7}' |sed -e 's/Computador=//g' |tail -n 1)
  echo "ET do ramal ${colunas[0]}: $valor_ramal" 
  
  # Vamos adicionar o valor na array lembrando que irá substituir o valor da variavel array pelo index [valor].
  colunas[1]=$valor_ramal
  echo "" 

  # Vamos isar o IFS para fechar esta array colunas em uma unica linha antes de escrever ela em uma nova array de dados.
  linha_modificada=$(IFS=';'; echo "${colunas[*]}")
  linhas+=("$linha_modificada")

done

echo -e "\nFim da busca por et e ramal." | tee -a "$caminho_log"

# Buscar os NaoDefinidoArquivo e substituir pelo valor mais recente do sgtela.
# Nova array para armazenar as linhas modificadas

echo -e "\nInicio da busca profunda para achar as máquinas não registradas." | tee -a "$caminho_log"

# Vamos repetir todo o processo usando IFS e criando arrays provisórias
for linha in "${linhas[@]}"; do
 IFS=';' read -ra colunas <<< "$linha"

  # verificamos se o valor do index 1 quer seria a ET for igual a não definido vamos realizar uma busca profunda.
  if [ "${colunas[1]}" = "NaoDefinidoArquivo" ]; then

  echo "Buscando ET do Ramal: ${colunas[0]}" 

  # Realizamos a busca profunda no log do sgtela, segundo a mesma lógida do anterior, buscando pelo ultimo valor atualizado.
  valor_sgtela=$(cat "$arquivo_sgtela" | grep -A10 "ChannelId: ${colunas[0]}" | grep "Computador:" |awk '{print $2}' |tail -n 1)
  echo "Nova ET do ramal ${colunas[0]}: $valor_sgtela" 

  # Substituir o valor NaoDefinidoArquivo pelo novo valor
  colunas[1]=$valor_sgtela
  echo ""

  fi

  linha_modificada=$(IFS=';'; echo "${colunas[*]}")
  linhas_modificadas+=("$linha_modificada")

done

echo -e "\nFim da busca profunda." | tee -a "$caminho_log"

# Este bloco do script é apenas para debug e irá escrever a array no log de execuxão. #
                                                                                      #
echo -e "\nO resultado final da busca é\n" >> "$caminho_log"                          #
                                                                                      #                            
# Imprimir as linhas armazenadas na array                                             #
for linha in "${linhas_modificadas[@]}"; do                                           #
  echo "$linha" >> "$caminho_log"                                                     #
done                                                                                  #
exit                                                                                  #
                                                                                      #
#######################################################################################

# Agora vamos atualizar as informações.
# Vamos seguir de uma lógica simples, onde verificamos primeiro se
# a informação está divergente antes de realizar a atualização.

echo "Iniciando a atualização dos dados no banco." | tee -a "$caminho_log"

# Configurações do banco de dados
host=""
usuario=""
senha=""
banco_dados=""

# Vamos ler a array e seperar os dados como sempre fizemos até o momento.
for linha in "${linhas[@]}"; do
  IFS=';' read -ra colunas <<< "$linha"

  # buscaremos primeiro a baia e o ramal usanbdo a ET como condição.
  comando_select_sql="SELECT
                        baia.baia,
                        ramal_baia.ramal
                      FROM archerx.acs_uni
                        INNER JOIN ramal_baia ON ramal_baia.id = acs_uni.id_ramal_baia
                        INNER JOIN baia ON baia.id = acs_uni.id_baia
                      WHERE acs_uni.id_hostname = (SELECT id FROM archerx.hosts WHERE hostname='${colunas[1]}')"

  # Realizamos o select utilizando o comando mysql. 
  # que é executado com a opção -B para formatar a saída como TSV. 
  # e a opção -e para fornecer a consulta SELECT. 
  # A saída de erro do comando mysql é capturada na variável saida usando a sintaxe 2>&1.
  saida_select=$(mysql -h "$host" -u "$usuario" -p"$senha" "$banco_dados" -B -e "$comando_select_sql" 2>&1)

  # Em seguida, verificamos o valor de saída $? para determinar se ocorreu algum erro. 
  # Se o valor de saída for diferente de zero, indica que ocorreu um erro.
  if [ $? -ne 0 ]; then

      echo -e "\nOcorreu um erro ao buscar a baia do ramal ${colunas[0]}"
      echo "$saida"

  else
    # Se ocorrer sem erros vamos pegar os valores da linha de cada coluna.
    # Como está em TSV vamos tratar como string normal, ou seja, usaremos awk para viajar como se fosse em células.
    # a Linha com os valores está na linha dois de cada coluna, "NR==" indica a linha, e "print $" indica a coluna
    
    # Pegamos a baia
    baia_select=$(echo "$saida_select" | awk 'NR==2 {print $1}')
    
    # Pegamos o ramal
    ramal_select=$(echo "$saida_select" | awk 'NR==2 {print $2}') 

    # Como buscamos baia e ramal com o host como condição.
    # Comparamos o ramal da array com o ramal do select.
    # se forem iguis significa que a máquina está cadastrada corretamente.
    if [ "${colunas[0]}" = "$ramal_select" ]; then

      echo "Host: ${colunas[1]} está cadastrado corretamente na baia $baia_select."

    # Se não forem iguais irá realizar o cadastro automáticamente.
    else 

      echo -e "\nAtualizando dados da ET: ${colunas[1]} para a baia do Ramal: ${colunas[0]}"

      comando_sql="UPDATE acs_uni 
                  SET 
                    id_hostname = (SELECT id FROM hosts WHERE hostname = '${colunas[1]}'),
                    id_funcionario = 20,
                    data = NOW()  
                  WHERE id_ramal_baia = (SELECT id FROM ramal_baia WHERE ramal = ${colunas[0]});"

      # Como não precisamos de retorno de valores utilizamos apenas a tratativa de erro 2>&1.
      saida_erro=$(mysql -h "$host" -u "$usuario" -p"$senha" "$banco_dados" -e "$comando_sql" 2>&1)

      # verificamos novamente o valor de saída $? para determinar se ocorreu algum erro. 
      # Se o valor de saída for diferente de zero, indica que ocorreu um erro.
      if [ $? -ne 0 ]; then

        echo -e "\nOcorreu um erro ao executar o comando SQL:"
        echo "$saida_erro"

      else

        echo -e "\nComando SQL executado com sucesso."

      fi

    fi
    
  fi
  
done
echo "Fim do script"
