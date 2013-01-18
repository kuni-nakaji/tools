VERSION='2.0'

MYIP='127.0.0.1'
MYHOST='local'
MYDOMAIN=$MYHOST'.localdomain'
PRIVATEIP='0.0.0.0'
PRIVATEHOST=$MYHOST
GITIP='180.214.43.170'
GITHOST='git.real.world'

# ganglia param
CLUSTER_NAME="\"ganglia cluster\""
PORT_NO='9999'


echo 'START: '`date`
echo 'Version: '$VERSION

# ----------------------------------------------
# 1. [ALL]update
# ----------------------------------------------
echo '###### 1.Update ######'

yum -y update
yum -y groupinstall 'Development Libraries' 'Development Tools'

# ----------------------------------------------
# 2. [ALL]stop process
# ----------------------------------------------
echo '###### 2.Stop Process ######'

for i in `echo anacron atd autofs avahi-daemon avahi-dnsconfd irqbalance iscsi iscsid ip6tables netfs nfslock portmap rawdevices rpcgssd rpcidmapd named bluetooth hidd ip6tables kudzu messagebus pcscd xfs yum-updatesd mcstrans firstboot gpm auditd`;
do
  chkconfig ${i} off;
done

for i in `echo portmap avahi-daemon cups nfslock named`; do service ${i} stop; done

# ----------------------------------------------
# 3. [ALL]Network setting
#  ex)
#   127.0.0.1       fas-web2.freeappsale.jp fas-web2
#   180.214.43.170  git.real.world
# ----------------------------------------------
echo '###### 3.Network Setting ######'

NETWORK_FILE='/etc/sysconfig/network'
cp -p  $NETWORK_FILE $NETWORK_FILE.`date '+%Y%m%d'`
sed -i 's/localhost.localdomain/'$MYDOMAIN'/g' $NETWORK_FILE
cat $NETWORK_FILE

HOSTS_FILE='/etc/hosts'
cp -p $HOSTS_FILE $HOSTS_FILE.`date '+%Y%m%d'`
sed -i '$s/$/\n'$MYIP'\t'$MYHOST'\t'$MYDOMAIN'/g' $HOSTS_FILE
sed -i '$s/$/\n'$GITIP'\t'$GITHOST'/g' $HOSTS_FILE
sed -i '$s/$/\n'$PRIVATEIP'\t'$PRIVATEHOST'/g' $HOSTS_FILE
cat $HOSTS_FILE

RESOLV_FILE='/etc/resolv.conf'
cp -p $RESOLV_FILE $RESOLV.`date '+%Y%m%d'`
sed -i 's/localdomain/localdomain\nnameserver 202.248.37.74\nnameserver 202.248.20.133/g' $RESOLV_FILE
cat $RESOLV_FILE

# ----------------------------------------------
# 4. [ALL]make skelton
# ----------------------------------------------
echo '###### 4.Make Skelton ######'

mkdir /etc/skel/.ssh
chmod 755 /etc/skel/.ssh
touch /etc/skel/.ssh/authorized_keys
chmod 644 /etc/skel/.ssh/authorized_keys

# ----------------------------------------------
# 5. [ALL]create account
#      -> Use LDAP (12/25)
# ----------------------------------------------
#echo '###### 5.Create Account ######'

#groupadd developer
#groupadd realworld

# ----------------------------------------------
# 6. [ALL]su setting
# ----------------------------------------------
echo '###### 6.SU Setting ######'

cp -ai /etc/pam.d/su /etc/pam.d/su.`date '+%Y%m%d'`
sed -i 's/^#\(auth.*required.*pam_wheel.so use_uid\)/\1/g' /etc/pam.d/su

# ----------------------------------------------
# 7. [ALL]package setting
# ----------------------------------------------
echo '###### 7.Package Setting ######'

