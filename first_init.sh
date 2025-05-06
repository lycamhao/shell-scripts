#!/bin/bash
configFile="./basic.cfg"
inputParam1=$1
hostname=$(hostname | tr -d ' ')
iface=$(nmcli connection show | grep ethernet | awk -F " " '{print $1}' | tr -d ' ')
idev=$(nmcli device status | grep ethernet | awk -F " " '{print $1}' | tr -d ' ')
idevTotal=$(nmcli device status | grep ethernet | awk -F " " '{print $1}' | tr -d ' ' | wc -l)
idevList=$(nmcli device status | grep ethernet | awk -F " " '{print $1}' | tr -d ' ') 
idevStatus=$(nmcli device status | grep ethernet | awk -F " " '{print $3}' | tr -d ' ')

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
    sysstat=$(yum list installed | grep sysstat | awk -F " " '{print $1}' | tr -d ' ')
    mksh=$(yum list installed | grep mksh | awk -F " " '{print $1}' | tr -d ' ')
    $perlinterpreter=$(yum list installed | grep "perl-interpreter" | awk -F " " '{print $1}' | tr -d ' ')
    $persyslog=$(yum list installed | grep "perl-Sys-Syslog" | awk -F " " '{print $1}' | tr -d ' ')
    $perlnetping=$(yum list installed | grep "perl-Net-Ping" | awk -F " " '{print $1}' | tr -d ' ')
    $perlthreadqueue=$(yum list installed | grep "perl-Thread-Queue" | awk -F " " '{print $1}' | tr -d ' ')
    $make=$(yum list installed | grep make | awk -F " " '{print $1}' | tr -d ' ')
    $elfutils=$(yum list installed | grep "elfutils-libelf-devel" | awk -F " " '{print $1}' | tr -d ' ')
    $patch=$(yum list installed | grep patch | awk -F " " '{print $1}' | tr -d ' ')
    $m4=$(yum list installed | grep m4 | awk -F " " '{print $1}' | tr -d ' ')
    $kerneldevel=$(yum list installed | grep "kernel-devel" | awk -F " " '{print $1}' | tr -d ' ')
    $python=$(yum list installed | grep "python36" | awk -F " " '{print $1}' | tr -d ' ')
    $perlthreadqueue=$(yum list installed | grep "perl" | awk -F " " '{print $1}' | tr -d ' ')
    $gcc_cpp=$(yum list installed | grep "gcc-c++" | awk -F " " '{print $1}' | tr -d ' ')
    $ksh=$(yum list installed | grep ksh | awk -F " " '{print $1}' | tr -d ' ')
    if [ -z "$nfsutil" ];then
        yum install -y nfs-utils
    fi
    if [ -z "$libstdc_i686" ];then
        yum install -y libstdc++.i686
    fi
    if [ -z "$pam_i686" ];then
        yum install -y pam.i686
    fi
    if [ -z "$sysstat" ];then
        yum install -y sysstat
    fi
    if [ -z "$mksh" ];then
        yum install -y mksh
    fi
    if [ -z "$perlinterpreter" ];then
        yum install -y perl-interpreter
    fi
    if [ -z "$perlsyslog" ];then
        yum install -y perl-Sys-Syslog
    fi
    if [ -z "$perlnetping" ];then
        yum install -y perl-Net-Ping
    fi
    if [ -z "$perlthreadqueue" ];then
        yum install -y perl-Thread-Queue
    fi
    if [ -z "$make" ];then
        yum install -y make
    fi
    if [ -z "$elfutils" ];then
        yum install -y elfutils-libelf-devel
    fi
    if [ -z "$patch" ];then
        yum install -y patch
    fi
    if [ -z "$m4" ];then
        yum install -y m4
    fi
    if [ -z "$kerneldevel" ];then
        yum install -y kernel-devel
    fi
    if [ -z "$python" ];then
        yum install -y python36
    fi
    if [ -z "$perl" ];then
        yum install -y perl
    fi
    if [ -z "$gcc_cpp" ];then
        yum install -y gcc-c++
    fi
    if [ -z "$ksh" ];then
        yum install -y ksh
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
    hn=$(grep "$inputParam1" $configFile | grep -oP "gw=\K[^$]+" | tr -d ' ')
    echo "" > /etc/hosts
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
    if [ $idevTotal > 1 ];then
        count=1
        for iface in $idevList;do
            nmcli device connect $iface
            nmcli connection modify $iface ipv4.method manual
            ip=$(grep "$inputParam1" $configFile | grep -oP "ip$count=\K[^|]+" | tr -d ' ')
            gw=$(grep "$inputParam1" $configFile | grep -oP "gw$count=\K[^|]+" | tr -d ' ')
            dns=$(grep "$inputParam1" $configFile | grep -oP "dns$count=\K[^|]+" | tr '-' ' ')
            if [ ! -z "$ip" ];then
                nmcli connection modify $iface ipv4.addresses $ip
            fi
            
            if [ ! -z "$gw" ];then
                nmcli connection modify $iface ipv4.gateway $gw
            fi

            if [ ! -z "$dns" ];then
                nmcli connection modify $iface ipv4.dns "$dns"
            fi
        count=$((count+1))
        done
    else
        nmcli connection modify $iface ipv4.method manual
        ip=$(grep "$inputParam1" $configFile | grep -oP "ip=\K[^|]+" | tr -d ' ')
        gw=$(grep "$inputParam1" $configFile | grep -oP "gw=\K[^|]+" | tr -d ' ')
        dns=$(grep "$inputParam1" $configFile | grep -oP "dns=\K[^|]+" | tr '-' ' ')
            if [ ! -z "$ip" ];then
                nmcli connection modify $iface ipv4.addresses $ip
            fi
            
            if [ ! -z "$gw" ];then
                nmcli connection modify $iface ipv4.gateway $gw
            fi

            if [ ! -z "$dns" ];then
                nmcli connection modify $iface ipv4.dns "$dns"
            fi
    fi
    hn=$(grep "$inputParam1" $configFile | grep -oP "hn=\K[^$]+" | tr -d ' ')
    nmcli general hostname $hn
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
    lvs=$(grep "lv=" $configFile | tr -d ' ')
    fs=$(grep "fs=" $configFile | awk -F "=" '{print $2}' | tr -d ' ')
    echo "$fs"
    for lv in $lvs;
    do
        lvName=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $1}' | tr -d ' ')
        lvSize=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $2}' | tr -d ' ')
        vgName=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $3}' | tr -d ' ')
        mountPoint=$(echo $lv | sed 's/^...//' | tr ',' ' ' | awk -F " " '{print $4}' | tr -d ' ')
        lvcreate -n $lvName -L $lvSize $vgName
        # XFS
        if [ "$fs" == "xfs" ];then
            mkfs.xfs /dev/"$vgName"/"$lvName"
        fi
        # Ext4
        if [ "$fs" == "ext4" ];then
            mkfs.ext4 /dev/"$vgName"/"$lvName"
        fi
        # Create folder for mount point
        if [ ! -d "$mountPoint" ];then
            mkdir "$mountPoint"
        fi
        mount /dev/"$vgName"/"$lvName" "$mountPoint"
        fstab=$(grep "$mountPoint" /etc/fstab)
        if [ -z $fstab ];then
            echo "/dev/$vgName/$lvName $mountPoint $fs defaults 1 2" >> /etc/fstab
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
    echo "alias sudb2='su - db2inst1'" >> .bashrc
    source .bashrc

    # Restart NetworkManager
    systemctl restart NetworkManager

    # Add alias sudb2
    echo "alias sudb2='su - db2inst1'" >> .bashrc
    source .bashrc
else    
    echo "The input.conig file not exist or first param not input, try again"
fi