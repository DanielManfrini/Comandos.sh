#!/bin/bash

# o script vai buscar e excluir os logs gerados há mais de (quantidade) dias.
# basta apenas editar e aplicar conforme a nescessidade.

#Messages
  find /script/backup_logs/messages*       -mtime +60 -exec rm -f {} \;
#Channelstats
  find /script/backup_logs/channelstats*   -mtime +15 -exec rm -f {} \;
  
#Explicação do comando
  
#  {Comando de busca [find]} {caminho dos arquivos, neste caso a pasta onde se encontra [/script/backup_logs/messages*]}
#  {Defini /Messages com [*] pois quero que execute em todos os arquivos dentro da pasta sem exeção} 
#  {defini com o parâmetro [-mtime] para que em todos os arquivos acima [+] de [60] dias executasse [-exec] uma remoção [rm] forçada [-f] {} \;}
