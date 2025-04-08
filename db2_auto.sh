#!/bin/bash
# Create and mount nfs then copy DB2 Sourc
db="HADB"
mkdir /nfs
mount -t nfs4 192.168.100.253:/lv-sharestore/nfs /nfs
cp /nfs/v11.5.9_linuxx64_server_dec.tar ./

# Install DB2
tar -xvf v11.5.9_linuxx64_server_dec.tar
cd server_dec
./db2prereqcheck -v 11.5.9.0
./db2_install -b /lv-db2install -p SERVER -t NOTSAMP

# Create Instance
cd /lv-db2install/instance/
./db2icrt -u db2inst1 db2inst1
ll /lv-db2instance/

su - db2inst1
db2start

# Basic reg for db2
db2set db2comm=tcpip
db2set DB2_ATS_ENABLE=YES
db2iauto -on db2inst1

# Basic setting for dbm 
db2 update dbm cfg using DFTDBPATH /lv-db2data
db2 update dbm cfg using SVCENAME 50000

# Create DB for HADR
mkdir /lv-db2data/$db
db2 create database $db on /lv-db2data/$db

# Basic setting for db2 database
mkdir /lv-db2arclogs/$db
mkdir /lv-db2txlogs/$db
db2 update db cfg for $db USING LOGARCHMETH1 DISK:/lv-db2arclogs/$db
db2 update db cfg for $db USING LOGARCHCOMPR1 ON
db2 update db cfg for $db USING NEWLOGPATH /lv-db2txlogs/$db
db2 update db cfg for $db USING LOGINDEXBUILD ON
db2 update db cfg for $db USING INDEXREC RESTART

# HADR setting for db2 crm database
db2 update db cfg for $db USING HADR_LOCAL_HOST DB2-SERVER-1
db2 update db cfg for $db USING HADR_REMOTE_HOST DB-SERVER-2
db2 update db cfg for $db USING HADR_LOCAL_SVC 52601
db2 update db cfg for $db USING HADR_REMOTE_SVC 52601
db2 update db cfg for $db USING HADR_REMOTE_INST DB2INST1
db2 update db cfg for $db USING HADR_SYNCMODE SYNC
db2 update db cfg for $db USING HADR_PEER_WINDOW 120

# Deactive and restart DB2 Service
db2 terminate
db2stop
db2start