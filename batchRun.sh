. etConf.sh

curl -s 192.168.165.126:93/daochu/jiankongshuju_two.aspx|awk '{print $4}'|sort -u|grep -v ^$ >uploadIpList.txt
cmd=$1
#echo "$passphrase"

for ip in `cat uploadIpList.txt`
do
{	
	/usr/bin/expect -c "set timeout 5
        spawn  ssh -p 45222 -i ${key}  -o StrictHostKeyChecking=no  $user@${ip}
        expect \"Enter passphrase for key\" {send \"${passphrase}\n\"}
	expect \"$user@debian\" {send \"nohup $cmd &\n\"}
	expect eof
	"
}&
done



#使用方式：
#批量打印eth0的ip地址
#/usr/local/sbin/batchRun.sh 'ip a|grep eth0|grep inet'
