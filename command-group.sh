host=$(hostname -i)
mkdir $host
cat /etc/security/passwd > ~/$host/2.txt
cat logins –axo > ~/$host/3.txt
cat/etc/login.defs > ~/$host/4.txt
cat/etc/shadow > ~/$host/5.txt
cat /etc/pam.d/system-auth > ~/$host/6.txt
cat /etc/pamd.conf > ~/$host/7.txt
cat /etc/hosts.equiv > ~/$host/8.txt
cat .rhosts > ~/$host/9.txt
cat /etc/passwd > ~/$host/10.txt
cat /etc/group > ~/$host/11.txt
cat /var/adm/sulog > ~/$host/12.txt
cat /etc/sudoers > ~/$host/13.txt
ls -al > ~/$host/14.txt
ls -la /etc/exports > ~/$host/15.txt
ls -la /etc/inetd.conf > ~/$host/16.txt
ls -la /etc/passwd > ~/$host/17.txt
ls -la /etc/services > ~/$host/18.txt
ls -la /etc/security > ~/$host/19.txt
ls -la /etc/securetty > ~/$host/20.txt
ls -la /etc/group > ~/$host/21.txt
ls -la /etc/ftpusers > ~/$host/22.txt
cat /etc/security/user > ~/$host/23.txt
cat /etc/sshd_config > ~/$host/24.txt
cat /etc/ssh/sshd_config > ~/$host/25.txt
lslpp -a -h > ~/$host/26.txt 
cat /var/adm/cron/cron.allow > ~/$host/27.txt
cat /var/adm/cron/cron.deny > ~/$host/28.txt
cat /var/adm/cron/at.allow > ~/$host/29.txt
cat /var/adm/cron/at.deny > ~/$host/30.txt
ls -la /var/adm/cron/cron.allow > ~/$host/31.txt
ls -la /var/adm/cron/cron.deny > ~/$host/32.txt
ls -la /var/adm/cron/at.allow > ~/$host/33.txt
ls -la /var/adm/cron/at.deny > ~/$host/34.txt
ls -la /var/adm/cron/* > ~/$host/35.txt
ls -la /var/spool/cron/crontab/* > ~/$host/36.txt
ls -la /var/spool/cron/atjobs/* > ~/$host/37.txt
crontab -l > ~/$host/38.txt
rm -rf command-group.sh