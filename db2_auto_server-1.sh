#!/bin/bash
<<<<<<< HEAD:db2_auto.sh
configFile="./basic.cfg"
inputParam1=$1
hostname=$(hostname | tr -d ' ')
iface=$(nmcli connection show | grep ethernet | awk -F " " '{print $1}' | tr -d ' ')

# Disable SELINUX Function
disableSELINUX(){
    selinux=$(getenforce | tr -d ' ')
    if [ "$selinux" -ne "Disabled" ];then
        echo "SELINUX=disabled" > /etc/selinux/config
        echo "SELINUXTYPE=targeted" >> /etc/selinux/config
    fi
}

# Update Function
doUpdate(){
    yum update -y
}

# Install related db2 package Function
doInstallPkg(){
    nfsutil=$(yum list installed | grep nfs-utils | awk -F " " '{print $1}' | tr -d ' ')
    libstdc_i686=$(yum list installed | grep libstdc++.i686 | awk -F " " '{print $1}' | tr -d ' ')
    pam_i686=$(yum list installed | grep pam.i686 | awk -F " " '{print $1}' | tr -d ' ')
    if [ -z "$nfsutil" ];then
        yum install -y nfs-utils
    fi
    if [ -z "$libstdc_i686" ];then
        yum install -y libstdc++.i686
    fi
    if [ -z "$pam_i686" ];then
        yum install -y pam.i686
    fi
}

# Fix db2top Function
doFixDB2(){
    # Fix db2top ncurses.so.5
    if [ ! -f "/lib64/libncurses.so.6 /lib64/libncurses.so.5" ];then
        ln -s /lib64/libncurses.so.6 /lib64/libncurses.so.5
    fi
    # Fix db2top libtinfo.so.5
    if [ ! -f "/lib64/libtinfo.so.6 /lib64/libtinfo.so.5" ];then
        ln -s /lib64/libtinfo.so.6 /lib64/libtinfo.so.5
    fi 
}

# Change and add other server ip and hostname Function
doChangeHostName(){ 
    hn=$(grep "$inputParam1" ./input.cfg | awk -F "|" '{print $5}' | awk -F "=" '{print $2}' | tr -d ' ')
    echo "127.0.0.1 $hn" > /etc/hosts
    list=$(cat "$configFile")
    for server in $list;
    do 
        ip=$(echo $server | awk -F "|" '{print $2}' | awk -F "=" '{print $2}' | tr -d ' ' | sed 's/...$//')
        hn=$(echo $server | awk -F "|" '{print $5}' | awk -F "=" '{print $2}' | tr -d ' ')
        echo "$ip $hn" >> /etc/hosts
    done
}

# Change IP
doChangeIP(){
    ip=$(grep "$inputParam1" $configFile | awk -F "|" '{print $2}' | awk -F "=" '{print $2}' | tr -d ' ')
    gw=$(grep "$inputParam1" $configFile | awk -F "|" '{print $3}' | awk -F "=" '{print $2}' | tr -d ' ')
    dns=$(grep "$inputParam1" $configFile | awk -F "|" '{print $4}'| awk -F "=" '{print $2}' | tr '-' ' ')
    hn=$(grep "$inputParam1" $configFile | awk -F "|" '{print $5}' | awk -F "=" '{print $2}' | tr -d ' ')
    echo "$ip -- $gw -- $dns -- $hn"
    nmcli connection modify $iface ipv4.addresses $ip
    nmcli connection modify $iface ipv4.gateway $gw
    nmcli connection modify $iface ipv4.dns $dns
    nmcli general hostname $hn
    nmcli connection modify $iface ipv4.method manual
    nmcli connection up $iface
}

# Create physical volume
doCreatePV(){
    pvs=$(grep "pv=" $configFile | awk -F "=" '{print $2}' | tr -d ' ')
    for pv in $pvs;
    do
        pvcreate $pv /dev/$pv
    done
}
=======

# Update
ip1="192.168.10.250"
ip2="192.168.10.247"
ifname=$(nmcli connection show --active | grep ethernet | awk -F" " '{print $1}' | tr -d ' ')
nmcli general hostname $1
hostname=$(hostname)
hostname1="$ip1 DB2-SERVER-1"
hostname2="$ip2 DB2-SERVER-2"

