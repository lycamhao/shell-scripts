# import paramiko
# import logging
# import os
# import csv

# import paramiko.transport 
# # logging.basicConfig(level=logging.DEBUG)

# hostname = '10.165.96.12'
# username = 'user_rd.'
# password = 'Rec0rd@1ns'
# port = 22

# # sftp_client.chdir('/mnt/RAID1/SWB/user_rd/PBX-Records')

# def connectSFTP(hostname,port,username,password):
#       try:
#             SSHConnection = paramiko.SSHClient()
#             SSHConnection.set_missing_host_key_policy(paramiko.AutoAddPolicy())
#             SSHConnection.connect(hostname,port,username,password)
#             SFTPConnection = SSHConnection.open_sftp()
#             return SFTPConnection
#       except:
#            return False

# def checkExistent(location,checkType,path,fileName):
         
# # sftp_client.file()
# # sftp_client.mkdir("abc")
# folder_name = 'efg'
# # print(sftp_client.listdir('/mnt/RAID1/SWB/user_rd/PBX-Records/7.02873040645_Van_Phong_2_(1031-1035)/1031/2025-01-17'))
# # if "abc.txt" in sftp_client.listdir('/mnt/RAID1/SWB/user_rd/PBX-Records'):
# #       sftp_client.remove('/mnt/RAID1/SWB/user_rd/PBX-Records/abc.txt')
# CURRENT_DIR = os.getcwd()
# CSV_FILE=f"{CURRENT_DIR}/input.csv"
# print(CSV_FILE)

# def readCSVFile(csvFile):
#     returnArr = []
#     with open (csvFile,mode='r') as file:
#         csvContent = csv.reader(file)
#         for row in csvContent:
#             returnArr.append(row)
#         return returnArr
       
# connectSFTP(hostname,port,username,password)

import requests
import os
import time
import paramiko
import logging
import csv
import re
# os.add_dll_directory('C:\\Program Files\\IBM\\SQLLIB\\clidriver\\bin')
# import ibm_db
# import ibm_db_sa
# from sqlalchemy import create_engine

CURRENT_FILE        = os.path.abspath(__file__)
CURRENT_DIR         = os.path.dirname(CURRENT_FILE)
NEED_FILE           = f"{CURRENT_DIR}/need.txt"
DB_HOST             = "10.165.50.16"
DB_USER             = "db2admin"
DB_PWRD             = "Cathay168"
DB_PORT             = 50000
DB_NAME             = "insvndb"

with open(NEED_FILE, "r") as file:
    pattern = r"com.cathayins"
    content = file.read()
    # print(content)
    matches = re.findall(pattern,content,re.DOTALL)
    print(matches)
#     lines = file.readlines()
#     temp = []
#     start = 0
#     end = 0
#     count = 0
#     total = lines.len()
#     for index, line in enumerate(lines):
#         if (line[0:13] == 'com.cathayins'):
#             if (index >= 0):
#                 temp.insert(count,[index])
#             if (index > start):
#                 temp[count-1].insert(1,index)
#             start = index
#             count += 1
#         total += 1
#     temp[count-1].insert(1,total)

#     for item in temp:
#         final = ""
#         splittedLine = ""
#         print (item[0])
#         for i in range(item[0],item[1]):
#             if i == item[0]:
#                 splittedLine = lines[i].split("=")
#                 sqlCode = splittedLine[0]
#                 sqlString = splittedLine[1]
#             else:
#                 final += lines[i]
#         final = sqlString + final

# connection_string = (
#     f"DATABASE={DB_NAME};"
#     f"HOSTNAME={DB_HOST};"
#     f"PORT={DB_PORT};"
#     f"PROTOCOL=TCPIP;"
#     f"UID={DB_USER};"
#     f"PWD={DB_PWRD};"
# )

# try:
#     conn = ibm_db.connect(connection_string, '', '')
#     print("Connection established successfully.")
# except Exception as e:
#     print(f"Error: {e}")
# print (final)
# BASE_URL            = "https://vnexpress.net"
# def callAPI(url,method,headerData=None,bodyData=None,params=None,auth=None):
#     if url == '':
#         print ("The URL cannot be empty")
#         return
    
#     if method == '':
#         print ("Please input the method")
#         return
    
#     if method.upper() == 'GET':
#         print(params)
#         try:
#             respone = requests.get(url)
#             print(respone.text)
#         except requests.exceptions.RequestException as e:
#             print ("Call Failed")

#     if method.upper() == 'POST':
#         print ("POST method")


# callAPI(BASE_URL,method='get')