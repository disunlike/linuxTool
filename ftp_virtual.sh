#!/bin/dash

Init(){
	IFS='\n'
	userDb=''
	accessControl='' 
	ConfFile='virtualFtpUser.conf'
	test -e "${ConfFile}" || exit 0
	apt-get update
}

InstallSoft(){
	type db_load || apt-get install db-util -y
	type db_load || exit 0
	
	type vsftpd  || apt-get install vsftpd -y
	type vsftpd  || exit 0
}


GetVittualUserDb(){
	for i in `grep -v ^# "${ConfFile}"`
	do
		#echo默认输出换行符号，所以这里不需要再加换行符了
		userDb=${userDb}`echo $i|awk '{print $1"\n"$2}'`
	done

	echo ${userDb} > /tmp/vusers.txt
	test -d /etc/vsftpd || mkdir /etc/vsftpd
	db_load -T -t hash -f /tmp/vusers.txt /etc/vsftpd/vsftpd-virtual-user.db
	chmod 600 /etc/vsftpd/vsftpd-virtual-user.db
}


ConfFtp(){
	if [ -f "/etc/vsftpd.conf.bkp" ]
	then
		cp /etc/vsftpd.conf.bkp /etc/vsftpd.conf
	else
		cp /etc/vsftpd.conf /etc/vsftpd.conf.bkp
	fi

cat <<EOF >>/etc/vsftpd.conf
anonymous_enable=NO
local_enable=YES
# Virtual users will use the same privileges as local users.
# It will grant write access to virtual users. Virtual users will use the
# same privileges as anonymous users, which tends to be more restrictive
# (especially in terms of write access).
virtual_use_local_privs=YES
write_enable=YES
 
# Set the name of the PAM service vsftpd will use
pam_service_name=vsftpd.virtual
 
# Activates virtual users
guest_enable=YES
 
# Automatically generate a home directory for each virtual user, based on a template.
# For example, if the home directory of the real user specified via guest_username is
# /home/virtual/$USER, and user_sub_token is set to $USER, then when virtual user vivek
# logs in, he will end up (usually chroot()'ed) in the directory /home/virtual/vivek.
# This option also takes affect if local_root contains user_sub_token.
user_sub_token=\$USER
 
# Usually this is mapped to Apache virtual hosting docroot, so that
# Users can upload files
local_root=/home/vftp/\$USER
 
# Chroot user and lock down to their home dirs
chroot_local_user=YES
 
# Hide ids from user
hide_ids=YES
 
#将所有本地用户限制在自家目录中，NO则不限制。
chroot_local_user=YES
#chroot_local_user的例外，YES则表明使用一个文件来保存例外用户
chroot_list_enable=YES
EOF

	service vsftpd restart
}


#配置访问控制
ConfAccessControl(){
cat <<EOF>/etc/vsftpd.chroot_list
EOF

cat <<EOF > /etc/pam.d/vsftpd.virtual
#%PAM-1.0
auth       required  pam_userdb.so db=/etc/vsftpd/vsftpd-virtual-user
account    required  pam_userdb.so db=/etc/vsftpd/vsftpd-virtual-user
account    required  pam_access.so
session    required  pam_loginuid.so
EOF

	for i in `grep -v ^# "${ConfFile}"`
	do
		accessControl=${accessControl}`echo $i|awk '{print $3":"$1":"$4" "$5" "$6}'`
	done

	echo ${accessControl} > /etc/security/access.conf
} 


#配置目录
ConfDir(){
	grep -v ^# "${ConfFile}"|while read i
	do
		user=`echo $i|awk '{print $1}'`
		#没有目录则创建目录
		test -d /home/vftp/${user}/upload || mkdir -p /home/vftp/${user}/upload
		#没有用户则创建用户
		id ${user} || useradd ${user} -d /home/vftp/${user} -s /sbin/nologin
		#vsftpd限制了家目录的写权限，如果有写权限则无法在登录的时候切换到该目录，这会导致登录失败。
		chmod a-w /home/vftp/${user}
	done
	chown -R ftp:ftp /home/vftp
}

Init
#安装服务
InstallSoft
set -e
#配置虚拟账户使用的数据库
GetVittualUserDb
#配置ftp支持虚拟账户
ConfFtp
#配置虚拟账户使用的目录
ConfDir
#配置对虚拟账户的访问控制
ConfAccessControl
