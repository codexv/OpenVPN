#!/bin/bash
cd EasyRSA-3.0.7
./easyrsa import-req /tmp/$1.req $1
./easyrsa sign-req client $1
echo "You may now press ENTER on the other machine."
