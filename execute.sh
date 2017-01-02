#!/bin/bash
#
# SCRIPT: check.ksh
#
# AUTOR: elismar@elismarluz.com
#
# DATA: 10-2016
#
# PROPOSITO:  script usado para conectar com ssh em uma lista de hosts e
# executar os comandos presente no arquivo commands.sh
#
# set -x # Uncomment to debug this script
# set -n # Uncomment to check command syntax without any execution
#
# SSHPASS:  Essa variável recebe a senha de root dos hosts e deve
#           ser atribuída no host que irá executar o script, isso evita
#           a prática ruim de escrever a senha em arquivo. É utilizado no
#           comando "sshpass" na função CONECTA.
#           No terminal execute: export SSHPASS="senha"
#
# Set a trap and clean up before a trapped exit...
# REMEMBER: you CANNOT trap "kill -9"

# Variável para uso com binario sshpass (na funcao CONNECT)
if [ ! -z "$SSHPASS" ]
  then
    read -p "Qual é a senha padrão do usuário root nos hosts da SEDF? " answer
    export SSHPASS=$answer
  fi
#----------------------------------------------------------------------
# Sessão SSH
SSH_PRIVATE_KEY="/home/elismar/.ssh/SUMTEC.rsa"
SSH_PUBLIC_KEY="/home/elismar/.ssh/SUMTEC_public.rsa"
SSH_USER="root"

# Usuários logados no host
USERS_LOGGED_IN=$( who -q | head -1)

# Arquivos de sessão
HOSTSFILE="hosts_ssh_enable.txt"
HOSTS_BAD="hosts_bad_access.txt"
HOSTS_OK="hosts_ok_access.txt"
#----------------------------------------------------------------------

# Função que scanneia uma faixa de hosts ou uma rede completa definifa no primeiro argumento
# da função e salva a lista de ips dos hosts com ssh ativo na porta 22.
function SCANNER(){
  echo "--------------------------------------------------"
  read -p "Em qual host (x.x.x.x) ou rede (x.x.x.x/xx) você quer executar?" alvo
  nmap -PN -p 22 --open -oG - $alvo | awk '$NF~/ssh/{print $2}' > $HOSTSFILE
}

# Função que realiza a conexão ssh no host
function CONNECT(){
  case $1 in
    # Utilizando a chave ssh
    with_key)
      ssh -oBatchMode=yes -q -i $SSH_PRIVATE_KEY $SSH_USER@$host $2
      ;;
    # Utilizando usuário e senha
    with_pass)
      sshpass -e ssh -oBatchMode=no -q $SSH_USER@$host $2
      ;;
  esac
}
#----------------------------------------------------------------------

# Scanneia a rede e monta o arquivo de hosts com ssh ativo
SCANNER $sede1_network

if [ -f $HOSTSFILE ]
  then
    for host in $(cat $HOSTSFILE)
    do
      # Tenta conectar com root usando a chave ssh adicionada na instação(imagem)
      CONECTA com_chave exit
        if [ $? -eq 0 ]
          then
            # K = chave ssh, assim saberemos quais hosts possuem a chave ssh funcional 
            echo \"K\",\"$host\",$(CONECTA com_chave 'bash -s' < $COMMANDS)
            echo $host>>$HOSTS_OK
        # Se não funcionar, então tenta com root e senha padrão definida.
        elif [ $? -ne 0 ]
          then
            CONECTA com_senha exit
              if [ $? -eq 0 ]
                then
                  # P = password, caso a key ssh nao esteja configurada no host.
                  echo \"P\",$host,$(CONECTA com_senha 'bash -s' < $COMMANDS)
                  echo $host>>$HOSTS_OK
                  # Adiciona a chave ssh para acesso futuro
                else
                  # Se nenhum dos dois métodos funcionarem, salva esse host em log para verificação posterior
                  echo $host "BAD"
                  echo $host>>$HOSTS_BAD
              fi
        fi
    done
else
  echo -e "\nERROR: Arquivo $HOSTS não existe"
  echo -e "\nA lista de hosts para conectar nao existe...\n"
exit 2
fi