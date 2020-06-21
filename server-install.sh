#!/bin/bash
# Script by Acronix (acronix@coders.ph)
# Always check latest version of EasyRSA;
# EasyRSA: https://github.com/OpenVPN/easy-rsa/releases
# Please set the script to download the .tgz version;

# Set Parameters Accordingly;
# Make sure that your Server has access to the CA Machine;
# You may need to configure the ssh-keys in order to work correctly;

# Latest version of EasyRSA (.tgz)
RSAURL="https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.7/EasyRSA-3.0.7.tgz"

#### The section below has been deprecated and replaced with user prompts ####
#CNSERVER="vpn-usa2"         # Common Name of Server (Ex. server)
#SERVERIP="10.10.10.11"      # IP Address of your VPN Server
#CAUSER="acronix"            # Non-root user of the CA Machine
#PORTN="1194"                # Port Number used by the VPN
#PROTO="udp"                 # Choose either "tcp" or "udp"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # #  END OF CONFIGURATION  # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


# WARNING: PLEASE DO NOT EDIT ANYTHING BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!


#STEP1: Installing OpenVPN, EasyRSA, UFW, and dnsutils
sudo apt update
sudo apt install openvpn ufw wget dnsutils -yy

echo ""

read -p "Common Name of VPN Server [vpn-usa2]: " CNSERVER
: ${CNSERVER:=vpn-usa2}

read -p "IP Address of VPN Server [10.10.10.11]: " SERVERIP
: ${SERVERIP:=10.10.10.11}

read -p "Port Number [1194]: " PORTN
: ${PORTN:=1194}

read -p "Protocol (tcp/udp) [udp]: " PROTO
: ${PROTO:=udp}

read -p "Non-root user of CA Machine [acronix]: " CAUSER
: ${CAUSER:=acronix}

read -p "IP Address of CA Machine [10.10.10.12]: " CAIPADD
: ${CAIPADD:=10.10.10.12}

