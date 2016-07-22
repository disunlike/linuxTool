#!/bin/sh

. /etc/gs.conf

RUN_ST=${1}
LOGDIR=/raid/dell
RESULTDIR=/home/dy1/db
IMLIST=12672,6349
IMTESTLIST=1927,2693,8563,6414
GETIP=/home/dy1/shellpublic/getip.sh
sendDEFINES=/home/dy1/shellpublic/defines.cfg
sendRTX=/home/dy1/shellpublic/sendrtx.sh


if [ ! -d ${LOGDIR} ];then
	mkdir -p ${LOGDIR}
fi

iFLG=$(dmidecode -s system-serial-number | grep ^VMware | wc -l)
if test ${iFLG} -ge 1 2>/dev/null; then
	echo "虚拟机不检查硬盘";
	exit 0;
fi

SID=`echo "${SERVERNUM}"|awk -F'-' '{print $1$2}'`
ProductCode=`expr ${SID} / 1000`
if [ "${ProductCode}" = "7" -o "${SERVERNUM}" = "112" ];then
	echo "?台湾不检查硬盘";
	exit 0;
fi

iflg=$(dmidecode -s system-serial-number | grep -o "-" | wc -l)
if test ${iflg} -ge 1 2>/dev/null; then
	echo "阿里虚拟机不检查硬盘";
	exit 0;
fi

if test -f ${GETIP} 2>/dev/null; then
	IPADDR=$(sh $GETIP)
else
	IPADDR=`ifconfig eth0 | grep "inet addr" | awk '{print $2}' | awk -F":" '{print $NF}'`
fi

TODAY=`date +"%Y%m%d"`
OLDDAY=`date -d "-30 day" +"%Y%m%d"`
BBULOGNAME=${LOGDIR}/${IPADDR}_BBU_${TODAY}.log
HDLOGNAME=${LOGDIR}/${IPADDR}_HD_${TODAY}.log
ADPLOGNAME=${LOGDIR}/${IPADDR}_ADPINFO.log
MSGINFO=${LOGDIR}/MSG.txt
HDTMPINFO="${LOGDIR}/HDINFO"
SERIALNUM=`dmidecode -s system-serial-number|grep -v ^#`
PRODUCTNAME=`dmidecode -s system-product-name | awk '{print $2}'`
IDRACLOGNAME="TTY Report for [SvcTag-${SERIALNUM}PE ${PRODUCTNAME}] on `date +\"%m-%d-%Y\"` at `date +\"%r\"`"
TITLE="[硬件预警][${SERIALNUM}][$SERVERNUM][${IPADDR}]"
sendFlag=0

saveFwtermLog(){
	if test -f ${RESULTDIR}/PERC_${SERIALNUM}.tar.gz 2>/dev/null; then
		rm -f ${RESULTDIR}/PERC_${SERIALNUM}.tar.gz
	fi
	megacli -FwtermLog dsply -aAll -Nolog > "${RESULTDIR}/${IDRACLOGNAME}.log"
	cd ${RESULTDIR} && tar czf PERC_${SERIALNUM}.tar.gz "${IDRACLOGNAME}.log"
	rm -f "${RESULTDIR}/${IDRACLOGNAME}.log"
}

removeOldFile(){
	rm -f ${LOGDIR}/${IPADDR}_BBU_${OLDDAY}.log
	rm -f ${LOGDIR}/${IPADDR}_HD_${OLDDAY}.log
	rm -f ${HDTMPINFO}
}

saveCurrLogFile(){
	megacli -AdpAllInfo -aALL -Nolog | tr -d "" > ${ADPLOGNAME}
	megacli -AdpBbuCmd -aALL -Nolog | tr -d "" > ${BBULOGNAME}
	megacli -PDList -aALL -Nolog | tr -d "" > ${HDLOGNAME}
}

