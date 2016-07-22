#!/bin/bash

. /etc/gs.conf

alarm(){
	myip=`sh /home/dy1/shellpublic/getip.sh`
	sh /home/dy1/shellpublic/sendrtx.sh 6349 "${SERVERNUM}${SRVNAME}:${myip}尚未部署snmp！"
}

iVER=$(cat /etc/debian_version | awk -F'.' '{print $1}')
if test ${iVER} -eq 6 2>/dev/null; then
	echo "debian 6"
elif test ${iVER} -eq 7 2>/dev/null; then
	echo "debian 7"
else
	echo "版本太低，不安装snmp!"
	exit
fi
	
ps_out=`pgrep snmpd`
if [ -n "$ps_out" ];
then
	echo "snmpd is ok"
else
	alarm
fi