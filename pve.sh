# List vm
qm list 

# List vm config 
qm config 101
qm config 115

# List vm status
qm status 101

# Start vm
qm start 101
qm start 115

# Stop vm
qm stop 101
qm stop 115

# Clone VM (linked clone)
qm clone 100 101 --name "DB2-SERVER-1" --full no 
qm clone 100 115 --name "DB2-SERVER-2" --full no 

# Snap shot VM with vmstate
qm snapshot 101 "Origin" --vmstate yes
qm snapshot 115 "Origin" --vmstate yes

# Snap shot VM without vmstate
qm snapshot 101 "Origin" --vmstate no
qm snapshot 115 "Origin" --vmstate no

# Add vm disk to VM
qm set 101 -scsi2 VM-STORE:500,format=qcow2,iothread=on
qm set 101 -scsi3 VM-STORE:500,format=qcow2,iothread=on
qm set 101 -scsi1 VM-STORE:500,format=qcow2,iothread=on
qm set 101 -scsi4 VM-STORE:500,format=qcow2,iothread=on

qm set 115 -scsi1 VM-STORE:500,format=qcow2,iothread=on
qm set 115 -scsi2 VM-STORE:500,format=qcow2,iothread=on
qm set 115 -scsi3 VM-STORE:500,format=qcow2,iothread=on
qm set 115 -scsi4 VM-STORE:500,format=qcow2,iothread=on

# VM auto start
qm set 101 --auto yes
qm set 115 --auto yes 

# Destroy VM
qm destroy 101 --purge
qm destroy 115 --purge

# Change VM RAM
qm set 101 --memory 8192
qm set 115 --memory 6144

# Show vm config
qm config 101
qm config 115