#!/bin/bash
# Script by Acronix (acronix@coders.ph)
# Always check latest version of EasyRSA

# Set Parameters Accordingly

COUNTRY="US"
PROVINCE="California"
CITY="San Francisco"
ORG="Coders Republic"
EMAIL="admin@coders.ph"
OU="Community"

# Latest version of EasyRSA (.tgz)
RSAURL="https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.7/EasyRSA-3.0.7.tgz"


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # #  END OF CONFIGURATION  # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# SCRIPT START
# WARNING: DO NOT EDIT ANYTHING BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!

sudo apt update
sudo apt install wget -yy

# Common Name of Server (Ex. server)
# This is automatically generated. Please do not edit!
CNSERVER="vpn-usa2"

RSAFILE=$(echo $RSAURL | awk -F/ '{ print $NF }')
RSAFOLDER=${RSAFILE//.tgz/}

wget -P ~/ $RSAURL
cd ~
tar xvf $RSAFILE

cd ~/$RSAFOLDER/

sh -c 'echo "if [ -z \"\$EASYRSA_CALLER\" ]; then" > ~/'$RSAFOLDER'/vars'
sh -c 'echo "   echo \"You appear to be sourcing an Easy-RSA '\''vars'\'' file.\" >&2" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "   echo \"This is no longer necessary and is disallowed. See the section called\" >&2" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "   echo \"'\''How to use this file'\'' near the top comments for more details.\" >&2" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "   return 1" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "fi" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "set_var EASYRSA_REQ_COUNTRY        \"'$COUNTRY'\"" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "set_var EASYRSA_REQ_PROVINCE   \"'$PROVINCE'\"" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "set_var EASYRSA_REQ_CITY        \"'$CITY'\"" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "set_var EASYRSA_REQ_ORG            \"'$ORG'\"" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "set_var EASYRSA_REQ_EMAIL       \"'$EMAIL'\"" >> ~/'$RSAFOLDER'/vars'
sh -c 'echo "set_var EASYRSA_REQ_OU         \"'$OU'\"" >> ~/'$RSAFOLDER'/vars'

./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa import-req ~/$CNSERVER.req $CNSERVER
./easyrsa sign-req server $CNSERVER

chmod 700 ~/sign-cert.sh

echo ""
echo "You may now proceed with the server-install.sh script."
echo "Press [ENTER] on your Server Machine"
echo ""

# A couple of housekeeping commands
mkdir ~/OpenVPN
mv ~/ca-install.sh ~/$CNSERVER.req ~/OpenVPN/
rm ~/$RSAFILE

### EOF ###