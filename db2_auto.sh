# # Create and mount nfs then copy DB2 Source
# mkdir /nfs
# chown -R db2inst1:dbiadmin /nfs
# mount -t nfs4 192.168.100.253:/lv-sharestore/nfs /nfs
# cp /nfs/v11.5.9_linuxx64_server_dec.tar ./

# # Install DB2
# tar -xvf v11.5.9_linuxx64_server_dec.tar
# cd server_dec
# ./db2prereqcheck -v 11.5.9.0
# ./db2_install -b /lv-db2install -t NOTSAMP

# # Create Instance
# cd /lv-db2install/instance/
# ./db2icrt -u db2inst1 db2inst1
# ll /lv-db2instance/

# # Create sample db
# su - db2inst1
# db2start
# db2sampl -dbpath /lv-db2data/ -name CRM -verbose



# # Basic set for db2
# db2set db2comm=tcpip
# db2set DB2_ATS_ENABLE=YES
# db2 create database HADB

# # Basic setting for dbm 
# db2 update dbm cfg using DFTDBPATH /lv-db2data
# db2 update dbm cfg using SVCENAME 50000

# # Basic setting for db2 database
# db2 update db cfg for CRM USING LOGARCHMETH1 DISK:/lv-db2arclogs
# db2 update db cfg for CRM USING LOGARCHCOMPR1 ON
# db2 update db cfg for CRM USING NEWLOGPATH /lv-db2txlogs

# db2 update db cfg for HADB USING LOGARCHMETH1 DISK:/lv-db2arclogs
# db2 update db cfg for HADB USING LOGARCHCOMPR1 ON
# db2 update db cfg for HADB USING NEWLOGPATH /lv-db2txlogs

# # HADR setting for db2 crm database
# db2 update db cfg for CRM USING HADR_LOCAL_HOST DB2-SERVER-1
# db2 update db cfg for CRM USING HADR_REMOTE_HOST DB2-SERVER-2
# db2 update db cfg for CRM USING HADR_LOCAL_SVC 50001
# db2 update db cfg for CRM USING HADR_LOCAL_SVC 50001
# db2 update db cfg for CRM USING HADR_REMOTE_INST DB2INST1
# db2 update db cfg for CRM USING HADR_SYNCMODE SYNC
# db2 update db cfg for CRM USING HADR_PEER_WINDOW 120
# db2 update db cfg for CRM USING LOGINDEXBUILD ON
# db2 update db cfg for CRM USING INDEXREC RESTART

# # HADR setting for db2 HADB database
# db2 update db cfg for HADB USING HADR_LOCAL_HOST DB2-SERVER-2
# db2 update db cfg for HADB USING HADR_REMOTE_HOST DB2-SERVER-1
# db2 update db cfg for HADB USING HADR_LOCAL_SVC 50001
# db2 update db cfg for HADB USING HADR_REMOTE_SVC 50001
# db2 update db cfg for HADB USING HADR_REMOTE_INST DB2INST1
# db2 update db cfg for HADB USING HADR_SYNCMODE SYNC
# db2 update db cfg for HADB USING HADR_PEER_WINDOW 120
# db2 update db cfg for HADB USING LOGINDEXBUILD ON
# db2 update db cfg for HADB USING INDEXREC RESTART

# # Deactive and restart DB2 Service
# db2 terminate
# db2stop
# db2start