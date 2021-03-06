#!/bin/bash
## VARIAVEIS
TFPATH="$PWD"
CHKSGNOK=`grep "sg" $TFPATH/0-terraform/sg-ok.tf | wc -l`
CHAVESSH="/var/lib/jenkins/.ssh/grupo-one.pem"
AMIID="cat /tmp/k8s-ami-id.tmp"
###########################

cd $TFPATH/0-terraform/

CHKTFOUTPUT=$(terraform output | wc -l)

if [ ${CHKTFOUTPUT} -lt 25 ]; 
  then
  echo "TERRAFORM INCOMPLETO OU DESTRUIDO"
  exit 1
fi

#PEGA O ESTADO DO TERRAFORM
cd $TFPATH/0-terraform/

### RETIRA OS IPS E DNS DAS MAQUINAS
terraform output | sed 's/\",//g' > $TFPATH/tmp/tfoutput.tmp

ID_M1=`awk '/IP k8s-master azc1 -/ {print $5}' $TFPATH/tmp/tfoutput.tmp`
ID_M1_DNS=`awk '/IP k8s-master azc1 -/ {print $8}' $TFPATH/tmp/tfoutput.tmp | cut -d"@" -f2`

ID_M2=`awk '/IP k8s-master aza2 -/ {print $5}' $TFPATH/tmp/tfoutput.tmp`
ID_M2_DNS=`awk '/IP k8s-master aza2 -/ {print $8}' $TFPATH/tmp/tfoutput.tmp | cut -d"@" -f2`

ID_M3=`awk '/IP k8s-master azc3 -/ {print $5}' $TFPATH/tmp/tfoutput.tmp`
ID_M3_DNS=`awk '/IP k8s-master azc3 -/ {print $8}' $TFPATH/tmp/tfoutput.tmp | cut -d"@" -f2`

ID_HAPROXY=`awk '/k8s_proxy -/ {print $3}' $TFPATH/tmp/tfoutput.tmp`
ID_HAPROXY_DNS=`awk '/k8s_proxy -/ {print $6}' $TFPATH/tmp/tfoutput.tmp | cut -d"@" -f2`

ID_W1=`awk '/IP k8s-workers azc1 -/ {print $5}' $TFPATH/tmp/tfoutput.tmp`
ID_W1_DNS=`awk '/IP k8s-workers azc1 -/ {print $8}' $TFPATH/tmp/tfoutput.tmp | cut -d"@" -f2`

ID_W2=`awk '/IP k8s-workers aza2 -/ {print $5}' $TFPATH/tmp/tfoutput.tmp`
ID_W2_DNS=`awk '/IP k8s-workers aza2 -/ {print $8}' $TFPATH/tmp/tfoutput.tmp | cut -d"@" -f2`

ID_W3=`awk '/IP k8s-workers azc3 -/ {print $5}' $TFPATH/tmp/tfoutput.tmp`
ID_W3_DNS=`awk '/IP k8s-workers azc3 -/ {print $8}' $TFPATH/tmp/tfoutput.tmp | cut -d"@" -f2`


echo "
ID_M1_DNS=${ID_M1_DNS}
ID_M2_DNS=${ID_M2_DNS}
ID_M3_DNS=${ID_M3_DNS}
" > $TFPATH/k8s-nginx-frontend/02-ansible/ipsmaster.txt

# COLOCA A INFRMACAO DOS IPS NO HOSTS DO ANSIBLE
echo "
[ec2-k8s-proxy]
$ID_HAPROXY_DNS

[ec2-k8s-m1]
$ID_M1_DNS
[ec2-k8s-m2]
$ID_M2_DNS
[ec2-k8s-m3]
$ID_M3_DNS

[ec2-k8s-w1]
$ID_W1_DNS
[ec2-k8s-w2]
$ID_W2_DNS
[ec2-k8s-w3]
$ID_W3_DNS

" > $TFPATH/2-ansible/01-k8s-install-masters_e_workers/hosts

cat $TFPATH/2-ansible/01-k8s-install-masters_e_workers/hosts



echo "
ID_M1_DNS=${ID_M1_DNS}
ID_M2_DNS=${ID_M2_DNS}
ID_M3_DNS=${ID_M3_DNS}
" > /tmp/ipmasters.tmp

echo "127.0.0.1 localhost
${ID_M1} master1
${ID_M2} master2
${ID_M3} master3


# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
" > $TFPATH/tmp/hostsnginx.tmp

scp -i ${CHAVESSH} $TFPATH/tmp/hostsnginx.tmp root@ec2-18-231-181-242.sa-east-1.compute.amazonaws.com:/etc/hosts
ssh -i ${CHAVESSH} root@ec2-18-231-181-242.sa-east-1.compute.amazonaws.com 'systemctl restart nginx'

####################
### SEGUE PARA O SCRIPT haproxy.sh