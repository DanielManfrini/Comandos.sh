#!/bin/bash

	# O script abaixo avisa a quantidade de desconexões de um ramal no dia
  # pode ser alterado para IP; HOSTNAME & Usuário dependendo do seu log gerado.
  # atualmente trabalhado em um server de telefonia asterix 
  # altere os nomes de variaveis e caminhos conforme a nescessidade.

	# Variáveis

	DIA=$(date +'%d-%m-%Y')

	# Execução

   echo "Digite o ramal desejado"
   read Ramal

   QUANTIDADE=$(cat /script/backup_logs/messages/messages_$DIA |grep $Ramal | grep  "UNRE" -c)
   echo "o ramal teve $QUANTIDADE desconexões hoje"
