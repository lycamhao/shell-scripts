#!/bin/bash

SAVE_FILE_PATH=$(grep SAVE_FILE_PATH ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
# NFS_PATH=$(grep SAVE_FILE_PATH ./settings.properties | awk -F'[=]' '{print $2}')
# AUTO_MOUNT_NFS=$(grep AUTO_MOUNT_NFS ./settings.properties | awk -F'[=]' '{print $2}')
# NFS_MOUNT_PATH=$(grep NFS_MOUNT_PATH ./settings.properties | awk -F'[=]' '{print $2}')
GET_CPU=$(grep GET_CPU ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
GET_RAM=$(grep GET_RAM ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
GET_HDD=$(grep GET_HDD ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
FORMATED_LOG=$(grep FORMATED_LOG ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
SCP_PATH=$(grep SCP_PATH ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
SSH_PRIVATE_KEY=$(grep SSH_PRIVATE_KEY ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
SCP_HOST=$(grep SCP_HOST ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
SCP_COPY=$(grep SCP_COPY ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
SFTP_COPY=$(grep SFTP_COPY ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
SFTP_USER=$(grep SFTP_USER ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
SFTP_PATH=$(grep SFTP_PATH ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
SFTP_HOST=$(grep SFTP_HOST ./settings.properties | awk -F'[=]' '{print $2}' | tr -d '[:space:]')
DATE_TIME=$(date +%Y%m%d-%H%M)
# if [[ $GET_CPU == 1 ]]; then
#     echo "GET_CPU is 1"
# fi

if [ -z ${SAVE_FILE_PATH} ]; then
	mkdir ${SAVE_FILE_PATH}
fi

HOST_ADDRESS=$(hostname -I)
HOST_ADDRESS=${HOST_ADDRESS::-1}
HOST_NAME=$(hostname)

# # Check SAVE_FILE_PATH for the resources's log
# # If $1 not empty, SAVE_FILE_PATH will be $1
# if [ ! -z $1 ];then
# 	SAVE_FILE_PATH=$1
# fi

# # Check NFS_PATH for upload resources's log to NFS Server
# # If $2 not empty, NFS_PATH will be $2
# if [ ! -z $2 ];then
# 	NFS_PATH=$2
# fi

# if [ ! -d "/tmp/nfs" ]; then
# 	mkdir /tmp/nfs
# 	sudo mount -t nfs -o rw 192.168.100.253:/mnt/ISO /tmp/nfs
# else
# 	sudo mount -t nfs -o rw 192.168.100.253:/mnt/ISO /tmp/nfs
# fi

# checkNFSPackage(){
# 	OS_REL="`cat /etc/*-release | grep -e '\bID=' | awk -F= '{print $2}'`"
# 	if [ "${OS_REL?}" = "ubuntu" ] || [ "${OS_REL?}" = "debian"  ]; then
# 		NFS_PACKAGE="`dpkg --list | grep 'nfs-common' | awk '{print $2}'`"
# 	elif [ "${OS_REL?}" = "centos" ] || [ "${OS_REL?}" = "fedora" ]; then
# 		NFS_PACKAGE="`rpm -qa | grep 'nfs-util'`"
# 	else
# 		NFS_PACKAGE="NO"
# 	fi
# 	echo ${NFS_PACKAGE?};
# }

rm -rf ${SAVE_FILE_PATH?}/${HOST_NAME}.log
writeToFile(){
	#checkNFSPackage;
	if [ ! -z "$1" ]; then
		echo -e "$1" >> "${SAVE_FILE_PATH}/${HOST_NAME}.log"
	fi
}

getResourcesInfo(){
	local cpuUsed="$(getCpuUsage)"
	local ramUsed="$(getRamUsage)"
	writeToFile "HOSTNAME=${HOST_NAME};IP=$HOST_ADDRESS;CPU=${cpuUsed};RAM=${ramUsed}"
}

getCpuUsage(){
	cpuResult=$(top -bn1 | grep %Cpu)
	if [ $FORMATED_LOG == 1 ]; then
		cpuResult=$(top -bn1 | grep '%Cpu' | awk -F' ' '{print $2 + $4}')
	fi
	echo "${cpuResult}"
}

getRamUsage(){
	ramResult=$(free -m)
	if [ $FORMATED_LOG == 1 ]; then
		output="`free -m | grep Mem:`"
        totalMem="`echo "${output}" | awk '{print $2}'`"
        usedMem="`echo "${output}" | awk '{print $3}'`"
        #freeMem=$(echo "$output | awk '{print $4});
        #sharedMem=$(echo "$output | awk '{print $5});
        #cacheMem=$(echo "$output | awk '{print $5});
        #availMem=$(echo "$output | awk '{print $5});
        ramResult="`expr ${usedMem} \* 100 / ${totalMem}`";
	fi 
	echo "${ramResult}"
}

getHDDUsage(){
	hddResult=$(df -h)
	if [ ${FORMATED_LOG} == 1 ]; then
		hddResult=$(df -h)
	fi 
	echo "${hddResult}"
}

if [ $GET_CPU == 1 ]; then
	cpuUsage=$(getCpuUsage)
	writeToFile "---CPU Usage---"
	writeToFile "$cpuUsage"
	writeToFile "\n"
fi

if [ $GET_RAM == 1 ]; then
	ramUsage=$(getRamUsage)
	writeToFile "---RAM Usage---"
	writeToFile "$ramUsage"
	writeToFile "\n"
fi

if [ $GET_HDD == 1 ]; then
	hddUsage=$(getHDDUsage)
	writeToFile "---HDD Usage---"
	writeToFile "$hddUsage"
fi

#SCP Copy
if [ $SCP_COPY == 1 ]; then
	scp -i ./${SSH_PRIVATE_KEY} "${SAVE_FILE_PATH}/${HOST_NAME}_${HOST_ADDRESS}.log" "${SCP_USER}"@"${SCP_HOST}":"${SCP_PATH}"
fi

# SFTP Copy
if [ $SFTP_COPY == 1 ]; then
	sftp "${SFTP_USER}"@"${SFTP_HOST}" <<EOF
lcd "${SAVE_FILE_PATH}"
cd "${SFTP_PATH}"
put ${HOST_NAME}.log
bye
EOF
fi