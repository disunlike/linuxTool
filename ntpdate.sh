#删除本地时间并设置时区为上海
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#同步网络时间
apt-get install ntpdate
ntpdate time.nist.gov #time.nist.gov 是一个时间服务器的域名

#查看当前的时间
date "+DATE: %m/%d/%y%nTIME: %H:%M:%S"
