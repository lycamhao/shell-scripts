# Update
yum update -y

# Install nfs-utils and other pkg
yum install -y nfs-utils
yum install -y libstdc++.i686
yum install -y pam.i686

# Fix db2top
ln -s /lib64/libncurses.so.6 /lib64/libncurses.so.5
ln -s /lib64/libtinfo.so.6 /lib64/libtinfo.so.5

# Change hostname
sed 's\centos-9\DB2-SERVER-1\' /etc/hosts
echo "192.168.100.250 DB2-SERVER-1" >>  /etc/hosts
echo "192.168.100.247 DB2-SERVER-2" >>  /etc/hosts
cat /etc/hosts

# Disable SELINUX
sed 's\SELINUX=enforcing\SELINUX=disabled\' /etc/selinux/config

# Create folder for mount
mkdir /lv-db2ad
mkdir /lv-db2backups
mkdir /lv-db2arclogs
mkdir /lv-db2txlogs
mkdir /lv-db2data
mkdir /lv-db2install
mkdir /lv-db2instance

# Change IP DB2-SERVER-1
# nmcli connection modify ens18 ipv4.addresses 192.168.100.250/24
# nmcli connection modify ens18 ipv4.gateway 192.168.100.1
# nmcli connection modify ens18 ipv4.dns "8.8.8.8 8.8.4.4"
# nmcli connection modify ens18 ipv4.method manual
# nmcli general hostname DB2-SERVER-1
# nmcli connection up ens18

# Change IP DB2-SERVER-2
nmcli connection modify ens18 ipv4.addresses 192.168.100.247/24
nmcli connection modify ens18 ipv4.gateway 192.168.100.1
nmcli connection modify ens18 ipv4.dns "8.8.8.8 8.8.4.4"
nmcli general hostname DB2-SERVER-2
nmcli connection modify ens18 ipv4.method manual
# nmcli connection up ens18

# Create physical volume
pvcreate sdb /dev/sdb
pvcreate sdc /dev/sdc
pvcreate sdd /dev/sdd
pvcreate sde /dev/sde

# Create volume group
vgcreate vg-db2system /dev/sdb
vgcreate vg-db2data /dev/sdc
vgcreate vg-db2logs /dev/sdd
vgcreate vg-db2backups /dev/sde

# Create logical volume
lvcreate -n lv-db2install -L 5G vg-db2system
lvcreate -n lv-db2instance -L 20G vg-db2system
lvcreate -n lv-db2data -L 499.9G vg-db2data
lvcreate -n lv-db2txlogs -L 249.9G vg-db2logs
lvcreate -n lv-db2arclogs -L 249.9G vg-db2logs
lvcreate -n lv-db2ad -L 99.9G vg-db2backups
lvcreate -n lv-db2backups -L 399.9G vg-db2backups

# Format ext4 for logical volume
mkfs.ext4 /dev/vg-db2backups/lv-db2ad
mkfs.ext4 /dev/vg-db2backups/lv-db2backups
mkfs.ext4 /dev/vg-db2logs/lv-db2arclogs
mkfs.ext4 /dev/vg-db2logs/lv-db2txlogs
mkfs.ext4 /dev/vg-db2data/lv-db2data
mkfs.ext4 /dev/vg-db2system/lv-db2install
mkfs.ext4 /dev/vg-db2system/lv-db2instance

# Add fstab
echo "/dev/vg-db2backups/lv-db2ad /lv-db2ad ext4 defaults 1 2" >> /etc/fstab 
echo "/dev/vg-db2backups/lv-db2backups /lv-db2backups ext4 defaults 1 2" >> /etc/fstab 
echo "/dev/vg-db2logs/lv-db2arclogs /lv-db2arclogs ext4 defaults 1 2" >> /etc/fstab
echo "/dev/vg-db2logs/lv-db2txlogs /lv-db2txlogs ext4 defaults 1 2" >> /etc/fstab 
echo "/dev/vg-db2data/lv-db2data /lv-db2data ext4 defaults 1 2" >> /etc/fstab 
echo "/dev/vg-db2system/lv-db2install /lv-db2install ext4 defaults 1 2" >> /etc/fstab 
echo "/dev/vg-db2system/lv-db2instance /lv-db2instance ext4 defaults 1 2" >> /etc/fstab
 
# Reload and mount
systemctl daemon-reload 
mount -a

# Create user for DB2 instance
useradd db2inst1 -d /lv-db2instance
groupadd dbiadmin
usermod db2inst1 -g dbiadmin 
chown -R db2inst1:dbiadmin /lv-db2*

# Create and mount nfs then copy DB2 Source
mkdir /nfs
chown -R db2inst1:dbiadmin /nfs
mount -t nfs4 192.168.100.253:/lv-sharestore/nfs /nfs
cp /nfs/v11.5.9_linuxx64_server_dec.tar ./

# Install DB2
tar -xvf v11.5.9_linuxx64_server_dec.tar
cd server_dec
./db2prereqcheck -v 11.5.9.0
./db2_install -b /lv-db2install -t NOTSAMP

# Create Instance
cd /lv-db2install/instance/
./db2icrt -u db2inst1 db2inst1
ll /lv-db2instance/

# Create sample db
su - db2inst1
db2start
db2sampl -dbpath /lv-db2data/ -name CRM -verbose

# Add alias to .bashrc
cd ~
echo "alias bkincreinsvndb='db2 backup db insvndb incremental to /db2backup compress'" >> .bashrc
echo "alias bkinsvndb='db2 backup db insvndb online to /db2backup include logs compress'" >> .bashrc
echo "alias bkoffinsvndb='db2 backup db insnvbd to /db2backup compress'" >> .bashrc
echo "alias connrs='db2 connect reset'" >> .bashrc
echo "alias conto='db2 connect to'" >> .bashrc
echo "alias contoinsvndb='db2 connect to insvndb'" >> .bashrc
echo "alias contocrm='db2 connect to insvndb'" >> .bashrc
echo "alias contosample='db2 connect to insvndb'" >> .bashrc
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
echo "alias l.='ls -d .* --color=auto'" >> .bashrc
echo "alias listapp='db2 list application'" >> .bashrc
echo "alias ll='ls -l --color=auto'" >> .bashrc
echo "alias ls='ls --color=auto'" >> .bashrc
echo "alias onswitch='db2 update monitor switches using bufferpool on lock on table on statement on uow on sort on timestamp on'" >> .bashrc
echo "alias resetswitch='db2 reset monitor for database '" >> .bashrc
source .bashrc

# setting for db2
db2 update db cfg for CRM USING LOGARCHMETH1 DISK:/lv-db2arclogs
db2 update db cfg for CRM USING LOGARCHCOMPR1 ON
db2 update db cfg for CRM USING NEWLOGPATH /lv-db2txlogs

# Deactive and restart DB2 Service
db2 terminate
db2stop
db2start
