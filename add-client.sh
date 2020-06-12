#!/bin/bash
cd ~/EasyRSA-3.0.7/
./easyrsa gen-req $1 nopass
cp pki/private/$1.key ~/client-configs/keys/
scp pki/reqs/$1.req acronix@35.194.185.43:/tmp
read -p "Switch to CA machine and press ENTER here when instructed..."
scp acronix@35.194.185.43:/home/acronix/EasyRSA-3.0.7/pki/issued/$1.crt /tmp
cp /tmp/$1.crt ~/client-configs/keys/
cd ~/client-configs
sudo ./make_config.sh $1
echo ''
ls files
echo ''
echo "You may now transfer /home/acronix/client-configs/files/$1.ovpn to your client device."
