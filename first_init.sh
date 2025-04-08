#!/bin/bash
configFile="./basic.cfg"
inputParam1=$1
hostname=$(hostname | tr -d ' ')
iface=$(nmcli connection show | grep ethernet | awk -F " " '{print $1}' | tr -d ' ')

# Change machine ID
doChangeMachineID(){
    systemd-machine-id-setup
}

# Disable SELINUX Function
disableSELINUX(){
    selinux=$(getenforce | tr -d ' ')
    if [ "$selinux" != "Disabled" ];then
        echo "SELINUX=disabled" > /etc/selinux/config
        echo "SELINUXTYPE=targeted" >> /etc/selinux/config
    fi
}

# Disable Firewall Function
disableFirewall(){
    firewall=$(systemctl status firewalld | grep Active | awk -F " " '{print $2}' | tr -d ' ')
    if [ "$firewall" != "inactive" ];then
        systemctl stop firewalld
        systemctl disable firewalld
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
doFixDB2Top(){
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
    hn=$(grep "$inputParam1" $configFile | awk -F "|" '{print $5}' | awk -F "=" '{print $2}' | tr -d ' ')
    echo "127.0.0.1 $hn" > /etc/hosts
    list=$(cat "$configFile")
    for server in $list;
    do 
        ip=$(echo $server | awk -F "|" '{print $2}' | awk -F "=" '{print $2}' | tr -d ' ' | sed 's/...$//')
        hn=$(echo $server | awk -F "|" '{print $5}' | awk -F "=" '{print $2}' | tr -d ' ')
        echo "$ip $hn" >> /etc/hosts
    done
}

# Change IP Function
doChangeIP(){
    ip=$(grep "$inputParam1" $configFile | awk -F "|" '{print $2}' | awk -F "=" '{print $2}' | tr -d ' ')
    gw=$(grep "$inputParam1" $configFile | awk -F "|" '{print $3}' | awk -F "=" '{print $2}' | tr -d ' ')
    dns=$(grep "$inputParam1" $configFile | awk -F "|" '{print $4}'| awk -F "=" '{print $2}' | tr '-' ' ')
    hn=$(grep "$inputParam1" $configFile | awk -F "|" '{print $5}' | awk -F "=" '{print $2}' | tr -d ' ')
    nmcli connection modify $iface ipv4.addresses $ip
    nmcli connection modify $iface ipv4.gateway $gw
    nmcli connection modify $iface ipv4.dns "$dns"
    nmcli general hostname $hn
    nmcli connection modify $iface ipv4.method manual
    # nmcli connection up $iface
}

# Create physical volume Function
doCreatePV(){
    pvs=$(grep "pv=" $configFile | awk -F "=" '{print $2}' | tr -d ' ')
    for pv in $pvs;
    do
        pvcreate $pv /dev/$pv
    done
}

# Create volume group Function
doCreateVG(){
    vgs=$(grep "vg=" $configFile)
    for vg in $vgs;
    do
        vgName=$(echo $vg | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $1}' | tr -d ' ')
        pvName=$(echo $vg | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $2}' | tr -d ' ')
        vgcreate $vgName $pvName
    done
}

# Create logical volume Function
doCreateLV(){
    lvs=$(grep "lv=" $configFile)
    fs=$(grep "fs=" $configFile)
    for lv in $lvs;
    do
        lvName=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $1}' | tr -d ' ')
        lvSize=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $2}' | tr -d ' ')
        vgName=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $3}' | tr -d ' ')
        mountPoint=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $4}' | tr -d ' ')
        lvcreate -n $lvName -L $lvSize $vgName
        # XFS
        if [ "$fs" == "xfs" ];then
            mkfs.xfs /dev/$vgName/$lvName
        fi
        # Ext4
        if [ "$fs" == "ext4" ];then
            mkfs.ext4 /dev/$vgName/$lvName
        fi
        # Create folder for mount point
        if [ ! -d $mountPoint ];then
            mkdir $mountPoint
        fi
        mount /dev/$vgName/$lvName $mountPoint
        fstab=$(grep "$mountPoint" /etc/fstab)
        if [ -z $fstab ];then
            echo "/dev/$vgName/$lvName $mountPoint ext4 defaults 1 2" >> /etc/fstab
        fi
    done
    systemctl daemon-reload
    mount -a
}

# Create user for DB2 instance Function
doCreateUser(){
    userName=$(grep "user=" $configFile | awk -F "=" '{print $2}' | tr -d ' ')
    groupName=$(grep "group=" $configFile | awk -F "=" '{print $2}' | tr -d ' ')
    homeDir=$(grep "home=" $configFile | awk -F "=" '{print $2}' | tr -d ' ')
    useradd $userName -d $homeDir
    groupadd $groupName
    usermod $userName -g $groupName 
}

# Read from input file 
if [ -f "$configFile" ] && [ ! -z $1 ];then
    # Change machine ID
    doChangeMachineID
    
    # Change IP and hostname
    doChangeHostName

    # Change IP
    doChangeIP

    # Disable SELINUX
    disableSELINUX

    # Disable Firewall
    disableFirewall
    
    # Update
    doUpdate

    # Install related db2 package
    doInstallPkg

    # Fix db2top
    doFixDB2Top

    # Create physical volume
    doCreatePV

    # Create volume group
    doCreateVG

    # Create logical volume and mount
    doCreateLV

    # Create user for DB2 instance
    doCreateUser

    # Change owner
    chown -R db2inst1:db2iadm /lv-db2*

    # Add alias to .bashrc
    su - db2inst1
    echo "alias connrs='db2 connect reset'" >> .bashrc
    echo "alias conto='db2 connect to'" >> .bashrc
    echo "alias getdbcfg='db2 get db cfg for'" >> .bashrc
    echo "alias getdbmcfg='db2 get dbm cfg'" >> .bashrc
    echo "alias getexec='db2 list application show detail | grep -v Wait | grep -v "Connect Completed"'" >> .bashrc
    echo "alias getid='db2 get snapshot for application agentid'" >> .bashrc
    echo "alias getlock='db2 list application show detail | grep Lock-wait | sort -k 10'" >> .bashrc
    echo "alias getlogs='db2pd -db insvndb -logs'" >> .bashrc
    echo "alias gettrans='db2pd -db insvndb -transaction'" >> .bashrc
    echo "alias listapp='db2 list application'" >> .bashrc
    echo "alias onswitch='db2 update monitor switches using bufferpool on lock on table on statement on uow on sort on timestamp on'" >> .bashrc
    echo "alias resetswitch='db2 reset monitor for database '" >> .bashrc
    source .bashrc

    # Restart NetworkManager
    systemctl restart NetworkManager

    # Add alias sudb2
    echo "sudb2='su - db2inst1'" >> .bashrc
    source .bashrc
else    
    echo "The input.conig file not exist or first param not input, try again"
fi