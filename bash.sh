#!/bin/bash

# install SNORT
sudo su

apt update
apt upgrade -y

apt install build-essential libpcap-dev libpcre3-dev \
libnet1-dev zlib1g-dev luajit hwloc libdnet-dev \
libdumbnet-dev bison flex liblzma-dev openssl libssl-dev \
pkg-config libhwloc-dev cmake cpputest libsqlite3-dev uuid-dev \
libcmocka-dev libnetfilter-queue-dev libmnl-dev autotools-dev \
libluajit-5.1-dev libunwind-dev libfl-dev -y

mkdir /home/ubuntu/snort-source-files && cd /home/ubuntu/snort-source-files/

git clone https://github.com/snort3/libdaq.git
cd /home/ubuntu/snort-source-files/libdaq
./bootstrap
./configure
make
make install

cd /home/ubuntu/snort-source-files/
wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.9.1/gperftools-2.9.1.tar.gz
tar xzf gperftools-2.9.1.tar.gz
cd /home/ubuntu/snort-source-files/gperftools-2.9.1/
./configure
make
make install

cd /home/ubuntu/snort-source-files/
wget https://github.com/snort3/snort3/archive/refs/tags/3.1.28.0.tar.gz
tar xzf 3.1.28.0.tar.gz
cd /home/ubuntu/snort-source-files/snort3-3.1.28.0
./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc

cd /home/ubuntu/snort-source-files/snort3-3.1.28.0/build
make
make install
ldconfig

# Configure SNORT
ip link set dev eth0 promisc on
ip add sh eth0
ethtool -k eth0 | grep receive-offload
ethtool -K eth0 gro off lro off

cat > /etc/systemd/system/snort3-nic.service << 'EOL'
[Unit]
Description=Set Snort 3 NIC in promiscuous mode and Disable GRO, LRO on boot
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ip link set dev eth0 promisc on
ExecStart=/usr/sbin/ethtool -K eth0 gro off lro off
TimeoutStartSec=0
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOL

systemctl daemon-reload
systemctl enable --now snort3-nic.service

# Install SNORT Rules
mkdir /usr/local/etc/rules
wget -qO- \
https://www.snort.org/downloads/community/snort3-community-rules.tar.gz \
| tar xz -C /usr/local/etc/rules/

# Configuration file path
config_file="/usr/local/etc/snort/snort.lua"

# Lines to add
line24="HOME_NET = '10.0.1.0/24'"
line28="EXTERNAL_NET = '!\$HOME_NET'"
line192=","
line193="    rules = [[\n    include \$RULE_PATH/snort3-community-rules/snort3-community.rules\n    ]]"
line196="}"

# Remove existing lines and insert new lines at specific line numbers
sed -i "24s|.*|$line24|" "$config_file"
sed -i "28s|.*|$line28|" "$config_file"
sed -i "192s|.*|&,|" "$config_file"
sed -i "193s|.*|$line193|" "$config_file"
sed -i "196i$line196" "$config_file"

mkdir /var/log/snort

cd /home/ubuntu/snort-source-files/
touch klaar