analyseBattery(){
	echo "=========================" > ${MSGINFO}
	echo "[${SERIALNUM}][${IPADDR}]" >> ${MSGINFO}
	echo "=========================" >> ${MSGINFO}
	BBU_WARN_FLG=`cat ${BBULOGNAME} | grep isSOHGood | sed 's/[ ][ ]*//g' | cut -d":" -f2`
	if [ "x${BBU_WARN_FLG}x" = "xNox" ];then
		TITLE="${TITLE}[电池异常]"
		echo "电池异常" >>  ${MSGINFO}
		echo "=========================" >> ${MSGINFO}
		cat ${BBULOGNAME} >>  ${MSGINFO}
#		egrep "^Battery State|^Relative State of Charge|^Charger Status:|^Remaining Capacity|^isSOHGood|^Estimated Time to full recharge:|^Cycle Count:|^Date of Manufacture:|^Auto Learn Period:|^Next Learn time:" ${BBULOGNAME} >> ${MSGINFO}
#		echo >>  ${MSGINFO}
		echo "\n=========================" >> ${MSGINFO}
#		echo >>  ${MSGINFO}
		sendFlag=1
	fi
}

analyseHardisk(){
	egrep "^Device Id:|Raw Size:|Firmware state:|Connected Port Number:|Port status:|Drive has flagged a S.M.A.R.T alert" ${HDLOGNAME} > ${HDTMPINFO}
	DFlg=`cat ${ADPLOGNAME} | grep -i degrade | sed 's/[ ][ ]*//g' | cut -d":" -f2`
	FFlg=`cat ${ADPLOGNAME} | grep "Failed Disks" | sed 's/[ ][ ]*//g' | cut -d":" -f2`
	RFlg=`cat ${HDTMPINFO} | grep -i rebuild | wc -l`
	UFlg=`cat ${HDTMPINFO} | grep -i unconfigured | wc -l`
	OFlg=`cat ${HDTMPINFO} | grep -i Offline | wc -l`
	HDLISTNUM=""
	if [ "x${OFlg}x" != "x0x" -o "x${UFlg}x" != "x0x" -o "x${DFlg}x" != "x0x" -o "x${FFlg}x" != "x0x" -o ${RFlg} -ne 0 ];then
		devID=0
		sendFlag=2
		for hdid in `cat ${HDTMPINFO} | grep "Device Id" | sed 's/[ ][ ]*//g' | cut -d":" -f2`
		do
			if [ "x${hdid}x" != "x${devID}x" ]; then
				HDLISTNUM="${HDLISTNUM}HDD${hdid}#"
			else
				devID=`expr ${devID} + 1`;
			fi
		done
	fi
	
	dID=0;
	for SMART in `cat ${HDLOGNAME} | grep "S.M.A.R.T alert" | sed 's/[ ][ ]*//g' | cut -d":" -f2`
	do
		if [ "x${SMART}x" = "xYesx" ];then
			if [ ${sendFlag} -ne 2 ];then
				HDLISTNUM="${HDLISTNUM}HDD${dID}#"
				sendFlag=2
				break;
			fi
		else
			dID=`expr ${dID} + 1`;
		fi
	done
	if [ ${sendFlag} -eq 2 ];then
		TITLE="${TITLE}[硬盘异常]"
		echo "#硬盘异常${HDLISTNUM}" >> ${MSGINFO}
		echo "=========================" >> ${MSGINFO}
		saveFwtermLog
		cat ${HDLOGNAME} >> ${MSGINFO}
	fi
}

sendImInfo(){
	if test -f ${sendDEFINES} 2>/dev/null; then
		. $sendDEFINES
	else
		SENDRTXIP=183.61.80.206
		SENDRTXPORT=10809
	fi
		sh $sendRTX "$IMLIST" "${TITLE}"
}

sendWarnInfo(){
	if [ "x${RUN_ST}" = "xINST" ];then
		sendFlag=1
		IMLIST=$IMTESTLIST
		TITLE="${TITLE}[安装成功]"
	fi
	if [ $sendFlag -ne 0 ];then
		sendImInfo ${1}
	fi
}

chkHD(){
	saveCurrLogFile
	analyseBattery
	analyseHardisk
	sendWarnInfo
	removeOldFile
}

iFLG=`dpkg -l | grep megacli | wc -l`
if [ ${iFLG} -eq 0 ];then
	TITLE="[${SERIALNUM}][$SERVERNUM][${IPADDR}][未安装硬件预警]"
	sendImInfo ${IMLIST}
	exit 21
fi

chkHD

