HOST_MACADDRES=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address)
HOST_HOSTNAME=$(hostname)
HOST_USERS=$(who -q | head -1)

OCS_PACKAGE="ocsinventory-agent"
OCS_SERVER="10.221.37.60"
OCS_FILE="/etc/ocsinventory/ocsinventory-agent.cfg"

function install_ocs(){
  DEBIAN_FRONTEND=noninteractive apt-get -y install $OCS_PACKAGE &> /dev/null
  echo "server=$OCS_SERVER" > $OCS_FILE
  ocsinventory-agent &> /dev/null
}
function registrar_correcao(){
  case $1 in
    puppet)
      echo "tag0002 - Demanda corretiva do puppet executada remotamente em: `date +%d/%m/%Y\ \à\s\ %H:%M:%S`" >> /var/log/stefanini.log
      ;;
    ocs)
      echo "tag0003 - Demanda de instalacao do $OCS_PACKAGE executada remotamente em: `date +%d/%m/%Y\ \à\s\ %H:%M:%S`" >> /var/log/stefanini.log
      ;;
    *)
      exit
  esac
}
if [ -f /etc/ocsinventory/ocsinventory-agent.cfg ]
  then
    echo \"$HOST_MACADDRES\",\"$HOST_HOSTNAME\",\"$HOST_USERS\",\"1\"
    echo "$OCS_PACKAGE"
    echo "OCS_FILE"
    echo "OCS_SERVER"
  else
    echo \"$HOST_MACADDRES\",\"$HOST_HOSTNAME\",\"$HOST_USERS\",\"0\"
    install_ocs
    registrar_correcao ocs
fi
