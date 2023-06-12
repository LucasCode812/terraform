#!/bin/bash

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
allowed_hosts=127.0.0.1,10.0.2.21

# ...
EOF

# Herstart de NRPE-service
systemctl restart nagios-nrpe-server

# Ga naar home
cd /home

# Maak een 'gelukt'-bestand aan
touch gelukt
