# l2tp-ipsec-setup-for-aws-centos7

## 1. create aws ec2 instance using CentOS Linux 7 x86_64 HVM ami-f5d7f195
  modify security group to allow ssh and l2tp/ipsec traffic (udp:  1701, 500, 4500)
  
## 2. ssh login to aws ec2 instance

## 3. clone remote repository to local aws ec2 server.
 $ sudo yum install -y git  
 $ git clone https://github.com/liyanatgit/l2tp-setup.git l2tp-setup

## 4. modify shell script if needed.
 $ vi l2tp-setup/l2tp-ipsec-setup-for-aws-centos7.sh  
  you may want to change the following secrets:
   - cat << _SECRETS_ > /tmp/SECRETS_TMP.txt 
   - PSK_SECRETS='psk.p@ss1234'  

## 5. run one shell file to set-up l2tp/ipsec vpn.
 $ sudo bash l2tp-setup/l2tp-ipsec-setup-for-aws-centos7.sh
 
## 6. confirm and vpn user management
 -  port confirm (udp: 1701, 500, 4500)  
    $ ss -autn
 -  vpn user management  
    $ sudo less /etc/ppp/chap-secrets
 -  using a vpn client (ios, mac, andriod, windows, etc.) to confirm if the vpn server works well 

## 7. trouble shooting  
 $ tail -f /var/log/xl2tpd.log /var/log/pluto.log  
 
## 8. monitoring
'''
 $ alias vpnuse='grep "CHAP Res" /var/log/xl2tpd.log | awk '\''{print $8}'\'' | uniq -c'  
 $ alias vpnuserall='grep "CHAP Res" /var/log/xl2tpd.log | awk '\''{print $8}'\'' | sort | uniq -c | sort -gr'
'''