RSAFILE=$(echo $RSAURL | awk -F/ '{ print $NF }')
RSAFOLDER=${RSAFILE//.tgz/}

wget -P ~/ $RSAURL
cd ~
tar xvf $RSAFILE

#### Create ~/sign-cert.sh File (to be used by CA Machine) ####
sh -c 'echo "#!/bin/bash" > ~/sign-cert.sh'
sh -c 'echo "cd ~/"'$RSAFOLDER'"/" >> ~/sign-cert.sh'
sh -c 'echo "./easyrsa import-req /tmp/\$1.req \$1" >> ~/sign-cert.sh'
sh -c 'echo "./easyrsa sign-req client \$1" >> ~/sign-cert.sh'
sh -c 'echo "echo \"You may now press ENTER on the other machine.\"" >> ~/sign-cert.sh'
chmod 700 ~/sign-cert.sh

# Update Common name of Server for ca-install.sh
sed -i "s/CNSERVER=\"vpn-usa2\"/CNSERVER=\"$CNSERVER\"/" ~/OpenVPN/ca-install.sh

#STEP2: EasyRSA Variables & Building the CA
#This is done inside the CA Machine

#STEP3: Server Certificate, Key & Encryption FIles
cd ~/$RSAFOLDER/
./easyrsa init-pki
./easyrsa gen-req $CNSERVER nopass
sudo cp ~/$RSAFOLDER/pki/private/$CNSERVER.key /etc/openvpn/
echo ""
echo "You are now going to SCP (upload) files to your CA Machine."
echo "You may be prompted to enter password for $CAUSER@$CAIPADD"
read -p "Press [ENTER] to Continue..."
scp ~/$RSAFOLDER/pki/reqs/$CNSERVER.req ~/sign-cert.sh ~/OpenVPN/ca-install.sh $CAUSER@$CAIPADD:/home/$CAUSER/
echo ""
read -p "Proceed with CA-Machine Script, then press ENTER here when instructed..."
echo ""
echo "You are now going to SCP (download) files from your CA Machine."
echo "You may be prompted to enter password for $CAUSER@$CAIPADD"
read -p "Press [ENTER] to Continue..."
scp -T $CAUSER@$CAIPADD:"/home/$CAUSER/$RSAFOLDER/pki/issued/$CNSERVER.crt /home/$CAUSER/$RSAFOLDER/pki/ca.crt" /tmp
sudo cp /tmp/$CNSERVER.crt /etc/openvpn/
sudo cp /tmp/ca.crt /etc/openvpn/
cd ~/$RSAFOLDER/
echo ""
echo "The next step will take several minutes to finish."
read -p "Please be patient. Press [ENTER] to Continue..."
./easyrsa gen-dh
sudo openvpn --genkey --secret ta.key
sudo cp ~/$RSAFOLDER/ta.key /etc/openvpn/
sudo cp ~/$RSAFOLDER/pki/dh.pem /etc/openvpn/

#STEP4: Generate Key Directories
mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs
sudo cp ~/$RSAFOLDER/ta.key ~/client-configs/keys/
sudo cp /etc/openvpn/ca.crt ~/client-configs/keys/

#STEP5: Configure OpenVPN Service
#sudo cp ~/server.conf /etc/openvpn/server.conf
sudo sh -c 'echo "port" '$PORTN' > /etc/openvpn/server.conf'
sudo sh -c 'echo "proto" '$PROTO' >> /etc/openvpn/server.conf'
sudo sh -c 'echo "dev tun" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "ca ca.crt" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "cert" '$CNSERVER'".crt" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "key" '$CNSERVER'".key # This file should be kept secret" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "dh dh.pem" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "server 10.8.0.0 255.255.255.0" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "ifconfig-pool-persist /var/log/openvpn/ipp.txt" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "push \"redirect-gateway def1 bypass-dhcp\"" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "push \"dhcp-option DNS 208.67.222.222\"" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "push \"dhcp-option DNS 208.67.220.220\"" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "keepalive 10 120" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "tls-auth ta.key 0 # This file is secret" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "cipher AES-256-CBC" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "auth SHA256" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "user nobody" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "group nogroup" >> /etc/openvpn/server.conf'
if [ $PROTO = "udp" ]; then
    sudo sh -c 'echo "#tcp-nodelay" >> /etc/openvpn/server.conf'
else
    sudo sh -c 'echo "tcp-nodelay" >> /etc/openvpn/server.conf'
fi
sudo sh -c 'echo "persist-key" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "persist-tun" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "status /var/log/openvpn/openvpn-status.log" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "verb 0" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "log /dev/null" >> /etc/openvpn/server.conf'
sudo sh -c 'echo "status /dev/null" >> /etc/openvpn/server.conf'
if [ $PROTO = "udp" ]; then
    sudo sh -c 'echo "#explicit-exit-notify 0" >> /etc/openvpn/server.conf'
else
    sudo sh -c 'echo "explicit-exit-notify 0" >> /etc/openvpn/server.conf'
fi

#STEP6: Adjusting Server Network Configuration
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sed -i 's/# net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p
INTF=$(ip route | grep default | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}')
sudo sed -i '9a\\n# START OPENVPN RULES\n# NAT table rules\n*nat\n:POSTROUTING ACCEPT [0:0] \n-A POSTROUTING -s 10.8.0.0/8 -o '$INTF' -j MASQUERADE\nCOMMIT\n# END OPENVPN RULES\n' /etc/ufw/before.rules
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
sudo ufw allow OpenSSH
#PORTN=$(sudo cat /etc/openvpn/server.conf | awk '{ if($CNSERVER ~ "port") print $CAUSER }')    # deprecated
#PROTO=$(sudo cat /etc/openvpn/server.conf | awk '{ if($CNSERVER ~ "proto") print $CAUSER }')   # deprecated
sudo ufw allow $PORTN/$PROTO
sudo ufw disable
sudo ufw enable

#STEP7: Start & Enable OpenVPN Service
sudo systemctl start openvpn@server
sudo systemctl status openvpn@server
ip addr show tun0
sudo systemctl enable openvpn@server

#STEP8: Create Client Config Infrastructure
mkdir -p ~/client-configs/files
sh -c 'echo "client" > ~/client-configs/base.conf'
sh -c 'echo "dev tun" >> ~/client-configs/base.conf'
sh -c 'echo "proto" '$PROTO' >> ~/client-configs/base.conf'
sh -c 'echo "remote" '$SERVERIP' '$PORTN' >> ~/client-configs/base.conf'
sh -c 'echo "resolv-retry infinite" >> ~/client-configs/base.conf'
sh -c 'echo "nobind" >> ~/client-configs/base.conf'
sh -c 'echo "user nobody" >> ~/client-configs/base.conf'
sh -c 'echo "group nogroup" >> ~/client-configs/base.conf'
sh -c 'echo "persist-key" >> ~/client-configs/base.conf'
sh -c 'echo "persist-tun" >> ~/client-configs/base.conf'
sh -c 'echo "remote-cert-tls server" >> ~/client-configs/base.conf'
sh -c 'echo "key-direction 1" >> ~/client-configs/base.conf'
sh -c 'echo "#script-security 2" >> ~/client-configs/base.conf'
sh -c 'echo "#up /etc/openvpn/update-resolv-conf" >> ~/client-configs/base.conf'
sh -c 'echo "#down /etc/openvpn/update-resolv-conf" >> ~/client-configs/base.conf'
sh -c 'echo "cipher AES-256-CBC" >> ~/client-configs/base.conf'
sh -c 'echo "auth SHA256" >> ~/client-configs/base.conf'
sh -c 'echo "verb 3" >> ~/client-configs/base.conf'

#### Create make_config.sh File ####
sh -c 'echo "#!/bin/bash" > ~/client-configs/make_config.sh'
sh -c 'echo "" >> ~/client-configs/make_config.sh'
sh -c 'echo "# First argument: Client identifier" >> ~/client-configs/make_config.sh'
sh -c 'echo "" >> ~/client-configs/make_config.sh'
sh -c 'echo "KEY_DIR=/home/"'$(whoami)'"/client-configs/keys" >> ~/client-configs/make_config.sh'
sh -c 'echo "OUTPUT_DIR=/home/"'$(whoami)'"/client-configs/files" >> ~/client-configs/make_config.sh'
sh -c 'echo "BASE_CONFIG=/home/"'$(whoami)'"/client-configs/base.conf" >> ~/client-configs/make_config.sh'
sh -c 'echo "" >> ~/client-configs/make_config.sh'
sh -c 'echo "cat \${BASE_CONFIG} \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    <(echo -e '\''<ca>'\'') \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    \${KEY_DIR}/ca.crt \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    <(echo -e '\''</ca>\\n<cert>'\'') \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    \${KEY_DIR}/\${1}.crt \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    <(echo -e '\''</cert>\\n<key>'\'') \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    \${KEY_DIR}/\${1}.key \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    <(echo -e '\''</key>\\n<tls-auth>'\'') \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    \${KEY_DIR}/ta.key \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    <(echo -e '\''</tls-auth>'\'') \\" >> ~/client-configs/make_config.sh'
sh -c 'echo "    > \${OUTPUT_DIR}/\${1}.ovpn" >> ~/client-configs/make_config.sh'
chmod 700 ~/client-configs/make_config.sh
echo "You may now add client configuration files. Example: ./add-client.sh client1"
echo "add-client.sh can be found at your home directory."

