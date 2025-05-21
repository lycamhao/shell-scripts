# Check HADR status
ckhadr() {
    if [ -z $1 ];then
        db2pd -db $1 -hadr
    fi
    db2pd -db $DB -hadr
}

# Start HADR
starthadr() {
    if [ -z $1 ];then
        db2 start hadr on db $1 as $2
    fi
    db2 start hadr on db $DB as $HADR_ROLE
}

# Stop HADR
stophadr() {
    if [ -z $1 ];then
        db2 stop hadr on db $1
    fi
    db2 stop hadr on db $DB
}

# Get Db2 Log files
getlogs() {
    if [ -z $1 ];then
        db2pd -db $1 -logs
    fi
    db2pd -db $DB -logs
}

# Get Db2 Transaction
gettrans() {
    if [ -z $1 ];then
        db2pd -db $1 -transaction
    fi
    db2pd -db $DB -transaction
}

# Backup DB2 Database Offline
backupdb() {
    if [ -z $1 ];then
        db2 backup db $1 to $2
    fi
    db2 backup db $DB to $BACKUP_DIR
}

# Backup DB2 Database Online
backupdbonline() {
    if [ -z $1 ];then
        db2 backup db $1 online to $2
    fi
    db2 backup db $DB online to $BACKUP_DIR
}

# Restore DB2 Database
restoredb() {
    if [ -z $1 ];then
        db2 restore db $1 from $2
    fi
    db2 restore db $DB from $BACKUP_DIR
}

# Restore DB2 Database Online
restoredbontime() {
    if [ -z $1 ];then
        db2 restore db $1 online to $2 taken at $3
    fi
    db2 restore db $DB online from $BACKUP_DIR taken at $BACKUP_TIME
}