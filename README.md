# OpenVPN

Pre-requisites:
1. A Linux Server/VPS for OpenVPN.
    (Preferrably Debian 9, or 10)
2. A Linux Server/VPS for your Certificate Authority (CA).
    (Preferrably Debian 9, or 10)
3. A non-root user for both your Server and CA machines.
3. VPS Server must have ssh access to your CA's non-root user. 
    Prepare ssh key access if necessary.


Installation:

1. Login to your VPS Server then run the following commands:

```bash
sudo apt update && sudo apt install git
```
```bash
git clone https://github.com/codexv/OpenVPN.git ~/OpenVPN
```

2. Check server-install.sh and ca-install.sh if they have the updated URL to EasyRSA:

```bash
nano ~/OpenVPN/server-install.sh
```
```bash
nano ~/OpenVPN/ca-install.sh
```

Edit the RSAURL field for both files if necessary.
You may also edit the parameters for ca-install.sh to match your own information.

3. Run the installer script for your VPN Server:

```bash
./OpenVPN/server-install.sh
```

Answer the prompts accordingly.


4. You will have to switch to your CA machine and vice versa when advised by the script.

When asked to proceed with the CA machine script, just log in to your CA machine and run:

```bash
./ca-install.sh
```

Answer the prompts accordingly.




