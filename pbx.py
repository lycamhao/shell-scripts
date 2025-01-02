import os
import requests
import csv 
import json
import datetime

BASE_URL="https://rsv01.oncall.vn:8887/api/"
RECORDINGS_URL=BASE_URL+"recordings"
BASE_DIR="\\\\10.165.96.12\\SWB\\PBX-Records"
BASE_DIR_2="D:\\PBXRecord\\"
CSV_FILE="input.csv"
CERTIFICATE_FILE="certificate.cer"

def callAPI(url,method,dataToSend,token=False,isReturned=True,isVerbose=True):
    headerData = {
        'Content-Type': 'application/json',
        'Host': 'rsv01.oncall.vn'
    }

    if token:
        headerData['Authorization'] = f"Bearer {token}"

    try:
        respone = requests.request(
            method=method.upper(),
            url=url,
            headers=headerData,
            json=dataToSend if dataToSend else None,
            verify=False
            # cert=CERTIFICATE_FILE
        )

    except requests.exceptions.RequestException as e:
        if isVerbose:
            print(f"API call error: {e}")
        return None 
    
    if isReturned:
        respone.raise_for_status()
        return respone.text

def today():
    today = datetime.date.today()
    return today

def getTokenFromOnCall():
    url = BASE_URL+'tokens'
    dataToSend = {
        'username'  : 'SGCX01177',
        'password'  : 'cathay@2024',
        'domain'    : 'sgcx01177.oncall'
    }
    token = callAPI(url,'POST',dataToSend,False,True,True);
    return json.loads(token)['access_token']

def getAllRecords(token):
    url = RECORDINGS_URL
    recordFileList = callAPI(url,'GET',False,token,True,True)
    return json.loads(recordFileList)['items']

def getTodayRecord(token):
    url = RECORDINGS_URL+"?filter=started_at gt '" + f"{today()}" + "T00:00:00Z' and started_at lt '" + f"{today()}" + "T23:59:59Z'"
    recordFileList = callAPI(url,'GET',False,token,True,True)
    return json.loads(recordFileList)['items']

def getRecordFileInfo(id,token):
    url = RECORDINGS_URL+f"/{id}"
    fileInfo = callAPI(url,'GET',False,token,True,True)
    return json.loads(fileInfo)

def createFolder(path,folderName):
    return 0

def readCSVFile(csvFile):
    returnArr = []
    with open (csvFile,mode='r') as file:
        csvContent = csv.reader(file)
        for row in csvContent:
            returnArr.append(row)
        return returnArr

def getParentFolderFromSearch(csvFile,search):
    csvContent = readCSVFile(csvFile)
    for row in csvContent:
        if search in row:
            return f"{row[0]}-{row[1]}"
        break

token = getTokenFromOnCall()
items = getAllRecords(token)
for item in items:
    # print(f"{item['id']}\n")
    fileInfo = getRecordFileInfo(item['id'],token)
    fileInfo = fileInfo['items'][0]
    fileName = fileInfo['file_name']
    fileName = fileName.split('_')
    fileName = list(filter(None,fileName))
    childFolder = fileName[2]
    parentFolder = getParentFolderFromSearch(CSV_FILE,childFolder)
    print(f"{parentFolder}-{childFolder}")