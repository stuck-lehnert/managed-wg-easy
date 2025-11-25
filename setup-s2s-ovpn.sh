#!/usr/bin/env bash

set -e

echo "apt-get update"
sudo apt-get update &> /dev/null
echo "apt-get install -y openvpn"
sudo apt-get install -y openvpn &> /dev/null
echo

echo -n "What is the current path of your .ovpn config? "
read OVPN_CONF_PATH
echo
if [[ -z "$OVPN_CONF_PATH" || ! -f "$OVPN_CONF_PATH" ]]; then exit 1; fi


echo -n "What is your username for this connection? "
read USERNAME
echo
if [[ -z "$USERNAME" ]]; then exit 1; fi

echo -n "What is the password for this connection? "
read -s PASSWORD
echo
if [[ -z "$PASSWORD" ]]; then exit 1; fi

sudo mkdir -p /etc/s2s-ovpn
echo "$USERNAME" > /etc/openvpn/s2s-auth.txt
echo "$PASSWORD" >> /etc/openvpn/s2s-auth.txt

cp "$OVPN_CONF_PATH" /etc/openvpn/s2s-config.opvn
sed -i '/auth-user-pass/d' /etc/openvpn/s2s-config.ovpn
echo >> /etc/openvpn/s2s-config.ovpn
echo "auth-user-pass /etc/openvpn/s2s-auth.txt" >> /etc/openvpn/s2s-config.ovpn

systemctl enable openvpn@s2s-config --now


