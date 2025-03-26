#!/bin/bash
if [ -d "${HOME}/sqllib/db2profile" ]; then
    . "${HOME}/sqllib/db2profile"
fi
defaultDB="INSVNDB"
getDB2ConnectionState() {
    res=$(db2 get connection state | grep "Database name" | tr -d ' ' | awk -F'[=]' '{print $2}')
    if [ -z "$res" ];then
        echo "0"
    else
        echo "1"
    fi
}

initDB2Connection(){
    db2State=$(getDB2ConnectionState)
    if [ $db2State -eq 0 ];then
        db2 connect to $defaultDB
    fi
}

exitDB2Connection(){
    db2State=$(getDB2ConnectionState)
    if [ $db2State -eq 1 ];then
        db2 connect reset > /dev/null
    fi
}

underConstruction() {
    echo "Under Construction, press enter to return"
    read
    main
}

#1. List DB2 Instances
showDB2Instances(){
    db2ls
    read -p "Task completed"
    main
}

#2. List DB2 License Info
showDB2License(){
    db2licm -l show detail
    read -p "Task completed"
    main
}

#3. List 
#3. Describe table
describeTable(){
    read -p "Input table name: " tabName
    if [ -z "$tabName" ];then
        read -p "Table name cannot be empty, please try again"
        describeTable
    else
        initDB2Connection
        db2 describe table $tabName
        exitDB2Connection
    fi
}

#4. Count a record of table
countRecordOfTable(){
    read -p "Input table name: " tabName
    if [ -z "$tabName" ];then
        echo "Table name cannot be empty, please try again"
        countRecordOfTable
    else
        initDB2Connection
        db2 -v "SELECT COUNT(*) AS \"$tabName\" FROM $tabName"
        exitDB2Connection
    fi    
}

main() {
    echo "List of functions"
    echo "
        1. List DB2 Instance            11. Import table
        2. List DB2 License Info        12. Get Top 10 SQL
        3. List DBM Config              13. 
        4. List DB Config
        5. List Instance Owner
        6. List Database Admin
        7. List 
        8. 
        9. Reorg Table
        10. Export Table
        q. Quit
    "
    read -p "Your choice: " select
    case $select in
        1) 
            showDB2Instances 
        ;;
        2) 
            showDB2License
        ;;
        3) 
            describeTable
        ;;
        4)
            countRecordOfTable
        ;;
        5) 
            underConstruction
        ;;
        6)
            underConstruction
        ;;
        q|Q)   
            echo "Quit"
            return 0 
            ;;
        *) 
            clear
            main
            ;;
    esac
}
main
