#!/bin/bash

  # O script abaixo avisa a quantidade de desconexões de um ramal no dia
  # pode ser alterado para IP; HOSTNAME ou Usuário dependendo do seu log gerado.
  # atualmente trabalhado em um server de telefonia asterix 
  # altere os nomes de variaveis e caminhos conforme a nescessidade.

	# Variáveis

	DIA=$(date +'%d-%m-%Y')

	# Execução

   echo "Digite o ramal desejado"
   read Ramal

   QUANTIDADE=$(cat /script/backup_logs/messages/messages_$DIA |grep $Ramal | grep  "UNRE" -c)
   echo "o ramal teve $QUANTIDADE desconexões hoje"

# pode ser integrado também ao zabbix para monitoração e alerta.

UserParameter=conta.quedas[*],DIA=$(date +'%d-%m-%Y'); cat /script/backup_logs/messages/messages_$DIA |grep "$1" | grep "UNRE" -c

# Ele irá retornar a quantidade de quedas que o Ramal; IP; HOSTNAME ou Usuário teve no dia atrávés do log gerado. 