# Install nfs-utils and other pkg
echo "Updating and installing nfs-utils, and other pakages"
yum update -y
yum install -y nfs-utils
yum install -y libstdc++.i686
yum install -y pam.i686

# Fix db2top
echo "Fix db2top"
ln -s /lib64/libncurses.so.6 /lib64/libncurses.so.5
ln -s /lib64/libtinfo.so.6 /lib64/libtinfo.so.5

# Add alias to root
echo "Add alias for root"
cd ~
sudb2="su - db2inst1"
echo "alias subd2='$sudb2'" >> .bashrc
source .bashrc

# Change hostname
echo "Changing hostname"
echo "127.0.0.1 " ${hostname} > /etc/hosts
echo $hostname1 >> /etc/hosts
echo $hostname2 >> /etc/hosts
cat /etc/hosts

# Disable SELINUX
echo "Disable SELINUX"
echo "SELINUX=disabled" > /etc/selinux/config
echo "SELINUXTYPE=targeted" >> /etc/selinux/config
cat /etc/selinux/config

# Create folder for mount
echo "Make folder for mount"
mkdir /lv-db2ad
mkdir /lv-db2backups
mkdir /lv-db2arclogs
mkdir /lv-db2txlogs
mkdir /lv-db2data
mkdir /lv-db2install
mkdir /lv-db2instance

# Change IP on subnet 192.168.10.0/24
echo "Change IP for $hostname"
if [ "$hostname" == "DB2-SERVER-1" ]; then
    nmcli connection modify $ifname ipv4.addresses 192.168.10.250/24
elif [ "$hostname" == "DB2-SERVER-2" ]; then
    nmcli connection modify $ifname ipv4.addresses 192.168.10.247/24
fi
nmcli connection modify $ifname ipv4.gateway 192.168.10.1
nmcli connection modify $ifname ipv4.dns "8.8.8.8 8.8.4.4"
nmcli connection modify $ifname ipv4.method manual

# Create physical volume
echo "Creating LVM"
pvcreate sdb /dev/sdb
pvcreate sdc /dev/sdc
pvcreate sdd /dev/sdd
pvcreate sde /dev/sde
>>>>>>> 98a688eea725f8b71b1fb56a397d46c391a3fe03:db2_auto_server-1.sh

# Create volume group
doCreateVG(){
    vgs=$(grep "vg=" $configFile)
    for vg in $vgs;
    do
        vgName=$(echo $vg | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $1}' | tr -d ' ')
        pvName=$(echo $vg | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $2}' | tr -d ' ')
        vgcreate $vgName $pvName
    done
}

# Create logical volume
doCreateLV(){
    lvs=$(grep "lv=" $configFile)
    for lv in $lvs;
    do
        lvName=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $1}' | tr -d ' ')
        lvSize=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $2}' | tr -d ' ')
        vgName=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $3}' | tr -d ' ')
        lvcreate -n $lvName -L $lvSize $vgName
    done
}

# Read from input file 
# if [ -f "$inputFile" ] && [ ! -z $1 ];then
#     # ip=$(grep "$1" ./input.cfg | awk -F "|" '{print $2}' | awk -F "=" '{print $2}' | tr -d ' ')
#     # gw=$(grep "$1" ./input.cfg | awk -F "|" '{print $3}' | awk -F "=" '{print $2}' | tr -d ' ')
#     # dns=$(grep "$1" ./input.cfg | awk -F "|" '{print $4}' | awk -F "=" '{print $2}'| tr -d ' ' | tr '-' ' ')
#     # ip=$(grep "$1" ./input.cfg | awk -F "|" '{print $5}' | awk -F "=" '{print $2}' | tr -d ' ')
    

<<<<<<< HEAD:db2_auto.sh
#     # Disable SELINUX
#     disableSELINUX

#     # Update
#     doUpdate

