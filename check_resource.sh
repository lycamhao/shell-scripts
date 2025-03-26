#!/bin/bash
shopt=$(shopt -s extglob)
##GENERAL##
ARG1_DEFAULT="nfs"
ARG2_DEFAULT="line"
ARG3_DEFAULT="summary"
ARG1=""
ARG2=""
ARG3=""
MEM_THRESHOLD=85
CPU_THRESHOLD=85
NFS_SHARE_PATH="/lv-sharestore/nfs"      ##Modify if you want to get resource by nfs
HOST_LIST_FILE="/root/host_list.txt" ##Modify if you want to get resource by SNMP, SCP, Ansible
MSG_HEADER="!!!!ALERT!!!!"
DATE=$(date)
#INTERVAL=120
###########s

##SNMP options##
TOTAL_RAM_SNMP_OID=".1.3.6.1.4.1.2021.4.5.0"
FREE_RAM_SNMP_OID=".1.3.6.1.4.1.2021.4.6.0"
CPU_SNMP_OID=".1.3.6.1.4.1.2021.11.11.0"
HOST_NAME_OID=".1.3.6.1.2.1.1.5.0"
HOST_IP_ADD=".1.3.6.1.2.1.4.20.1.1"
SNMP_COMMUNITY_STRING="public"
################

##SCP options##
LRM_PATH="/root/scp-monitor"
###############

##Check and normalize arguments
case $# in
1)
	if [ "${1}" = "nfs" ] || [ "${1}" = "snmp" ] || [ "${1}" = "rsync" ]; then
		ARG1=${1}
		ARG2=$ARG2_DEFAULT
	elif [ "${1}" = "line" ] || [ "${1}" = "telegram" ]; then
		ARG1=$ARG1_DEFAULT
		ARG2=${1}
	elif [ "${1}" = "summary" ]; then
		ARG1=$ARG1_DEFAULT
		ARG2=$ARG2_DEFAULT
		ARG3=$ARG3_DEFAULT
	else
		echo "Wrong argument"
	fi
	;;
2 | 3)
	if [ "${1}" = "${2}" ] || [ "${2}" = "${3}" ] || [ "${1}" = "${3}" ]; then
		echo "$DATE: Arguments cannot same"
		exit 0
	elif [ "${1}" != "nfs" ] && [ "${1}" != "snmp" ] && [ "${1}" != "scp" ] && [ "${1}" != "ansible" ] && [ "${1}" != "rsync" ] && [ "${1}" != "ansible" ]; then
		echo "$DATE: Arg1 wrong"
		exit 0
	elif [ "${2}" != "line" ] && [ "${2}" != "telegram" ] && [ "${2}" != "zalo" ]; then
		echo "$DATE: Arg2 wrong"
		exit 0
	elif [ ! -z "${3}" ] && [ "${3}" != "summary" ]; then
		echo "$DATE: Arg3 wrong"
		exit 0
	else
		ARG1=$1
		ARG2=$2
		ARG3=$3
	fi
	;;
*)
	ARG1=$ARG1_DEFAULT
	ARG2=$ARG2_DEFAULT
	;;
esac
echo $ARG1 $ARG2 $ARG3
if [ "$ARG3" = "summary" ]; then MSG_HEADER="----SUMMARY REPORT----"; fi
##Alert options##
LINE_NOTIFY_TOKEN="oYhk3mKcHsiLrOdK03f86niLATQHa7mpYVrHYF8sA6u"
TELEGRAM_BOT_TOKEN="7602298301:AAGbIDJJ6TTuBR6l3cdZikKA8TM1-kjPEYU"
TELEGRAM_CHAT_ID="-1002405368317"
#################

##checkPakage function: check the package exist or not on /bin/
##How to use it: this function require 1 param, type is string, this param is a name of the package that you want to check
##Ex: checkPakage 'nano'
##If exist, return the fullpath of package, it not, return an empty string
checkPackage() {
	packageStatus=$(find "/bin/" -name $1)
	echo "${packageStatus}"
}

