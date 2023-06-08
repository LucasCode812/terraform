#!/bin/bash

sudo su

apt update
apt dist-upgrade -y
apt install unattended-upgrades -y
dpkg-reconfigure --priority=low unattended-upgrades -y

password="StrongPassword"
echo -e "$password\n$password" | passwd root

config_file="/etc/ssh/sshd_config"
line14="Port 227"
sed -i "14s|.*|$line14|" "$config_file"
systemctl restart sshd

ufw allow 227
ufw enable

