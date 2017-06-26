#!/bin/bash -x
# Description:
#  L2TP/IPsec for CentOS Linux 7 x86_64 HVM ami-f5d7f195 @ aws
# 2017/06/21 

(
## setting

cat << _SECRETS_ > /tmp/SECRETS_TMP.txt
#==============================================
# username auth_server password auth_ipaddress
"guest01" "xl2tpd" "p@ss1234" *
#==============================================
_SECRETS_

PSK_SECRETS='psk.p@ss1234'

COLOR_LIGHT_GREEN='\033[1;32m'
COLOR_LIGHT_BLUE='\033[1;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[1;37m'
COLOR_DEFAULT='\033[0m'

IPADDR_GLOBAL=$(/sbin/ip addr show eth0 2>/dev/null | /bin/grep 'inet ' | /bin/sed -e 's/.*inet \([^ ]*\)\/.*/\1/')

VPN_LOCAL_IPADDRESS='192.168.5.99'
VPN_REMOTE_IPADDRESS='192.168.5.128-254'

## add repositoory：EPEL
yum install -y epel-release

## install package needed
#yum install -y xl2tpd libreswan lsof
yum erase -y xl2tpd libreswan
yum install -y xl2tpd libreswan

## lsof firewalld needed because the original centos7 ami lack of these packages
yum install -y lsof firewalld
#yum update -y

## L2TP setup
sed -i.org -e "s/; listen-addr.*/listen-addr = ${IPADDR_GLOBAL}/g" -e "s/ip range.*/ip range = ${VPN_REMOTE_IPADDRESS}/g" -e "s/local ip.*/local ip = ${VPN_LOCAL_IPADDRESS}/g" /etc/xl2tpd/xl2tpd.conf

#sed -i.org -e "s/^ms-dns/# ms-dns/g" -e "s/^noccp/# noccp/g" /etc/ppp/options.xl2tpd
sed -i.org -e "s/^ms-dns/# ms-dns/g" -e "s/^noccp/# noccp/g" -e "s/^crtscts/# crtscts/g" -e "s/^lock/# lock/g" /etc/ppp/options.xl2tpd

cat << _XL2TPDCONF_ >> /etc/ppp/options.xl2tpd
ms-dns 8.8.8.8
ms-dns 209.244.0.3
ms-dns 208.67.222.222
name xl2tpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
persist
logfile /var/log/xl2tpd.log
_XL2TPDCONF_

## IPsec setup
sed -i.org -e "s/^#include/include/g" /etc/ipsec.conf
cat << _IPSECCONF_ > /etc/ipsec.d/l2tp-ipsec.conf
conn L2TP-PSK-NAT
    rightsubnet=0.0.0.0/0
    dpddelay=10
    dpdtimeout=20
    dpdaction=clear
    forceencaps=yes
    also=L2TP-PSK-noNAT
conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    rekey=no
    ikelifetime=8h
    keylife=1h
    type=transport
    left=${IPADDR_GLOBAL}
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
_IPSECCONF_

cat /tmp/SECRETS_TMP.txt >> /etc/ppp/chap-secrets
rm /tmp/SECRETS_TMP.txt
echo -e ": PSK \"${PSK_SECRETS}\"" > /etc/ipsec.d/default.secrets

## Enable and Restart firewalld
systemctl enable firewalld
systemctl restart firewalld

## firewalld setup
firewall-cmd --permanent --add-service=ipsec
firewall-cmd --permanent --add-port=1701/udp
firewall-cmd --permanent --add-port=4500/udp
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload

## IP_FORWARD setting
cat << _SYSCTLCONF_ > /etc/sysctl.d/60-sysctl_ipsec.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.eth0.accept_redirects = 0
net.ipv4.conf.eth0.rp_filter = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.conf.eth1.accept_redirects = 0
net.ipv4.conf.eth1.rp_filter = 0
net.ipv4.conf.eth1.send_redirects = 0
net.ipv4.conf.eth2.accept_redirects = 0
net.ipv4.conf.eth2.rp_filter = 0
net.ipv4.conf.eth2.send_redirects = 0
net.ipv4.conf.ip_vti0.accept_redirects = 0
net.ipv4.conf.ip_vti0.rp_filter = 0
net.ipv4.conf.ip_vti0.send_redirects = 0
net.ipv4.conf.lo.accept_redirects = 0
net.ipv4.conf.lo.rp_filter = 0
net.ipv4.conf.lo.send_redirects = 0
net.ipv4.conf.ppp0.accept_redirects = 0
net.ipv4.conf.ppp0.rp_filter = 0
net.ipv4.conf.ppp0.send_redirects = 0
_SYSCTLCONF_
systemctl restart network

## enable and start process
systemctl enable ipsec
systemctl enable xl2tpd
systemctl restart ipsec
systemctl restart xl2tpd

## Finish
echo -e "${COLOR_WHITE}L2TP/IPsec SERVER IP     : ${COLOR_LIGHT_GREEN}${IPADDR_GLOBAL}${COLOR_DEFAULT}"
echo -e "${COLOR_WHITE}L2TP/IPsec USER/PASSWORD : \n${COLOR_LIGHT_GREEN}$(/bin/cat /etc/ppp/chap-secrets)${COLOR_DEFAULT}"
echo -e "${COLOR_WHITE}L2TP/IPsec PSK SECRETS   : ${COLOR_LIGHT_GREEN}${PSK_SECRETS}${COLOR_DEFAULT}"
echo -e "${COLOR_WHITE}Install log              : ${COLOR_LIGHT_GREEN}/var/log/l2tp-ipsec-installer.log${COLOR_DEFAULT}"

) 2>&1 | tee /var/log/l2tp-ipsec-installer.log