##sendMsg function: this function will send a message to line or telegram
##How to use it: this function require 2 param, type is string, first param is a platform that you want to use (line, telegram) and second param is a message
##Ex: sendMsg 'line' 'Hello world'
##After send, this function will return a status code to screen with echo, if one or two param wrong, it will show an error on screen
sendMsg() {
	OOTplatForm=${1?}
	msgText=${2?}
	if [ "${OOTplatForm?}" = "line" ] && [ ! -z "${msgText}" ]; then
		statusCode=$(curl -X POST -H "Authorization: Bearer $LINE_NOTIFY_TOKEN" -F "Message=${msgText}" https://notify-api.line.me/api/notify)
		echo "$DATE: Send status code: $statusCode"
	elif [ "${OOTplatForm?}" = "telegram" ] && [ ! -z "${msgText}" ]; then
		statusCode=$(curl -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d "chat_id=$TELEGRAM_CHAT_ID&text=${msgText}")
		echo "$DATE: Send status code: $statusCode"
	else
		echo echo "$DATE: send error"
	fi
}

##readFile function: this function will read a file that provided and return a content inside the file.
##How to use it: this function has 1 param, type is string, this param is a full path of a file you want to read.
##Ex: readFile '/tmp/test.txt'
##After read, it will return a content of file, if the file is empty, it will return 0, if param 1 not exist, it will show an error on the screen
readFile() {
	file=${1?}
	if [ ! -z "$file" ] && [ -f "$file" ]; then
		readResult=$(tail "${file?}" 2>"/dev/null")
		if [ ! -z "$readResult" ]; then
			echo "${readResult}"
		else
			echo "0"
		fi
	else
		echo "$DATE: the file not exist or param 1 not exist, try again"
	fi
}

##Parse string from file like: HOSTNAME=xx;IP=xx;CPU=xx;RAM=xx
##Use resourceStringParser <string> <search string>
resourceStringParser() {
	resourceString=${1?}
	searchString=${2?}
	parseResult=$(echo "${resourceString}" | awk -F'[;]' '{print $1; print $2; print $3; print $4}' | grep "${searchString}" | awk -F'[=]' '{print $2}')
	echo "${parseResult}"
}

## Check resource by File
## This function use to check RAM and CPU from the file respone from client to NFS share folder
## It will use $HOST_LIST_FILE as a list of file that responed from client with a for loop, each time loop, it will use readFile function to read a file content and use resourceStringParser to parse a string regarding to CPU, RAM, HOSTNAME, ...
## It depends on the CPU_THRESHOLD and RAM_THRESHOLD global variable, if greater then
## If the threshold in file > global variable threshold, it will call sendMsg with the alert messsage and use script param 2 as an OOT Platform, current support LINE and TELEGRAM
## If it detect have a param 3 from a script and param 3 is summary, i will send an summary report to OOT Platform depends on param 2 or default is LINE if param 2 not defined
checkResourceByNfs() {
	alertMsg=""
	for file in ${HOST_LIST_FILE}; do
		resourceString=$(readFile "${file?}")
		if [ "$resourceString" != "0" ]; then
			host=$(resourceStringParser "${resourceString}" "HOSTNAME")
			IP=$(resourceStringParser "${resourceString}" "IP")
			cpuUsed=$(resourceStringParser "${resourceString}" "CPU")
			ramUsed=$(resourceStringParser "${resourceString}" "RAM")
			case $ARG3 in
			"summary")
				alertMsg=$alertMsg$(printf "\n\nHost: $host\nIP: $IP\n1.CPU Usage with: $cpuUsed%%\n2.RAM Usage with: $ramUsed%%")
				;;
			*)
				if awk "BEGIN {exit !($cpuUsed >= $CPU_THRESHOLD)}" && awk "BEGIN {exit !($ramUsed >= $MEM_THRESHOLD)}"; then
					alertMsg=$alertMsg$(printf "\n\nHost: $host\nIP: $IP\nHighly CPU and RAM Usage with \nCPU: $cpuUsed%%\nRAM: $ramUsed%%\n")
				elif awk "BEGIN {exit !($cpuUsed >= $CPU_THRESHOLD)}"; then
					alertMsg=$alertMsg$(printf "\n\nHost: $host\nIP: $IP\nHighly CPU Usage with \nCPU: $cpuUsed%%\n")
				elif awk "BEGIN {exit !($ramUsed >= $MEM_THRESHOLD)}"; then
					alertMsg=$alertMsg$(printf "\n\nHost: $host\nIP: $IP\nHighly RAM Usage with \nRAM: $ramUsed%%\n")
				fi
				;;
			esac
		fi
	done
	if [ ! -z "$alertMsg" ]; then 
		sendMsg "${ARG2}" "${MSG_HEADER}${alertMsg}" 
	fi
}

