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

sudo cat > /usr/share/nginx/html/index.html <<EOF
<html>
<head>
  <style>
    h1 {
      color: #5e9ca0;
      text-align: center;
    }
    h2 {
      color: #2e6c80;
      text-align: center;
    }
    p {
      text-align: center;
    }
  </style>
</head>
<body>
  <p><strong><img src="https://www.google.nl/url?sa=i&amp;url=https%3A%2F%2Fwww.possible.today%2Fprototype-sociaal-cv%2Ffontys-logo-svg%2F&amp;psig=AOvVaw1m6do9nB4Qceu0uvf-MG2d&amp;ust=1686519045171000&amp;source=images&amp;cd=vfe&amp;ved=0CBEQjRxqFwoTCNCN0ZfTuf8CFQAAAAAdAAAAABAJ" alt="" /></strong></p>
  <h1><span style="color: #666699;"><strong>Jouw business website hier!</strong></span></h1>
  <p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://t3.ftcdn.net/jpg/03/82/64/52/360_F_382645277_6VUaiZuHXtB4OiivCWVQ1DIxqPbu9xv5.jpg" alt="" width="326" height="217" /></p>
  <h2><span style="color: #808080;"><em>Wat is dit?:</em></span></h2>
  <p><em>Deze page dient als demo en is onderdeel van Project 'Turnkey Infrastructuur in de Cloud'.</em></p>
  <p>&nbsp;</p>
  <p><img style="display: block; margin-left: auto; margin-right: auto;" src="https://www.possible.today/wp-content/uploads/2021/12/Fontys-Logo.svg.png" alt="" width="150" height="76" /></p>
</body>
</html>
EOF

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