#     # for server in $list;
#     # do
#     #     hn=$(echo "$server" | awk -F "|" '{print $5}' | awk -F "=" '{print $2}')
#     #     echo $hn
#     # done
# else
#     echo "The input.conig file not exist or first param not input, try again"
# fi

# # Format ext4 for logical volume
# mkfs.ext4 /dev/vg-db2backups/lv-db2ad
# mkfs.ext4 /dev/vg-db2backups/lv-db2backups
# mkfs.ext4 /dev/vg-db2logs/lv-db2arclogs
# mkfs.ext4 /dev/vg-db2logs/lv-db2txlogs
# mkfs.ext4 /dev/vg-db2data/lv-db2data
# mkfs.ext4 /dev/vg-db2system/lv-db2install
# mkfs.ext4 /dev/vg-db2system/lv-db2instance

# # Add fstab
# echo "/dev/vg-db2backups/lv-db2ad /lv-db2ad ext4 defaults 1 2" >> /etc/fstab 
# echo "/dev/vg-db2backups/lv-db2backups /lv-db2backups ext4 defaults 1 2" >> /etc/fstab 
# echo "/dev/vg-db2logs/lv-db2arclogs /lv-db2arclogs ext4 defaults 1 2" >> /etc/fstab
# echo "/dev/vg-db2logs/lv-db2txlogs /lv-db2txlogs ext4 defaults 1 2" >> /etc/fstab 
# echo "/dev/vg-db2data/lv-db2data /lv-db2data ext4 defaults 1 2" >> /etc/fstab 
# echo "/dev/vg-db2system/lv-db2install /lv-db2install ext4 defaults 1 2" >> /etc/fstab 
# echo "/dev/vg-db2system/lv-db2instance /lv-db2instance ext4 defaults 1 2" >> /etc/fstab
 
# # Reload and mount
# systemctl daemon-reload 
# mount -a

# # Create user for DB2 instance
# useradd db2inst1 -d /lv-db2instance
# groupadd dbiadmin
# usermod db2inst1 -g dbiadmin 
# chown -R db2inst1:dbiadmin /lv-db2*
=======
# Add fstab
echo "Adding fstab"
echo "/dev/vg-db2backups/lv-db2ad /lv-db2ad ext4 defaults 1 2" >> /etc/fstab
echo "/dev/vg-db2backups/lv-db2backups /lv-db2backups ext4 defaults 1 2" >> /etc/fstab 
echo "/dev/vg-db2logs/lv-db2arclogs /lv-db2arclogs ext4 defaults 1 2" >> /etc/fstab
echo "/dev/vg-db2logs/lv-db2txlogs /lv-db2txlogs ext4 defaults 1 2" >> /etc/fstab
echo "/dev/vg-db2data/lv-db2data /lv-db2data ext4 defaults 1 2" >> /etc/fstab
echo "/dev/vg-db2system/lv-db2install /lv-db2install ext4 defaults 1 2" >> /etc/fstab
echo "/dev/vg-db2system/lv-db2instance /home ext4 defaults 1 2" >> /etc/fstab
cat /etc/fstab

# Reload and mount
systemctl daemon-reload 
mount -a

# Create user for DB2 instance
useradd db2inst1 -d /home/db2inst1
groupadd dbiadmin
usermod db2inst1 -g dbiadmin 
chown -R db2inst1:dbiadmin /lv-db2*
>>>>>>> 98a688eea725f8b71b1fb56a397d46c391a3fe03:db2_auto_server-1.sh

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

<<<<<<< HEAD:db2_auto.sh
# # Create sample db
# su - db2inst1
# db2start
# db2sampl -dbpath /lv-db2data/ -name CRM -verbose

