#!/bin/bash

# Update the system packages
sudo apt update

# Upgrade the system packages
sudo apt update

# Install Nginx
sudo apt install -y nginx

# Start Nginx service
sudo systemctl start nginx

# Enable Nginx to start on system boot
sudo systemctl enable nginx

# install openssl
sudo apt install openssl

# generate private key 
sudo openssl genpkey -algorithm RSA -out /etc/ssl/private/nginx-selfsigned.key

# generate public key 
openssl req -new -key /etc/ssl/private/nginx-selfsigned.key -x509 -days 365 -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/CN=localhost"

# Configure Nginx.conf
echo '
      server {
        listen 80 default_server;
        listen [::]:80 default_server;

        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
        server_name localhost;

        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
      }
          
    ' | sudo tee /etc/nginx/sites-available/default

# Restart Nginx
sudo systemctl restart nginx

# NagiosAgent
# Become sudo
sudo su

# Update system
apt update

# Install NRPE
apt install -y nagios-nrpe-server nagios-plugins

# Configure NRPE connection with NagiosXI
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

# Restart NRPE-service
systemctl restart nagios-nrpe-server

# WazuhAgent
IP_ADDRESS="10.0.2.10"
PORT="1514"

# Start install when Wazuh-Manager is on
function check_port() {
    nc -zv "$IP_ADDRESS" "$PORT" >/dev/null 2>&1
    return $?
}

while ! check_port; do
    echo "Pinging $IP_ADDRESS on port $PORT..." >> /var/log/logfile.txt
    sleep 1
done

echo "The ping to $IP_ADDRESS on port $PORT!" >> /var/log/logfile.txt

# Install Wazuh agent
curl -so wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.4.3-1_amd64.deb && sudo WAZUH_MANAGER='10.0.2.10' WAZUH_AGENT_GROUP='default' WAZUH_AGENT_NAME='WebserverInstance' dpkg -i ./wazuh-agent.deb
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

echo "The installation was successful!" >> /var/log/logfile.txt