mkdir /root/work
cd /root/work
rpm -ivh http://ftp.riken.jp/Linux/fedora/epel/5Client/x86_64/epel-release-5-4.noarch.rpm
rpm -ivh http://rpms.famillecollet.com/el5.x86_64/remi-release-5-8.el5.remi.noarch.rpm
# rpm -ivh http://repo.webtatic.com/yum/centos/5/latest.rpm
rpm -ivh http://repo.webtatic.com/yum/centos/5/x86_64/webtatic-release-5-2.noarch.rpm
ls /etc/yum.repos.d

# ----------------------------------------------
# 8. [ALL]NTP
# ----------------------------------------------
echo '###### 8.NTP ######'

yum -y --disablerepo=* --enablerepo=base,update install ntp
cp -ai /etc/ntp.conf /etc/ntp.conf.`date '+%Y%m%d'`
cat > /etc/ntp.conf << __EOF__
         restrict default kod nomodify notrap nopeer noquery
         restrict 127.0.0.1
         server 0.centos.pool.ntp.org
         server 1.centos.pool.ntp.org
         server 2.centos.pool.ntp.org
         server  127.127.1.0     # local clock
         fudge   127.127.1.0 stratum 10
         driftfile /var/lib/ntp/drift
         keys /etc/ntp/keys
__EOF__
chkconfig ntpd on
service ntpd start
ntpq -p

# ----------------------------------------------
# 9. [ALL]Create key
# ----------------------------------------------

# ----------------------------------------------
# 10. [Nifty]Nifty monitor Setting
# ----------------------------------------------
echo '###### 10.Nifty Monitor Setting ######'

SNMP_FILE='/etc/snmp/snmpd.conf'
yum -y install net-snmp
chkconfig snmpd on
cp -p $SNMP_FILE $SNMP_FILE.`date '+%Y%m%d'`

ADD_TMP='/tmp/snmp_tmp'
TMP_FILE='/tmp/snmp_tmp2'
cat << __TXT__ > $ADD_TMP
###############################################################################
# Nifty setting
rocommunity niftycloud 10.100.0.14 .1.3.6.1.
rocommunity niftycloud 10.100.8.15 .1.3.6.1.
rocommunity niftycloud 10.100.16.13 .1.3.6.1.
rocommunity niftycloud 10.100.32.15 .1.3.6.1.
rocommunity niftycloud 202.248.175.141 .1.3.6.1.
disk / 10000
__TXT__
cat $SNMP_FILE $ADD_TMP > $TMP_FILE
\mv $TMP_FILE $SNMP_FILE
service snmpd start

# ----------------------------------------------
# 11. [Nifty]Security tool
# ----------------------------------------------
echo '###### 11.Security tool ######'

yum -y install nmap

# ----------------------------------------------
# 12. [Nifty]LDAP
#   need to set FW on Bit-isle
#      180.214.43.170
#      180.214.43.176
# ----------------------------------------------
echo '###### 12.LDAP ######'

yum -y install openldap-clients.x86_64 pam_ldap nss-pam-ldapd
cp -p /etc/ldap.conf /etc/ldap.conf.`date '+%Y%m%d'`
cp -p /etc/pam_ldap.conf /etc/pam_ldap.conf.`date '+%Y%m%d'`
cp -p /etc/sudo-ldap.conf /etc/sudo-ldap.conf.`date '+%Y%m%d'`
cp -p /etc/nslcd.conf /etc/nslcd.conf.`date '+%Y%m%d'`

## LDAP setting
cat > /etc/ldap.conf << __EOF__
host 180.214.43.176
base dc=realworld,dc=jp
ldap_version 3
binddn cn=Admin,dc=realworld,dc=jp
bindpw aEzvQ66o
port 389
timelimit 120
bind_timelimit 120
bind_policy soft
idle_timelimit 3600
pam_filter &(objectClass=posixAccount)(|(description=admin)(description=))
nss_initgroups_ignoreusers root,ldap,named,avahi,haldaemon,dbus,radvd,tomcat,radiusd,news,mailman,nscd,gdm,puppet,git,apache,bin,daemon,adm,lp,sync,shutdown,halt,mail,uucp,operator,games,gopher,ftp,oprofile,rpcuser,rpc,ntp,xfs,mailnull,smmsp,vcsa,sshd,pcap,distcache,nobody,ganglia,qmaild,qmaill,qmailp,alias,qmailq,qmailr,qmails,nfsnobody,mysql
pam_password md5
uri ldaps://180.214.43.176/
tls_cacertdir /etc/openldap/cacerts
sudoers_base ou=SUDOers,dc=realworld,dc=jp
TLS_REQCERT never
TLS_CHECKPEER no
__EOF__