#### Create ~/add-client.sh File ####
sh -c 'echo "#!/bin/bash" > ~/add-client.sh'
sh -c 'echo "cd ~/"'$RSAFOLDER'"/" >> ~/add-client.sh'
sh -c 'echo "./easyrsa gen-req \$1 nopass" >> ~/add-client.sh'
sh -c 'echo "cp pki/private/\$1.key ~/client-configs/keys/" >> ~/add-client.sh'
sh -c 'echo "scp pki/reqs/\$1.req "'$CAUSER'"@"'$CAIPADD'":/tmp" >> ~/add-client.sh'
sh -c 'echo "echo \"Switch to CA machine and run ./sign-cert.sh \$1\"" >> ~/add-client.sh'
sh -c 'echo "read -p \"Press [ENTER] here when instructed...\"" >> ~/add-client.sh'
sh -c 'echo "scp "'$CAUSER'"@"'$CAIPADD'":/home/"'$CAUSER'"/"'$RSAFOLDER'"/pki/issued/\$1.crt /tmp" >> ~/add-client.sh'
sh -c 'echo "cp /tmp/\$1.crt ~/client-configs/keys/" >> ~/add-client.sh'
sh -c 'echo "cd ~/client-configs" >> ~/add-client.sh'
sh -c 'echo "sudo ./make_config.sh \$1" >> ~/add-client.sh'
sh -c 'echo "echo \"\"" >> ~/add-client.sh'
sh -c 'echo "ls files" >> ~/add-client.sh'
sh -c 'echo "echo \"\"" >> ~/add-client.sh'
sh -c 'echo "echo \"You may now transfer /home/"'$(whoami)'"/client-configs/files/\$1.ovpn to your client device.\"" >> ~/add-client.sh'
chmod 700 ~/add-client.sh


