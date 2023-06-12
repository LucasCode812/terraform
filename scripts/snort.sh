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

## NagiosAgent
sudo su

# Update systeempakketten
apt update

# Installeer NRPE
apt install -y nagios-nrpe-server nagios-plugins

# Configureer NRPE om verbinding te maken met de Nagios-server
cat << EOF > /etc/nagios/nrpe.cfg
# Sample NRPE Configuration File - nrpe.cfg

# ...

# Command definitions
command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 80% -c 90%
command[check_load]=/usr/lib/nagios/plugins/check_load -w 5,4,3 -c 10,6,4
command[check_ping]=/usr/lib/nagios/plugins/check_ping -H localhost -w 100.0,20% -c 200.0,40%
command[check_ssh]=/usr/lib/nagios/plugins/check_ssh -H localhost

# ...

# Allowed hosts
allowed_hosts=127.0.0.1,10.0.2.11

# ...
EOF

# Herstart de NRPE-service
systemctl restart nagios-nrpe-server

# Ga naar home
cd /home

# Maak een 'gelukt'-bestand aan
touch gelukt

## WazuhAgent
IP_ADDRESS="10.0.2.10"
PORT="1514"

function check_port() {
    nc -zv "$IP_ADDRESS" "$PORT" >/dev/null 2>&1
    return $?
}

while ! check_port; do
    echo "Pinging $IP_ADDRESS on port $PORT..." >> /var/log/logfile.txt
    sleep 1
done

echo "The ping to $IP_ADDRESS on port $PORT!" >> /var/log/logfile.txt

curl -so wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.4.3-1_amd64.deb && sudo WAZUH_MANAGER='10.0.2.10' WAZUH_AGENT_GROUP='default' WAZUH_AGENT_NAME='SnortInstance' dpkg -i ./wazuh-agent.deb
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

echo "The installation was successful!" >> /var/log/logfile.txt