# # Add alias to .bashrc
# cd ~
# echo "# The following three lines have been added by UDB DB2." >> .bashrc
# echo "if [ -f /home/db2inst1/sqllib/db2profile ]; then" >> .bashrc
# echo "    . /lv-db2instance/sqllib/db2profile" >> .bashrc
# echo "fi" >> .bashrc
# echo "alias bkincreinsvndb='db2 backup db insvndb incremental to /db2backup compress'" >> .bashrc
# echo "alias bkinsvndb='db2 backup db insvndb online to /db2backup include logs compress'" >> .bashrc
# echo "alias bkoffinsvndb='db2 backup db insnvbd to /db2backup compress'" >> .bashrc
# echo "alias connrs='db2 connect reset'" >> .bashrc
# echo "alias conto='db2 connect to'" >> .bashrc
# echo "alias contoinsvndb='db2 connect to insvndb'" >> .bashrc
# echo "alias contocrm='db2 connect to insvndb'" >> .bashrc
# echo "alias contosample='db2 connect to insvndb'" >> .bashrc
# echo "alias egrep='egrep --color=auto'" >> .bashrc
# echo "alias explg='db2expln -d insvndb -g -t -q'" >> .bashrc
# echo "alias explt='db2expln -d insvndb -t -q'" >> .bashrc
# echo "alias getagentid='db2 get snapshot for application agentid'" >> .bashrc
# echo "alias getdbcfg='db2 get db cfg for insvndb'" >> .bashrc
# echo "alias getdbmcfg='db2 get dbm cfg'" >> .bashrc
# echo "alias getdiag='less /db2dump/db2diag.log'" >> .bashrc
# echo "alias getexec='db2 list application show detail | grep -v Wait | grep -v "Connect Completed"'" >> .bashrc
# echo "alias getid='db2 get snapshot for application agentid'" >> .bashrc
# echo "alias getinsvndbcfg='db2 get db cfg for insvndb show detail'" >> .bashrc
# echo "alias getlock='db2 list application show detail | grep Lock-wait | sort -k 10'" >> .bashrc
# echo "alias getlogs='db2pd -db insvndb -logs'" >> .bashrc
# echo "alias gettrans='db2pd -db insvndb -transaction'" >> .bashrc
# echo "alias grep='grep --color=auto'" >> .bashrc
# echo "alias l.='ls -d .* --color=auto'" >> .bashrc
# echo "alias listapp='db2 list application'" >> .bashrc
# echo "alias ll='ls -l --color=auto'" >> .bashrc
# echo "alias ls='ls --color=auto'" >> .bashrc
# echo "alias onswitch='db2 update monitor switches using bufferpool on lock on table on statement on uow on sort on timestamp on'" >> .bashrc
# echo "alias resetswitch='db2 reset monitor for database '" >> .bashrc
# source .bashrc

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
=======
# Create sample db
su - db2inst1
mkdir /lv-db2txlogs/HADB
mkdir /lv-db2arclogs/HADB
mkdir /lv-db2txlogs/CRM
mkdir /lv-db2arclogs/CRM

db2start
db2sampl -dbpath /lv-db2data/ -name CRM -verbose

# Add alias to db2inst1
cd ~
echo "alias bkincrecrm='db2 backup db crm incremental to /db2backup compress'" >> .bashrc
echo "alias bkincrehadb='db2 backup db hadb incremental to /db2backup compress'" >> .bashrc
echo "alias bkcrm='db2 backup db crm online to /db2backup include logs compress'" >> .bashrc
echo "alias bkhadb='db2 backup db crm online to /db2backup include logs compress'" >> .bashrc
echo "alias bkoffcrm='db2 backup db crm to /db2backup compress'" >> .bashrc
echo "alias bkoffhadb='db2 backup db crm to /db2backup compress'" >> .bashrc
echo "alias connrs='db2 connect reset'" >> .bashrc
echo "alias conto='db2 connect to'" >> .bashrc
echo "alias contocrm='db2 connect to insvndb'" >> .bashrc
echo "alias contohadb='db2 connect to insvndb'" >> .bashrc
echo "alias egrep='egrep --color=auto'" >> .bashrc
echo "alias explg='db2expln -d insvndb -g -t -q'" >> .bashrc
echo "alias explt='db2expln -d insvndb -t -q'" >> .bashrc
echo "alias getagentid='db2 get snapshot for application agentid'" >> .bashrc
echo "alias getdbcfg='db2 get db cfg for insvndb'" >> .bashrc
echo "alias getdbmcfg='db2 get dbm cfg'" >> .bashrc
echo "alias getdiag='less /db2dump/db2diag.log'" >> .bashrc
echo "alias getexec='db2 list application show detail | grep -v Wait | grep -v "Connect Completed"'" >> .bashrc
echo "alias getid='db2 get snapshot for application agentid'" >> .bashrc
echo "alias getinsvndbcfg='db2 get db cfg for insvndb show detail'" >> .bashrc
echo "alias getlock='db2 list application show detail | grep Lock-wait | sort -k 10'" >> .bashrc
echo "alias getlogs='db2pd -db insvndb -logs'" >> .bashrc
echo "alias gettrans='db2pd -db insvndb -transaction'" >> .bashrc
echo "alias grep='grep --color=auto'" >> .bashrc
echo "alias listapp='db2 list application'" >> .bashrc
echo "alias ll='ls -l --color=auto'" >> .bashrc
echo "alias ls='ls --color=auto'" >> .bashrc
echo "alias onswitch='db2 update monitor switches using bufferpool on lock on table on statement on uow on sort on timestamp on'" >> .bashrc
echo "alias resetswitch='db2 reset monitor for database '" >> .bashrc
source .bashrc

