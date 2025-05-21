# Check HADR status
ckhadr() {
    p1="${DB}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    db2pd -db "${p1}" -hadr
}

# Start HADR
starthadr() {
    p1="${DB}"
    p2="${HADR_ROLE}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    if [ -n "$2" ];then
        p2="$2"
    fi
    db2 start hadr on db "${p1}" as "${p2}"
}

# Stop HADR
stophadr() {
    p1="${DB}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    db2 stop hadr on db "${p1}"
}

# Get Db2 Log files
getdblogfiles() {
    p1="${DB}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    db2pd -db "${p1}" -logs
}
    
# Get Db2 Transaction
getdbtrans() {
    p1="${DB}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    db2pd -db "${p1}" -transactions
}

# Backup DB2 Database Offline
backupdb() {
    p1="${DB}"
    p2="${BACKUP_DIR}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    if [ -n "$2" ];then
        p2="$2"
    fi
    db2 backup db "${p1}" to "${p2}"
}

# Backup DB2 Database Online
backupdbonline() {
    p1="${DB}"
    p2="${BACKUP_DIR}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    if [ -n "$2" ];then
        p2="$2"
    fi
    db2 backup db "${p1}" online to "${p2}"
}

# Restore DB2 Database
restoredb() {
    p1="${DB}"
    p2="${BACKUP_DIR}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    if [ -n "$2" ];then
        p2="$2"
    fi
    db2 restore db "${p1}" from "${p2}"
}

# Restore DB2 Database Online
restoredbontime() {
    p1="${DB}"
    p2="${BACKUP_DIR}"
    p3="${BACKUP_TIME}"
    if [ -n "$1" ];then
        p1="$1"
    fi
    if [ -n "$2" ];then
        p2="$2"
    fi
    if [ -n "$3" ];then
        p2="$3"
    fi
    db2 restore db "${p1}" online from "${p2}" taken at "${p3}"
}