## Same as checkResourceByNfs but this function use SNMP as a get resource's method
checkResourceBySNMP() {
	alertMsg=""
	packageExist=$(checkPackage "snmpget")
	hostList=$(readFile ${HOST_LIST_FILE})
	if [ ! -z "$packageExist" ]; then
		for host in $hostList; do
			snmpErr=$(snmpget -v2c -c $SNMP_COMMUNITY_STRING $host -O v $HOST_NAME_OID 1 2 2>&1 >/dev/null)
			if [ -z "$snmpErr" ]; then
				hostName=$(snmpget -v2c -c $SNMP_COMMUNITY_STRING $host -O v $HOST_NAME_OID | awk -F' ' '{print $2}')
				cpuIdle=$(snmpget -v2c -c $SNMP_COMMUNITY_STRING $host -O v $CPU_SNMP_OID | awk -F' ' '{print $2}')
				cpuUsed=$((100 - $cpuIdle))
				ramTotalReal=$(snmpget -v2c -c $SNMP_COMMUNITY_STRING $host -O v $TOTAL_RAM_SNMP_OID | awk -F' ' '{print $2}')
				ramTotalReal=$(($ramTotalReal / 1024))
				ramAvailReal=$(snmpget -v2c -c $SNMP_COMMUNITY_STRING $host -O v $FREE_RAM_SNMP_OID | awk -F' ' '{print $2}')
				ramAvailReal=$(($ramAvailReal / 1024))
				ramUsed=$((($ramTotalReal - $ramAvailReal) * 100 / $ramTotalReal))
				case $ARG3 in
				"summary")
					alertMsg=$alertMsg$(printf "\n\nHost: $host\nIP: $IP\n1.CPU Usage with: $cpuUsed%%\n2.RAM Usage with: $ramUsed%%")
					;;
				*)
					if awk "BEGIN {exit !($cpuUsed >= $CPU_THRESHOLD)}" && awk "BEGIN {exit !($ramUsed >= $MEM_THRESHOLD)}"; then
						alertMsg=$alertMsg$(printf "\n\nHost: $host\nIP: $IP\nHighly CPU and RAM Usage with \nCPU: $cpuUsed%%\nRAM: $ramUsed%%\n")
					elif awk "BEGIN {exit !($cpuUsed >= $CPU_THRESHOLD)}"; then
						alertMsg=$alertMsg$(printf "\n\nHost: $host\nIP: $IP\nHighly CPU Usage with \nCPU: $cpuUsed%%\n")
					elif awk "BEGIN {exit !($ramUsed >= $MEM_THRESHOLD)}"; then
						alertMsg=$alertMsg$(printf "\n\nHost: $host\nIP: $IP\nHighly RAM Usage with \nRAM: $ramUsed%%\n")
					fi
					;;
				esac
			else
				echo "$DATE: Cannot communicate with host: $host, make sure this host have installed snmpd and started it"
				alertMsg=$alertMsg$(printf "\nCannot communicate with host: $host, make sure this host have installed snmpd and started it")
			fi
		done
		if [ ! -z "$alertMsg" ]; then sendMsg "${ARG2}" "${MSG_HEADER}${alertMsg}"; fi
	else
		echo "$DATE: Error, make sure you can run snmpget"
		exit 0
	fi
}

## Check res by SCP
checkResourceBySCP() {
	scpPackage=$(checkPackage "scp")
	if [ ! -z "$scpPackage" ]; then
		echo "This package existed"
	fi
}

## Check res by rsync
checkResourceByRsync() {
	rsyncPackage=$(checkPackage "rsync")
	if [ ! -z "$rsyncPackage" ]; then
		echo "This Package existed"
	fi
}

## Check res by ansible
checkResourceByAnsible() {
	echo "checkResourceByAnsible"
}

## Check package

##Running
mainProcess() {
	case $ARG1 in
	"snmp")
		if [ -f "${HOST_LIST_FILE}" ]; then
			checkResourceBySNMP
		else
			echo "$DATE: Host list file not exist"
		fi
		;;
	"nfs")
		HOST_LIST_FILE=$(ls "${NFS_SHARE_PATH?}"/*.log)
		if [ ! -z "${HOST_LIST_FILE}" ]; then
			checkResourceByNfs
		else
			echo "$DATE: No file respone from client"
		fi
		;;
	"rsync")
		if [ -f "${HOST_LIST_FILE}" ]; then
			checkResourceByRsync
		else
			echo "$DATE: Host list file not exist"
		fi
		;;
	"ansible")
		checkResourceByAnsible
		;;
	*)
		exit 0
		;;
	esac
}
mainProcess
# readFile "/mnt/ISO/Share/192.168.100.240.log"
