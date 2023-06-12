#!/bin/bash -xe
  
sudo su
  
apt-get install apt-transport-https zip unzip lsb-release curl gnupg -y
  
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/elasticsearch.gpg --import && chmod 644 /usr/share/keyrings/elasticsearch.gpg
  
echo "deb [signed-by=/usr/share/keyrings/elasticsearch.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
  
apt-get update
  
apt-get install elasticsearch=7.17.9
  
curl -so /etc/elasticsearch/elasticsearch.yml https://packages.wazuh.com/4.4/tpl/elastic-basic/elasticsearch_all_in_one.yml
  
curl -so /usr/share/elasticsearch/instances.yml https://packages.wazuh.com/4.4/tpl/elastic-basic/instances_aio.yml
  
/usr/share/elasticsearch/bin/elasticsearch-certutil cert ca --pem --in instances.yml --keep-ca-key --out ~/certs.zip
  
unzip ~/certs.zip -d ~/certs

mkdir /etc/elasticsearch/certs/ca -p
cp -R ~/certs/ca/ ~/certs/elasticsearch/* /etc/elasticsearch/certs/
chown -R elasticsearch: /etc/elasticsearch/certs
chmod -R 500 /etc/elasticsearch/certs
chmod 400 /etc/elasticsearch/certs/ca/ca.* /etc/elasticsearch/certs/elasticsearch.*
rm -rf ~/certs/ ~/certs.zip

systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch

/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive -b << EOF
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
Welkom123
EOF
  
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update

apt-get install wazuh-manager

systemctl daemon-reload
systemctl enable wazuh-manager
systemctl start wazuh-manager

systemctl status wazuh-manager

apt-get install filebeat=7.17.9
curl -so /etc/filebeat/filebeat.yml https://packages.wazuh.com/4.4/tpl/elastic-basic/filebeat_all_in_one.yml

curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/4.4/extensions/elasticsearch/7.x/wazuh-template.json
chmod go+r /etc/filebeat/wazuh-template.json

curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.2.tar.gz | tar -xvz -C /usr/share/filebeat/module

sed -i 's/output.elasticsearch.password: <elasticsearch_password>/output.elasticsearch.password: Welkom123/' /etc/filebeat/filebeat.yml

cp -r /etc/elasticsearch/certs/ca/ /etc/filebeat/certs/
cp /etc/elasticsearch/certs/elasticsearch.crt /etc/filebeat/certs/filebeat.crt
cp /etc/elasticsearch/certs/elasticsearch.key /etc/filebeat/certs/filebeat.key

systemctl daemon-reload
systemctl enable filebeat
systemctl start filebeat
  
apt-get install kibana=7.17.9

mkdir /etc/kibana/certs/ca -p
cp -R /etc/elasticsearch/certs/ca/ /etc/kibana/certs/
cp /etc/elasticsearch/certs/elasticsearch.key /etc/kibana/certs/kibana.key
cp /etc/elasticsearch/certs/elasticsearch.crt /etc/kibana/certs/kibana.crt
chown -R kibana:kibana /etc/kibana/
chmod -R 500 /etc/kibana/certs
chmod 440 /etc/kibana/certs/ca/ca.* /etc/kibana/certs/kibana.*
  
curl -so /etc/kibana/kibana.yml https://packages.wazuh.com/4.4/tpl/elastic-basic/kibana_all_in_one.yml

sed -i 's/elasticsearch.password: <elasticsearch_password>/elasticsearch.password: Welkom123/' /etc/kibana/kibana.yml

mkdir /usr/share/kibana/data
chown -R kibana:kibana /usr/share/kibana
  
cd /usr/share/kibana
sudo -u kibana /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/4.x/ui/kibana/wazuh_kibana-4.4.3_7.17.9-1.zip
  
setcap 'cap_net_bind_service=+ep' /usr/share/kibana/node/bin/node

systemctl daemon-reload
systemctl enable kibana
systemctl start kibana

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