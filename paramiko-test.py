import paramiko
import logging
logging.basicConfig(level=logging.DEBUG)

hostname = '10.165.96.12'
username = 'user_rd'
password = 'Rec0rd@1ns'
port = 22

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(hostname=hostname,port=port,username=username,password=password)
sftp_client = client.open_sftp()
sftp_client.chdir('/mnt/RAID1/SWB/user_rd/PBX-Records')
sftp_client.file()
print(sftp_client.mkdir('abc'))
sftp_client.file()