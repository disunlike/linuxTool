#!/bin/dash
Path=$1
 
if [ -z "${Path}" ];then
 echo '需要路径参数'
 exit
fi
 
ls ${Path} 2>/dev/null
if [ "$?" != "0" ];then
 echo '文件夹不存在'
 exit
fi
 
Time=`date "+%Y-%m-%d_%H_%M"`
 
FileName=`echo $Path|awk -F'/' '{print $NF}'`

UTFFileName=${FileName}.${Time}.utf8.tar.gz

tar cvfz ${UTFFileName} ${Path}

sshpass -p duoyi scp ${UTFFileName} dy1@${2}:~

#######################################################3 
FileName=${FileName}.${Time}.gbk.tar.gz

rm -r /tmp/${Path}

cp -r ${Path} /tmp/${Path}
 
#删除eclipse，git，.pyc文件。
rm -r /tmp/${Path}/.*
 
#删除编译过得pyc文件
find /tmp/${Path}|grep -E *.pyc|xargs rm
 
#删除Log
rm -r /tmp/${Path}/Log

#删除编辑器缓存文件
find /tmp/opspro/|grep .py~|xargs rm -f
 
#批量转换换行符
find /tmp/${Path} -type f|xargs dos2unix
 
#批量转码
find /tmp/${Path} -type f|xargs enca -L zh_CN -x gbk

#打包以提交
tar cvfz ${FileName} /tmp/${Path}/
 
#文件权限
chown yzs ${FileName}

if [ ! -z "${2}" ];then
	sshpass -p duoyi scp ${FileName} dy1@${2}:~
fi

