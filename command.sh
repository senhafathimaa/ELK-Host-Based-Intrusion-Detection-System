#!/bin/bash
# ============================================================
# HIDS Setup Commands - ELK Stack + Suricata on Kali Linux
# Author: Senha Fathima
# ============================================================

# ─────────────────────────────────────────
# 1. INSTALLATION
# ─────────────────────────────────────────

# Elasticsearch
dpkg -i elasticsearch-*.deb
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
sudo systemctl status elasticsearch

# Logstash
dpkg -i logstash-*.deb
sudo systemctl enable logstash
sudo systemctl start logstash
sudo systemctl status logstash

# Kibana
dpkg -i kibana-*.deb
sudo systemctl enable kibana
sudo systemctl start kibana
sudo systemctl status kibana

# Filebeat
dpkg -i filebeat-*.deb
sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl status filebeat

# Suricata
sudo apt install suricata -y
sudo systemctl enable suricata
sudo systemctl start suricata
sudo systemctl status suricata


# ─────────────────────────────────────────
# 2. CONFIGURE ELASTICSEARCH
# ─────────────────────────────────────────

sudo nano /etc/elasticsearch/elasticsearch.yml
# Uncomment and set:
#   network.host: "0.0.0.0"
#   http.port: 9200
#   transport.host: "0.0.0.0"

sudo systemctl restart elasticsearch

# Reset elastic user password
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic

# Fix permission errors if they occur
sudo chown -R elasticsearch:elasticsearch /etc/elasticsearch
sudo chmod -R 750 /etc/elasticsearch
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic

# Verify Elasticsearch is running
curl -k -u elastic:<your-password> https://localhost:9200


# ─────────────────────────────────────────
# 3. CONFIGURE KIBANA
# ─────────────────────────────────────────

sudo nano /etc/kibana/kibana.yml
# Set:
#   server.port: 5061
#   server.host: "0.0.0.0"
#   elasticsearch.hosts: ["https://localhost:9200"]
#   elasticsearch.password: "<your-elastic-password>"
#   elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/ca.crt"]
#   elasticsearch.ssl.verificationMode: full

# Generate encryption keys and paste into kibana.yml
sudo /usr/share/kibana/bin/kibana-encryption-keys generate

# Copy Elasticsearch CA cert to Kibana
sudo cp /etc/elasticsearch/certs/http_ca.crt /etc/kibana/ca.crt

# Optional: generate service account token instead of username/password
sudo /usr/share/elasticsearch/bin/elasticsearch-service-tokens create elastic/kibana kibana-token

sudo systemctl restart kibana

# Access Kibana at: http://localhost:5061


# ─────────────────────────────────────────
# 4. CONFIGURE LOGSTASH
# ─────────────────────────────────────────

sudo nano /etc/logstash/conf.d/pipeline.conf
# Paste the pipeline (input → beats:5044, filter → json, output → elasticsearch)

# Copy Elasticsearch CA cert to Logstash
sudo mkdir -p /etc/logstash/certs
sudo cp /etc/elasticsearch/certs/http_ca.crt /etc/logstash/certs/
sudo chown logstash:logstash /etc/logstash/certs/http_ca.crt
sudo chmod 644 /etc/logstash/certs/http_ca.crt

# Fix Logstash directory permissions
sudo chown -R logstash:logstash /var/lib/logstash
sudo chown -R logstash:logstash /var/log/logstash

sudo systemctl enable logstash
sudo systemctl start logstash
sudo systemctl status logstash

# Confirm Logstash is listening on port 5044
sudo ss -tulnp | grep 5044


# ─────────────────────────────────────────
# 5. CONFIGURE SURICATA
# ─────────────────────────────────────────

sudo nano /etc/suricata/suricata.yaml
# Set:
#   af-packet:
#     - interface: wlan0
#
#   eve-log:
#     enabled: yes
#     filename: /var/log/suricata/eve.json
#
#   default-rule-path: /var/lib/suricata/rules
#   rule-files:
#     - local.rules

# Create custom rules file
sudo nano /etc/suricata/rules/local.rules
# Add rules (see Detection Rules section in README)

# Copy rules to Suricata's default rule path
sudo cp /etc/suricata/rules/local.rules /var/lib/suricata/rules/

# Test Suricata config and rules
sudo suricata -T -c /etc/suricata/suricata.yaml -v

sudo systemctl restart suricata

# Watch eve.json live
sudo tail -f /var/log/suricata/eve.json

# Check fast.log for triggered alerts
sudo cat /var/log/suricata/fast.log


# ─────────────────────────────────────────
# 6. CONFIGURE FILEBEAT
# ─────────────────────────────────────────

sudo nano /etc/filebeat/filebeat.yml
# Set filebeat.inputs to type: filestream
# Add paths:
#   - /var/log/suricata/eve.json
#   - /var/log/auth.log
# Comment out output.elasticsearch
# Uncomment output.logstash with hosts: ["localhost:5044"]

# Fix log file permissions so Filebeat can read them
sudo chmod 644 /var/log/suricata/eve.json
sudo chmod 644 /var/log/auth.log

# Test connection to Logstash
sudo filebeat test output

sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl status filebeat


# ─────────────────────────────────────────
# 7. TEST DETECTION (from Windows VM)
# ─────────────────────────────────────────

# Run these from the Windows VM (192.168.0.107) targeting Kali (192.168.0.105):
# ping 192.168.0.105 -n 20
# nmap -sS 192.168.0.105
# nmap -sN 192.168.0.105
# nmap -sX 192.168.0.105
# ssh user@192.168.0.105  (repeated attempts to trigger brute-force rule)

# On Kali, verify alerts fired:
sudo cat /var/log/suricata/fast.log


# ─────────────────────────────────────────
# 8. SERVICE MANAGEMENT (quick reference)
# ─────────────────────────────────────────

# Restart all services after config changes
sudo systemctl restart elasticsearch
sudo systemctl restart kibana
sudo systemctl restart logstash
sudo systemctl restart filebeat
sudo systemctl restart suricata

# Check status of all services
sudo systemctl status elasticsearch kibana logstash filebeat suricata
