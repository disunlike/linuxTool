#!/bin/bash
 
init(){
	basePath=$(cd `dirname $0`;pwd)
	. ${basePath}/backup.conf
	nowtime=`date +'%Y-%m-%d_%Hh%Mm%Ss'`
	webFile="wordpress.${nowtime}.file.tar.gz"
	webSql="wordpress.${nowtime}.sql"
	if [ -d ${path} ];then
	    echo "目录backup存在"
	  else
	    mkdir ${path}
	fi
}
 
backup(){
    tar cfzP ${path}/${webFile} ${file}
    if [ "$backup_mysql" = 1 ];then
	 mysqldump -uroot -p${mysql_password} wordpress >${path}/${webSql}
    fi
}
 
 
check(){
	if [ -f ${path}/${webFile} ] && [ -f ${path}/${webSql} ];then
	   echo "得到备份信息"
	  else
	   echo "备份失败"
	fi
}

Tran(){
    if [ -f ${path}/${webFile} ];then
        sshpass -p 'dy@123' scp ${path}/${webFile} root@10.32.64.134:/backup/wordpress/
    fi

    if [ -f ${path}/${webSql} ];then
        sshpass -p 'dy@123' scp ${path}/${webSql} root@10.32.64.134:/backup/wordpress/
    fi
}

delOld(){
	num=`ls ${path}/wordpress*|wc -l`
	if [ $num -gt ${max_save}  ];then
		ls ${path}/wordpress*|sort|head -n2|xargs rm
	fi
}



main(){
  init
  backup
  check
  Tran
  delOld
}
 
main
