#!/bin/bash

set -e

# Constants
BASE_URL="https://rsv01.oncall.vn:8887/api"
TOKEN_URL="$BASE_URL/tokens"
GROUPS_URL="$BASE_URL/groups"
RECORDINGS_URL="$BASE_URL/recordings"
DOWNLOAD_DIR="D:/PBXRecord"
USERNAME="SGCX01177"
PASSWORD="cathay@2024"
DOMAIN="sgcx01177.oncall"
CACERT_PATH="./certificate.pem"
INPUT_FILE="./input.csv"
DOWNLOAD_DIR="$HOME/PBX-Record"
if [ ! -d "$DOWNLOAD_DIR" ]; then
  mkdir -p "$DOWNLOAD_DIR"
fi
# Function to call API
callAPI() {
  local url=$1
  local method=$2
  local data=$3
  local token=$4
  curl -k -s --cacert "$CACERT_PATH" -X "$method" "$url" \
    -H "Content-Type: application/json" \
    -H "Host: rsv01.oncall.vn" \
    ${token:+-H "Authorization: Bearer $token"} \
    ${data:+-d "$data"}
}

#Function to get token from api
getTokenFromOncall() {
  # local payload=$(jq -n \
  #   --arg username "$USERNAME" \
  #   --arg password "$PASSWORD" \
  #   --arg domain "$DOMAIN" \
  local payload=$(printf '{
  "username": "%s",
  "password": "%s",
  "domain": "%s"
}' "$USERNAME" "$PASSWORD" "$DOMAIN")
  local response=$(callAPI "$TOKEN_URL" "POST" "$payload")
  echo "$response"
}
#Read input file 
downloadRecords() {
  while IFS=',' read -r field1 field2 field3; do 
    # Create the parent folder using "field 1-field 2"
    parent_folder="${field1}-${field2}"
    local childFolder=$(echo "$field3" | awk -F, '{print $1}')
    if [ ! -d "$DOWNLOAD_DIR/$parent_folder" ]; then
      mkdir -p "$DOWNLOAD_DIR/$parent_folder"
      # Create the child folder inside the parent folder
      if [ ! -d "$DOWNLOAD_DIR/${parent_folder}/${childFolder}" ]; then
        mkdir -p "$DOWNLOAD_DIR/${parent_folder}/${childFolder}"
      fi
    fi
  done < "$INPUT_FILE"
  local token=$(getTokenFromOncall)
  IFS=',' read -r f1 f2 <<< $token
  bearerToken=$(echo $f1 | awk -F: '{print $2}' | tr -d '"')
  local payload=$(printf '{"pagination": "%d"}' 1000)
  local response=$(callAPI "$RECORDINGS_URL" "GET" "$payload" "$bearerToken")
  echo $response > ./response.json
  local numOfFields=$(cat ./response.json | awk -F '},{' '{print NF}')
  echo $numOfFields
  local id=""
  local caller=""
  local callee=""
  local started_at=""
  local temp
  local isCaller
  local isCallee
  for((i=1;i<=$numOfFields;i++));
  do
    if [ $i == 1 ];then
      temp=$(cat ./response.json | awk -F"{" '{print $3}')
    else
      temp=$(cat ./response.json | awk -v i=$i -F"},{" '{print $i}' | awk -F',:' '{print $1}')
    fi
    id=$(echo $temp | awk -F ',' '{print $1}' | awk -F ':' '{print $2}' | tr -d '"')
    caller=$(echo $temp | awk -F ',' '{print $2}' | awk -F ':' '{print $2}' | tr -d '"')
    # callee=$(echo $temp | awk -F ',' '{print $3}' | awk -F ':' '{print $2}' | tr -d '"')
    # calleeFolder="$(grep $callee "./input.csv" | awk -F ',' '{print $1"/"$2"/"$3}')"
    callerFolder="$(grep $caller "./input.csv" | awk -F ',' '{print $1"/"$2"/"$3}')"
    # calleeFolder="$DOWNLOAD_DIR/$calleeFolder"
    callerFolder="$DOWNLOAD_DIR/$callerFolder"
    response=$(callAPI "$RECORDINGS_URL/$id" "GET" "$payload" "$bearerToken")
    fileID=$(echo $response | tr -d '{"' | awk -F ',' '{print $5}' | awk -F ':' '{print $2}')
    echo $response
    # curl -s --cacert ./certificate.pem "$BASE_URL/blobs/$fileID" --output "$DOWNLOAD_DIR/$id.wav"
  done
}
downloadRecords