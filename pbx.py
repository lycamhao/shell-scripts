import os
import requests
import csv 
import json
import datetime
import logging
logging.basicConfig(level=logging.DEBUG)

BASE_URL="https://rsv01.oncall.vn:8887/api/"
RECORDINGS_URL=BASE_URL+"recordings"
BASE_DIR="D:\\PBX-Records" #"\\\\10.165.96.12\\SWB\\PBX-Records"
CSV_FILE="input.csv"
CERTIFICATE_FILE="python-oncall.pem"
TODAY = False

def callAPI(url,method,dataToSend,token=False,isReturned=True,isVerbose=True,proxies=False):
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
            verify=CERTIFICATE_FILE,
            proxies={"http": None, "https": None}
        )

    except requests.exceptions.RequestException as e:
        if isVerbose:
            print(f"API call error: {e}")
        return None 
    
    if isReturned:
        result = respone.text
        return result

def today():
    today = datetime.date.today()
    return today

def getTokenFromOnCall():
    url = BASE_URL+'tokens'
    print(url)
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

def createFolder(folderName):
    if os.path.exists(folderName) != True:
        os.mkdir(folderName)

def readCSVFile(csvFile):
    returnArr = []
    with open (csvFile,mode='r') as file:
        csvContent = csv.reader(file)
        for row in csvContent:
            returnArr.append(row)
        return returnArr

def getParentFolder(csvFile,search=None):
    csvContent = readCSVFile(csvFile)
    for row in csvContent:
        if (search != None) & (search in row):
            return f"{row[0]}_{row[1]}"

def createFolderFromCSV(csvFile):
    csvContent = readCSVFile(csvFile)
    for row in csvContent:
        parentFolder = f"{row[0]}_{row[1]}"
        createFolder(f"{BASE_DIR}\\{parentFolder}")
        row=row[3:]
        for item in row:
            createFolder(f"{BASE_DIR}\\{parentFolder}\\{item}") 

def genFileName(caller,callee,namePart):
    if (int(caller) >= 1001) & (int(caller) <= 1040):
        fileName = f"OUTBOUND_FROM_{caller}_to_{callee}_{namePart[4]}"
        if callee == f"*57":
            fileName = f"OUTBOUND_from_{caller}_to_VOICEMAIL_{namePart[4]}"
    else:
        fileName = f"INBOUND_FROM_{caller}_to_{namePart[2]}_{namePart[4]}"
    return fileName 

def downloadFile(url, destination):
    try:
        with requests.get(url, stream=True, verify=CERTIFICATE_FILE,proxies={"http": None, "https": None}) as response:
            response.raise_for_status()
            with open(destination, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
        print("File downloaded successfully!")
    except requests.exceptions.RequestException as e:
        print("Error downloading the file:", e)

createFolderFromCSV(CSV_FILE)
token = getTokenFromOnCall()
items = getAllRecords(token)

if TODAY:
    items = getTodayRecord(token)

for item in items:
    fileInfo = getRecordFileInfo(item['id'],token)['items'][0]
    fileDate = fileInfo['started_at'][0:10]
    namePart = list(filter(None,fileInfo['file_name'].split('_')))
    childFolder = namePart[2]
    parentFolder = getParentFolder(CSV_FILE,childFolder)
    if parentFolder:
        fullpath = f"{BASE_DIR}\\{parentFolder}\\{childFolder}\\{fileDate}"
        createFolder(fullpath)
        caller = fileInfo['caller']
        callee = fileInfo['callee']
        filename = f"{fullpath}\\{genFileName(caller,callee,namePart)}"
        recordFileUrl = f"https://rsv01.oncall.vn:8887/api/files/{fileInfo['file_id']}/data"
        downloadFile(recordFileUrl, filename)