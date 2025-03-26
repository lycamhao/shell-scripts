pvcreate sdb /dev/sdb
pvcreate sdc /dev/sdc
pvcreate sdd /dev/sdd
pvcreate sde /dev/sde

vgcreate vg-db2system /dev/sdb
vgcreate vg-db2data /dev/sdc
vgcreate vg-db2logs /dev/sdd
vgcreate vg-db2backup /dev/sde

lvcreate -n lv-db2install -L 5G vg-db2system
lvcreate -n lv-db2instance -L 20G vg-db2system
lvcreate -n lv-db2data -L 499.9G vg-db2data
lvcreate -n lv-db2txlogs -L 249.9G vg-db2logs
lvcreate -n lv-db2arclog -L 249.9G vg-db2logs
lvcreate -n lv-db2ad -L 99.9G vg-db2backup
lvcreate -n lv-db2backup -L 399.9G vg-db2backup

mkfs.ext4 /dev/vg-db2backup/lv-db2ad
mkfs.ext4 /dev/vg-db2backup/lv-db2backup
mkfs.ext4 /dev/vg-db2logs/lv-db2arclog
mkfs.ext4 /dev/vg-db2logs/lv-db2txlogs
mkfs.ext4 /dev/vg-db2data/lv-db2data
mkfs.ext4 /dev/vg-db2system/lv-db2install
mkfs.ext4 /dev/vg-db2system/lv-db2instance

mkdir /lv-db2install
mkdir /lv-db2instance
mkdir /lv-db2data
mkdir /lv-db2ad
mkdir /lv-db2txlogs
mkdir /lv-db2backups
mkdir /lv-db2arclog

useradd db2inst1 -d /lv-db2instance
groupadd dbiadmin
usermod db2inst1 -g dbiadmin 
chown -R db2inst1:dbiadmin /lv-db2*

systemctl daemon-reload 
mount -a
mkdir /nfs
chown -R db2inst1:dbiadmin /nfs
yum install -y nfs-utils
yum install -y libstdc++.i686
yum install -y pam.i686
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
# Fix db2top
ln -s /lib64/libncurses.so.6 /lib64/libncurses.so.5
ln -s /lib64/libtinfo.so.6 /lib64/libtinfo.so.5
db2top -d CRM