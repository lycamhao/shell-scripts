#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
SAVE_FILE_PATH="${SCRIPT_DIR}"/temp
GET_TIME=$(grep GET_TIME "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
GET_CPU=$(grep GET_CPU "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
GET_RAM=$(grep GET_RAM "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
GET_HDD=$(grep GET_HDD "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
FORMATED_LOG=$(grep FORMATED_LOG "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SCP_PATH=$(grep SCP_PATH "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SSH_PRIVATE_KEY=$(grep SSH_PRIVATE_KEY "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SCP_HOST=$(grep SCP_HOST "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SCP_COPY=$(grep SCP_COPY "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SFTP_COPY=$(grep SFTP_COPY "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SFTP_USER=$(grep SFTP_USER "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SFTP_PATH=$(grep SFTP_PATH "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SFTP_HOST=$(grep SFTP_HOST "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
SFTP_LIMIT_FILES=$(grep SFTP_LIMIT_FILES "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
MINUTE_TO_KEEP_FILES=$(grep MINUTE_TO_KEEP_FILES "${SCRIPT_DIR}"/settings.properties | awk -F'[=]' '{print $2}' | tr -d ' ')
DATE_TIME=$(date +%Y%m%d-%H%M)

HOST_ADDRESS=$(hostname -I | awk '{print $1}')
HOST_ADDRESS=${HOST_ADDRESS::-1}
HOST_NAME=$(hostname)

COUNT_FILE=$(find "${SAVE_FILE_PATH}" -type f -name "*.log" -mmin +"${MINUTE_TO_KEEP_FILES}" | wc -l | tr -d ' ')
if [[ $COUNT_FILE -gt 1 ]]; then
	find "${SAVE_FILE_PATH}" -type f -name "*.log" -mmin +"${MINUTE_TO_KEEP_FILES}" -exec rm -rf {} \;
sftp "${SFTP_USER}"@"${SFTP_HOST}" <<EOF
rm "${SFTP_PATH}"/"${HOST_NAME}"_*.log
bye
EOF
fi

writeToFile(){
	if [ ! -z "$1" ]; then
		echo -e "$1" >> "${SAVE_FILE_PATH}/${HOST_NAME}_${DATE_TIME}.log"
	fi
}

getResourcesInfo(){
	local cpuUsed="$(getCpuUsage)"
	local ramUsed="$(getRamUsage)"
	writeToFile "HOSTNAME=${HOST_NAME};IP=$HOST_ADDRESS;CPU=${cpuUsed};RAM=${ramUsed}"
}

getCpuUsage(){
	cpuResult=$(top -bn1 | grep %Cpu)
	if [[ $FORMATED_LOG == 1 ]]; then
		cpuResult=$(top -bn1 | grep '%Cpu' | awk -F' ' '{print $2 + $4}')
	fi
	echo "${cpuResult}"
}

getRamUsage(){
	ramResult=$(free -m)
	if [[ $FORMATED_LOG == 1 ]]; then
		output="$(free -m | grep Mem:)"
        totalMem="$(echo "${output}" | awk '{print $2}')"
        usedMem="$(echo "${output}" | awk '{print $3}')"
        #freeMem=$(echo "$output | awk '{print $4});
        #sharedMem=$(echo "$output | awk '{print $5});
        #cacheMem=$(echo "$output | awk '{print $5});
        #availMem=$(echo "$output | awk '{print $5});
        ramResult="$(expr "${usedMem}" \* 100 / "${totalMem}")";
	fi 
	echo "${ramResult}"
}

getHDDUsage(){
	hddResult=$(df -h)
	if [[ ${FORMATED_LOG} == 1 ]]; then
		hddResult=$(df -h)
	fi 
	echo "${hddResult}"
}

getDateTime(){
	echo "${DATE_TIME}"
}

# Get date time
if [[ $GET_TIME == 1 ]]; then
	dateTime=$(getDateTime)
	writeToFile "---Date time (YYYMMDD-HHMM)---"
	writeToFile "$dateTime"
	writeToFile "\n"
fi

# Get CPU Usage
if [[ $GET_CPU == 1 ]]; then
	cpuUsage=$(getCpuUsage)
	writeToFile "---CPU Usage---"
	writeToFile "$cpuUsage"
	writeToFile "\n"
fi

#Get RAM Usage
if [[ $GET_RAM == 1 ]]; then
	ramUsage=$(getRamUsage)
	writeToFile "---RAM Usage---"
	writeToFile "$ramUsage"
	writeToFile "\n"
fi

#Get HDD Usage
if [[ $GET_HDD == 1 ]]; then
	hddUsage=$(getHDDUsage)
	writeToFile "---HDD Usage---"
	writeToFile "$hddUsage"
fi

#SCP Copy
if [[ $SCP_COPY == 1 ]]; then
	scp -i ./"${SSH_PRIVATE_KEY}" "${SAVE_FILE_PATH}/${HOST_NAME}_${HOST_ADDRESS}.log" "${SCP_USER}"@"${SCP_HOST}":"${SCP_PATH}"
fi

# SFTP Delete
	if [[ $SFTP_COPY == 1 ]]; then
sftp "${SFTP_USER}"@"${SFTP_HOST}" <<EOF
lcd "${SAVE_FILE_PATH}"
cd "${SFTP_PATH}"
# put "${HOST_NAME}"_"${DATE_TIME}".log
put "${HOST_NAME}"_*.log
bye
EOF
fi