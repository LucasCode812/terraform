#!/bin/bash


# Word root
sudo su
# Update systeempakketten
apt update

# Installeer Nagios
curl https://assets.nagios.com/downloads/nagiosxi/install.sh | sh

# Ga naar home
cd /home

# Maak een 'gelukt'-bestand aan
touch gelukt

# Voeg de agents toe aan de Nagios-server
echo "define host {
  use                 linux-server
  host_name           webserver-agent
  alias               Webserver Agent
  address             10.0.1.20
}

define service {
  use                 generic-service
  host_name           webserver-agent
  service_description Disk Space
  check_command       check_nrpe!check_disk
}

define service {
  use                 generic-service
  host_name           webserver-agent
  service_description Load Average
  check_command       check_nrpe!check_load
}

define service {
  use                 generic-service
  host_name           webserver-agent
  service_description Ping
  check_command       check_nrpe!check_ping
}

define service {
  use                 generic-service
  host_name           webserver-agent
  service_description SSH
  check_command       check_nrpe!check_ssh
}" >> /usr/local/nagios/etc/hosts/webserver.cfg

echo "define host {
  use                 linux-server
  host_name           wazuh-agent
  alias               Wazuh Agent
  address             10.0.2.10
}

define service {
  use                 generic-service
  host_name           wazuh-agent
  service_description Disk Space
  check_command       check_nrpe!check_disk
}

define service {
  use                 generic-service
  host_name           wazuh-agent
  service_description Load Average
  check_command       check_nrpe!check_load
}

define service {
  use                 generic-service
  host_name           wazuh-agent
  service_description Ping
  check_command       check_nrpe!check_ping
}

define service {
  use                 generic-service
  host_name           wazuh-agent
  service_description SSH
  check_command       check_nrpe!check_ssh
}" >> /usr/local/nagios/etc/hosts/wazuh.cfg

echo "define host {
  use                 linux-server
  host_name           snort-agent
  alias               Snort Agent
  address             10.0.1.10
}

define service {
  use                 generic-service
  host_name           snort-agent
  service_description Disk Space
  check_command       check_nrpe!check_disk
}

define service {
  use                 generic-service
  host_name           snort-agent
  service_description Load Average
  check_command       check_nrpe!check_load
}

define service {
  use                 generic-service
  host_name           snort-agent
  service_description Ping
  check_command       check_nrpe!check_ping
}

define service {
  use                 generic-service
  host_name           snort-agent
  service_description SSH
  check_command       check_nrpe!check_ssh
}" >> /usr/local/nagios/etc/hosts/snort.cfg

echo "define host {
  use                 windows-server
  host_name           ad-agent
  alias               ad Agent
  address             10.0.2.12
}" >> /usr/local/nagios/etc/hosts/ad.cfg


# Herstart de Nagios-service
systemctl restart nagios

# Ga naar home
cd /home

# Maak een 'allesgelukt'-bestand aan
touch allesgelukt

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

curl -so wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.4.3-1_amd64.deb && sudo WAZUH_MANAGER='10.0.2.10' WAZUH_AGENT_GROUP='default' WAZUH_AGENT_NAME='NagiosInstance' dpkg -i ./wazuh-agent.deb
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

echo "The installation was successful!" >> /var/log/logfile.txt