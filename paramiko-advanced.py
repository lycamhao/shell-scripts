import os
import requests
import json
import datetime
import logging
import paramiko
import time
from pathlib import Path
# logging.basicConfig(level=logging.DEBUG)

##### OS #####
OS_WORKING_DIR = Path('D:/')
##############

##### SMB #####

###############

##### SFTP #####
SFTP_HOST = '10.165.96.12'
SFTP_USER = 'user_rd'
SFTP_PASSWD = 'Rec0rd@1ns'
SFTP_PORT = 22
SFTP_PATH = '/mnt/RAID1/SWB/user_rd/PBX-Records'
##################

##### Connect SFPT #####
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(hostname=SFTP_HOST,port=SFTP_PORT,username=SFTP_USER,password=SFTP_PASSWD)
sftp_client = client.open_sftp()
sftp_client.chdir(SFTP_PATH)
########################

DOWNLOAD_MODE       = "all"
TRANSFER_PROTOCOL   = "SFTP" #SMB
CURRENT_FILE        = Path(__file__)
CURRENT_DIR         = Path(__file__).parent
BASE_URL            = "https://rsv01.oncall.vn:8887/api/"
RECORDINGS_URL      = BASE_URL+"recordings"
CSV_FILE            = f"{CURRENT_DIR}/input.csv"
CERTIFICATE_FILE    = f"{CURRENT_DIR}/python-oncall.pem"
TEMP_FOLDER         = f"{CURRENT_DIR}/temp"
HEADER              = {'Content-Type': 'application/json','Host': 'rsv01.oncall.vn'}
BODY                = {'username': 'SGCX01177','password': 'cathay@2024','domain': 'sgcx01177.oncall'}

# Call an API using requests module
def callAPI (url=None,method=None,header=None,body=None,auths=None,proxies=None):
    proxies = {"https": None, "http": None} if None else None
    resp = False
    if url:
        if method:
            # Auth Type
            if auths:
                if auths['authType'] == "Bearer":
                    HEADER['Authorization'] = f"Bearer {auths['accessToken']}"
            # Get method
            if method.upper() == 'GET':
                resp = requests.get(url=url,headers=HEADER,verify=CERTIFICATE_FILE,proxies={"https": None, "http": None})
            # Get method
            if method.upper() == 'POST':
                resp = requests.post(url,verify=CERTIFICATE_FILE,json=body,proxies={"https": None, "http": None})
    
    if resp.ok == True:
        resp = resp.text

    return resp

# Get oncall access token
def getOncallAccessToken():
    url = BASE_URL+"tokens"
    respone = callAPI(url=url,method='post',body=BODY)
    if respone:
        token = json.loads(respone)
    
    return token['access_token']

# Create a folder
def createFolder(folder,mode=None):
    # print(folder.get("name"))
    if input:
        #Create folder on any dir you want (change the OS_WORKING_DIR value)
        if mode == "os":
            fullPath = OS_WORKING_DIR / folder['name']
            if not fullPath.exists():
                print (f"{folder['name']} on {OS_WORKING_DIR} not existed, created it")
                fullPath.mkdir(parents=True, exist_ok=True)
        # Create folder on SFTP (change the SFTP_PATH value)
        if mode == "sftp":
            fullPath = folderPath = ""
            sftp = conenctSFTP(hostName=SFTP_HOST,hostPort=SFTP_PORT,userName=SFTP_USER,passWord=SFTP_PASSWD)
            if folder.get("path") == None or folder.get("path") == '':
                folderPath = SFTP_PATH
                fullPath = f"{SFTP_PATH}/{folder['name']}"
            else:
                folderPath = f"{SFTP_PATH}/{folder['path']}"
                fullPath = f"{SFTP_PATH}/{folder['path']}/{folder['name']}"

            if folder['name'] not in sftp.listdir(folderPath):
                print (f"{folder['name']} on {folderPath} not existed, created it")
                sftp.mkdir(fullPath)

        # Create folder on current dir (change the CURRENT_DIR value)
        if mode == "current":
            fullPath = OS_WORKING_DIR / folder['name']
            if not fullPath.exists():
                print(folder)
                print (f"{folder['name']} on {CURRENT_DIR} not existed, created it")
                fullPath.mkdir(parents=True, exist_ok=True)

# Create today
def today():
    today = datetime.date.today()
    return today

# Get all Oncall records
def getAllRecords(token):
    url = RECORDINGS_URL
    resp = callAPI(url=url,method='GET',header=None,body=None,auths={'authType':'Bearer','accessToken':token},proxies=None)
    return json.loads(resp)['items']

# Get today records
def getTodayRecord(token):
    url = RECORDINGS_URL+"?filter=started_at gt '" + f"{today()}" + "T00:00:00Z' and started_at lt '" + f"{today()}" + "T23:59:59Z'"
    resp = callAPI(url=url,method='GET',header=None,body=None,auths={'authType':'Bearer','accessToken':token},proxies=None)
    return json.loads(resp)['items']

# Get record file info
def getRecordFileInfo(id,token):
    url = RECORDINGS_URL+f"/{id}"
    resp = callAPI(url=url,method='GET',header=None,body=None,auths={'authType':'Bearer','accessToken':token},proxies=None)
    return json.loads(resp)

# Generate a file name
def genFileName(caller,callee,namePart):
    if (int(caller) >= 1001) & (int(caller) <= 1040):
        fileName = f"OUTBOUND_FROM_{caller}_to_{callee}_{namePart[4]}"
        if callee == f"*57":
            fileName = f"OUTBOUND_from_{caller}_to_VOICEMAIL_{namePart[4]}"
    else:
        fileName = f"INBOUND_FROM_{caller}_to_{namePart[2]}_{namePart[4]}"
    return fileName

# Read the file line by line
def readFile(fileName,fileType):
    if fileType == 'csv':
        import csv
        fileCont = []
        with open (fileName,mode='r') as csvFile:
            for row in csv.reader(csvFile):
                fileCont.append(row)

            return fileCont
        
# Connect to sftp server, change the SFTP_HOST, SFTP_HOST, SFTP_USER, SFTP_PASSWD
def conenctSFTP(hostName,hostPort,userName,passWord):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname=SFTP_HOST,port=SFTP_PORT,username=SFTP_USER,password=SFTP_PASSWD)
    sftp = ssh.open_sftp()

    return sftp

# Create folder from the inputed csv file
def createFolderFromCSVFile(csvFile,mode):
    csvCont = readFile(csvFile,'csv')
    parentFolder=childFolder=""
    for i in range(0,len(csvCont)):
        csvCont[i].pop(2)
        parentFolder = f"{csvCont[i][0]}_{csvCont[i][1]}"
        createFolder({'name':parentFolder},mode=mode)
        for j in range(2,len(csvCont[i])):
            childFolder = csvCont[i][j]
            createFolder(folder={'path':parentFolder,'name':childFolder},mode=mode)

# 

# createFolder(folder={'path':SFTP_PATH,'name':'test3'},mode='sftp')
# csvCont = readFile('./input.csv','csv')
# createFolderFromCSVFile('input.csv','sftp')
token = getOncallAccessToken()
# print (token)
print(getRecordFileInfo('939779570301669376',token))