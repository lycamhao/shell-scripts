import os
import requests
import csv 
import json
import datetime
import logging
import paramiko
import time
# logging.basicConfig(level=logging.DEBUG)

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
CURRENT_FILE        = os.path.abspath(__file__)
CURRENT_DIR         = os.path.dirname(CURRENT_FILE)
BASE_URL            = "https://rsv01.oncall.vn:8887/api/"
RECORDINGS_URL      = BASE_URL+"recordings"
CSV_FILE            = f"{CURRENT_DIR}/input.csv"
CERTIFICATE_FILE    = f"{CURRENT_DIR}/python-oncall.pem"
TEMP_FOLDER         = f"{CURRENT_DIR}/temp"
HEADER              = {'Content-Type': 'application/json','Host': 'rsv01.oncall.vn'}
BODY                = {'username': 'SGCX01177','password': 'cathay@2024','domain': 'sgcx01177.oncall'}

def callAPI (url=None,method=None,header=None,body=None,auths=None,proxies=None):
    proxies = {"https": None, "http": None} if None else None
    resp = False
    if url:
        if method:
            # 
            if auths:
                if auths['authType'] == "Bearer":
                    HEADER['Authorization'] = f"Bearer: {auths['accessToken']}" if auths['accessToken'] else None
            # 
            if method.upper() == 'GET':
                resp = requests.get(url=url,headers=HEADER,verify=CERTIFICATE_FILE,proxies={"https": None, "http": None})
            if method.upper() == 'POST':
                resp = requests.post(url,verify=CERTIFICATE_FILE,json=body,proxies={"https": None, "http": None})
    
    if resp.ok == True:
        resp = resp.text

    return resp

def getOncallAccessToken():
    url = BASE_URL+"tokens"
    respone = callAPI(url=url,method='post',body=BODY)
    if respone:
        token = json.loads(respone)
    
    return token['access_token']

token = getOncallAccessToken()
print(token)