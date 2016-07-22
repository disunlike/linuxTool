. etConf.sh

file=$1
#用私网地址传，没有私网的是未配置的和BGP。单独处理
curl -s 192.168.165.126:93/daochu/jiankongshuju_two.aspx|awk '{print $4}'|sort -u|grep -v ^$ >uploadIpList.txt

for ip in `cat uploadIpList.txt`
do
{	
	/usr/bin/expect -c "set timeout 5
        spawn  scp -P 45222 -i ${key}  -o StrictHostKeyChecking=no  ${file} youzeshun@${ip}:~
        expect \"Enter passphrase for key\" {send \"${passphrase}\n\"}
        expect eof
	"
}&
done


#使用示范
#/usr/local/sbin/batchScp.sh /var/ftp/downloadSpeedTest.tar.gz