## Auth setting
cp -ai /etc/pam.d/system-auth-ac /etc/pam.d/system-auth-ac.`date '+%Y%m%d'`
cat > /etc/pam.d/system-auth-ac << __EOF__
auth        required      pam_env.so
auth        sufficient    pam_unix.so nullok try_first_pass
auth        requisite     pam_succeed_if.so uid >= 500 quiet
auth        sufficient    pam_ldap.so use_first_pass
auth        required      pam_deny.so
account     required      pam_unix.so broken_shadow
account     sufficient    pam_succeed_if.so uid < 500 quiet
account     [default=bad success=ok user_unknown=ignore] pam_ldap.so
account     required      pam_permit.so
password    requisite     pam_cracklib.so try_first_pass retry=3
password    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok
password    sufficient    pam_ldap.so use_authtok
password    required      pam_deny.so
session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
session     required      pam_mkhomedir.so skel=/etc/skel umask=0077
session     optional      pam_ldap.so
__EOF__

## nsswitch.conf
cp -p /etc/nsswitch.conf /etc/nsswitch.conf.`date '+%Y%m%d'`
sed -i 's/passwd:     files/passwd:     files ldap/g' /etc/nsswitch.conf
sed -i 's/group:      files/group:     files ldap/g' /etc/nsswitch.conf
sed -i '$s/^/sudoers:    files ldap/g' /etc/nsswitch.conf

## Copy key
mkdir /etc/openldap/cacerts
echo "copy key"
scp 180.214.43.170:/tmp/cacert.pem /etc/openldap/cacerts

## Check LDAP
yum -y install nscd
service nscd start
chkconfig nscd on
echo "LDAP check: enter password"
ldapsearch -x -h ldaps://180.214.43.176 -D "cn=Manager,dc=realworld,dc=jp" -b "cn=gendama,ou=Group,dc=realworld,dc=jp" -W|grep gendama
echo ""

## Clean LDAP
yum remove openldap-clients
cat /etc/ldap.conf|grep description

# ----------------------------------------------
# 13. [Nifty]Ganglia
# ----------------------------------------------
echo '###### 13.Ganglia ######'

## Check Python file
find /home -name *.pyc
find /home -name *.py

## Regist repository
if [ ! -f /etc/yum.repos.d/centos-5.5-x86_64-realworld.repo ] ; then
cat > /etc/yum.repos.d/centos-5.5-x86_64-realworld.repo << __EOF__
[centos-5.5-x86_64-realworld]
name=centos-5.5-x86_64-realworld
baseurl=http://180.214.43.158/cobbler/repo_mirror/centos-5.5-x86_64-realworld/
enabled=0
gpgcheck=0
__EOF__
fi

cat /etc/yum.repos.d/centos-5.5-x86_64-realworld.repo

## Check repository
yum --enablerepo=centos-5.5-x86_64-realworld list ganglia-gmond libganglia-3_1_0-3.1.7-1 ganglia-gmond-modules-python

## Install ganglia: ganglia-gmond libganglia-3_1_0-3.1.7-1
yum -y --enablerepo=centos-5.5-x86_64-realworld install ganglia-gmond libganglia-3_1_0-3.1.7-1
yum -y --enablerepo=centos-5.5-x86_64-realworld install ganglia-gmond-modules-python

## Install DB module: MySQL-python26
yum -y --enablerepo=centos-5.5-x86_64-realworld install MySQL-python26*

## Create User：ganglia
## uid 101か105で作成する
if [ `cat /etc/passwd | grep ":101:" | wc -l` -eq 0 ]; then
  groupadd -g 105 ganglia && useradd -u 101 -g 105 -c 'Ganglia Monitoring System' -d /var/lib/ganglia -s /sbin/nologin -M ganglia
