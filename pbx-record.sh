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
# Function to call API
callAPI() {
  local url=$1
  local method=$2
  local data=$3
  local token=$4
  curl -s --cacert "$CACERT_PATH" -X "$method" "$url" \
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
    if [ ! -d "$parent_folder" ]; then
      mkdir -p "$parent_folder"
      # Create the child folder inside the parent folder
      if [ ! -d "${parent_folder}/${childFolder}" ]; then
        mkdir -p "${parent_folder}/${childFolder}"
      fi
    fi
  done < "$INPUT_FILE"
  local token=$(getTokenFromOncall)
  IFS=',' read -r f1 f2 <<< $token
  bearerToken=$(echo $f1 | awk -F: '{print $2}' | tr -d '"')
  local payload=$(printf '{"pagination": "%d"}' 1000)
  local response=$(callAPI "$RECORDINGS_URL" "GET" "$payload" "$bearerToken")
  echo $response > response.json
}
downloadRecords