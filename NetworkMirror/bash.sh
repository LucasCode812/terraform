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
ip link set dev ens3 promisc on
ip add sh ens3
ethtool -k ens3 | grep receive-offload
ethtool -K ens3 gro off lro off

cat > /etc/systemd/system/snort3-nic.service << 'EOL'
[Unit]
Description=Set Snort 3 NIC in promiscuous mode and Disable GRO, LRO on boot
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ip link set dev ens3 promisc on
ExecStart=/usr/sbin/ethtool -K ens4 gro off lro off
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
line195="    include \$RULE_PATH/local.rules"
line197="}"

# Remove existing lines and insert new lines at specific line numbers
sed -i "24s|.*|$line24|" "$config_file"
sed -i "28s|.*|$line28|" "$config_file"
sed -i "192s|.*|&,|" "$config_file"
sed -i "193s|.*|$line193|" "$config_file"
sed -i "195i$line195" "$config_file"
sed -i "197i$line197" "$config_file"

mkdir /var/log/snort
mkdir /usr/local/etc/rules/local.rules
cat > /etc/systemd/system/snort3-nic.service << 'EOL'
alert icmp any any -> $HOME_NET any (msg:"ICMP connection test"; sid:1000001; rev:1;)
EOL

config_file="/usr/local/etc/snort/snort.lua"
line254="alert_fast = { file = true, packet = false, limit = 10 }"
sed -i "254s|.*|$line254|" "$config_file"

useradd -r -s /usr/sbin/nologin -M -c SNORT_IDS snort
cat > /etc/systemd/system/snort3.service << EOL
[Unit]
Description=Snort Daemon
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/snort -c /usr/local/etc/snort/snort.lua -s 65535 -k none -l /var/log/snort -D -i ens3 -m 0x1b -u snort -g snort
ExecStop=/bin/kill -9 \$MAINPID

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
chmod -R 5775 /var/log/snort
chown -R snort:snort /var/log/snort
systemctl enable --now snort3

cd /home/ubuntu/snort-source-files/
touch klaar