elif [ `cat /etc/passwd | grep ":105:" | wc -l` -eq 0 ]; then
  groupadd -g 105 ganglia && useradd -u 105 -g 105 -c 'Ganglia Monitoring System' -d /var/lib/ganglia -s /sbin/nologin -M ganglia
else
  exit 1
fi

id ganglia

## Setting route
## 内部IPを持っているeth1に設定すること

ifconfig
echo "Before set routing"
netstat -rn
route add -net 239.2.11.71 dev eth1 netmask 255.255.255.255

echo "After set routing"
netstat -rn

echo "239.2.11.71 dev eth1" >> /etc/sysconfig/network-scripts/route-eth1

cat /etc/sysconfig/network-scripts/route-eth1
cp -p /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.`date +%Y%m%d`
ls -l /etc/ganglia/gmond.conf*

## Copy conf.d & python_modules
scp root@180.214.43.170:/home/imura/work/ganglia/conf.d/*         /etc/ganglia/conf.d/
scp root@180.214.43.170:/home/imura/work/ganglia/python_modules/* /usr/lib64/ganglia/python_modules/

## ※！ポート番号修正すること！※
## ※！クラスタ名修正すること！※
sed -i "s/name = \"unspecified\"/name = ${CLUSTER_NAME}/" /etc/ganglia/gmond.conf
sed -i "s/user = nobody/user = ganglia/" /etc/ganglia/gmond.conf
sed -i "s/port = 8649/port = ${PORT_NO}/" /etc/ganglia/gmond.conf
cat /etc/ganglia/gmond.conf | egrep '${CLUSTER_NAME}|ganglia|${PORT_NO}'

## OPTION START
## ------------------------------------------------------------
## [WEB]
#rm -f /etc/ganglia/conf.d/mysql.pyconf
#rm -f /usr/lib64/ganglia/python_modules/mysql.py
#rm -f /usr/lib64/ganglia/python_modules/mysql.pyc
#rm -f /usr/lib64/ganglia/python_modules/DBUtil.py
#rm -f /usr/lib64/ganglia/python_modules/DBUtil.pyc

## [DB][Master]
#echo 'GRANT SUPER, PROCESS ON *.* TO ganglia@localhost IDENTIFIED BY "iy9QD6bV"' | mysql -u root -p'w2QldN5v'
#sed -i "s/value = 'mmm_agent'/value = 'ganglia'/" /etc/ganglia/conf.d/mysql.pyconf
#sed -i "s/value = 'RepAgent'/value = 'iy9QD6bV'/"   /etc/ganglia/conf.d/mysql.pyconf
#cat /etc/ganglia/conf.d/mysql.pyconf | egrep 'ganglia|iy9QD6bV'

## [DB]
#rm -f /etc/ganglia/conf.d/apache_status.pyconf
#rm -f /usr/lib64/ganglia/python_modules/apache_status.py
#rm -f /usr/lib64/ganglia/python_modules/apache_status.pyc
## ------------------------------------------------------------
## OPTION END

## ポート解放
## ニフティ用設定等のコメントがあるので
## ファイルを直接修正してrestoreする。
cp -p /etc/sysconfig/iptables /etc/sysconfig/iptables.`date +%Y%m%d`

#vi /etc/sysconfig/iptables

## iptablesのfilter テーブルに追加
# ※！ポート番号修正すること！※
#---↓ここから↓---
## Ganglia Setting !!!!
#-A RH-Firewall-1-INPUT -p tcp -m tcp --dport 8656 -j ACCEPT
#-A RH-Firewall-1-INPUT -p udp -m udp --dport 8656 -j ACCEPT
#---↑ここまで↑---

#iptables-restore < /etc/sysconfig/iptables
#cat /etc/sysconfig/iptables
#iptables -L -t filter -n
#iptables -L -t mangle -n

## 起動
#service gmond start
service gmond status
chkconfig gmond on
chkconfig --list | grep gmond

echo 'END: '`date`
