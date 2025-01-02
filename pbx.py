import os
import requests
import csv 
import json
import datetime

BASE_URL="https://rsv01.oncall.vn:8887/api/"
RECORDINGS_URL=BASE_URL+"recordings"
BASE_DIR="\\\\10.165.96.12\\SWB\\PBX-Records"
CSV_FILE="D:\\Haolc\\Devops\\shell-scripts\\input.csv"
CERTIFICATE_FILE="certificate.cer"

def callAPI(url,method,dataToSend,token=False,isReturned=True,isVerbose=True):
    headerData = {
        'Content-Type': 'application/json',
        'Host': 'rsv01.oncall.vn'
    }

    if token:
        headerData['Authorization'] = f"{token}"

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
    token = callAPI(url,'POST',dataToSend,True,True,True);
    return token

def getAllRecords(token):
    url = RECORDINGS_URL
    recordFileList = callAPI(url,'GET',False,token,True,True)
    return json.loads(recordFileList)

def getTodayRecord(token):
    url = RECORDINGS_URL+"?filter=started_at gt '" + today() + "T00:00:00Z' and started_at lt '" + today() + "T23:59:59Z'"
    recordFileList = callAPI(url,'GET',False,token,True,True)
    return url #json.loads(recordFileList)

print(getTodayRecord(getTokenFromOnCall))