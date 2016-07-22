echo 'deb http://debian.adiscon.com/v8-stable wheezy/'>> /etc/apt/sources.list.d/rsyslogSources.list
echo 'deb http://debian.adiscon.com/v8-stable wheezy/'>> /etc/apt/sources.list.d/rsyslogSources.list
apt-get update
apt-get install rsyslog --force-yes -y #上面添加的源来自官网，没有问题，这里加 --force-yes

echo 'module(load="imfile" PollingInterval="10")
input(type="imfile" File="/home/youzeshun/DST/*[0-9].log"
Tag=""
Facility="local7")
local7.* @192.168.165.200:514'>/etc/rsyslog.d/outPutLog.conf

service rsyslog restart

chown youzeshun /etc/rsyslog.d/outPutLog.conf

#用私网传日志，因此将数据私网ip（vpn）

ip r d 192.168.0.0/16

gateway=`ip a|grep 'inet '|egrep '(192\.168|172\.168)\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'|awk '{print $2}'|cut -d'/' -f1|awk -F. '{print $1"."$2"."$3".1"}'`
ip r a 192.168.0.0/16 via $gateway