# Basic setting for dbm 
db2 update dbm cfg using DFTDBPATH /lv-db2data
db2 update dbm cfg using SVCENAME 50000
db2 update dbm cfg using WLM_DISPATCHER YES

# Basic set for db2
db2set db2comm=tcpip
db2set DB2_ATS_ENABLE=YES
db2 create database HADB

# Basic setting for db2 database
db2 update db cfg for CRM USING LOGARCHMETH1 DISK:/lv-db2arclogs/CRM
db2 update db cfg for CRM USING LOGARCHCOMPR1 ON
db2 update db cfg for CRM USING NEWLOGPATH /lv-db2txlogs/CRM

db2 update db cfg for HADB USING LOGARCHMETH1 DISK:/lv-db2arclogs/HADB
db2 update db cfg for HADB USING LOGARCHCOMPR1 ON
db2 update db cfg for HADB USING NEWLOGPATH /lv-db2txlogs/HADB

# HADR setting for CRM and HADB database
if [ "$hostname" == "DB2-SERVER-1" ]; then
    db2 update db cfg for CRM USING HADR_LOCAL_HOST DB2-SERVER-1
    db2 update db cfg for CRM USING HADR_REMOTE_HOST DB2-SERVER-2
    db2 update db cfg for HADB USING HADR_LOCAL_HOST DB2-SERVER-1
    db2 update db cfg for HADB USING HADR_REMOTE_HOST DB2-SERVER-2
else
    db2 update db cfg for CRM USING HADR_LOCAL_HOST DB2-SERVER-2
    db2 update db cfg for CRM USING HADR_REMOTE_HOST DB2-SERVER-1
    db2 update db cfg for HADB USING HADR_LOCAL_HOST DB2-SERVER-2
    db2 update db cfg for HADB USING HADR_REMOTE_HOST DB2-SERVER-1
fi
db2 update db cfg for CRM USING HADR_LOCAL_SVC 50001
db2 update db cfg for CRM USING HADR_REMOTE_SVC 50001
db2 update db cfg for CRM USING HADR_REMOTE_INST DB2INST1
db2 update db cfg for CRM USING HADR_SYNCMODE SYNC
db2 update db cfg for CRM USING HADR_PEER_WINDOW 120
db2 update db cfg for CRM USING LOGINDEXBUILD ON

db2 update db cfg for HADB USING HADR_LOCAL_SVC 50001
db2 update db cfg for HADB USING HADR_REMOTE_SVC 50001
db2 update db cfg for HADB USING HADR_REMOTE_INST DB2INST1
db2 update db cfg for HADB USING HADR_SYNCMODE SYNC
db2 update db cfg for HADB USING HADR_PEER_WINDOW 120
db2 update db cfg for HADB USING LOGINDEXBUILD ON

# Deactive and restart DB2 Service
db2 terminate
db2stop
db2start

# nmcli connection up ${ifname}
>>>>>>> 98a688eea725f8b71b1fb56a397d46c391a3fe03:db2_auto_server-1.sh
