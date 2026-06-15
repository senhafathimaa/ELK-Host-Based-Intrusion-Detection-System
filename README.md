# Host-Based Intrusion Detection System Using ELK Stack and Suricata

> A fully functional HIDS built on Kali Linux using Suricata for network detection and the ELK Stack for log processing and visualization.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tools & Technologies](#tools--technologies)
- [Data Flow](#data-flow)
- [Installation](#installation)
- [Configuration](#configuration)
- [Detection Rules](#detection-rules)
- [Dashboard Setup](#dashboard-setup)
- [Results](#results)
- [Challenges & Solutions](#challenges--solutions)
- [Conclusion](#conclusion)

---

## Overview

This project implements a Host-Based Intrusion Detection System (HIDS) by integrating **Suricata** with the **ELK Stack** (Elasticsearch, Logstash, Kibana) on a Kali Linux host. The system captures live network traffic, processes it through a log pipeline, and visualizes real-time security alerts on a Kibana dashboard.

A **Windows virtual machine** (running in VirtualBox on the same LAN) was used to simulate attacks including ICMP pings, Nmap scans, and SSH brute-force attempts directed at the Kali host.

---

## Architecture
┌─────────────────────────────────────────────────────────────────┐

│                    Kali Linux Host (192.168.0.105)              │

│                                                                 │

│  ┌───────────┐    ┌──────────┐    ┌──────────┐    ┌─────────┐  │

│  │ Suricata  │───▶│ Filebeat │───▶│ Logstash │───▶│ Elastic │  │

│  │ (IDS/NSM) │    │  (Ship)  │    │ (Process)│    │ search  │  │

│  └───────────┘    └──────────┘    └──────────┘    └────┬────┘  │

│       ▲                                                 │       │

│       │                                            ┌────▼────┐  │

│  wlan0 interface                                   │  Kibana │  │

│                                                    │  :5061  │  │

└─────────────────────────────────────────────────── └─────────┘  │

▲

│  Same LAN (192.168.0.0/24)

┌────────┴──────────┐

│  Windows VM       │

│  (VirtualBox)     │

│  192.168.0.107    │

│  • Pings          │

│  • Nmap scans     │

│  • SSH attempts   │

└───────────────────┘
---

## Tools & Technologies

| Tool | Version | Role |
|---|---|---|
| Kali Linux | Bare metal | Host OS |
| Suricata | 8.0.5 | Network IDS / NSM |
| Elasticsearch | 9.x | Data store & search engine |
| Logstash | 9.x | Log processing pipeline |
| Kibana | 9.x | Visualization & dashboards |
| Filebeat | 9.x | Log shipper |
| VirtualBox | — | Windows VM host |
| Windows VM | — | Attack traffic source |

---

## Data Flow
Suricata (eve.json)

│

▼

Filebeat  ──────▶  Logstash (:5044)  ──────▶  Elasticsearch (:9200)

│

▼

Kibana (:5061)
1. Suricata monitors `wlan0` and writes structured JSON events to `/var/log/suricata/eve.json`
2. Filebeat tails `eve.json` and ships logs to Logstash on port `5044`
3. Logstash parses and enriches the events, then forwards them to Elasticsearch
4. Elasticsearch indexes the data under the `suricata-YYYY.MM.dd` index pattern
5. Kibana queries Elasticsearch and renders the data as interactive dashboards

---

## Installation

### 1. Elasticsearch
```bash
dpkg -i elasticsearch-*.deb
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

### 2. Logstash
```bash
dpkg -i logstash-*.deb
sudo systemctl enable logstash
sudo systemctl start logstash
```

### 3. Kibana
```bash
dpkg -i kibana-*.deb
sudo systemctl enable kibana
sudo systemctl start kibana
```

### 4. Filebeat
```bash
dpkg -i filebeat-*.deb
sudo systemctl enable filebeat
sudo systemctl start filebeat
```

### 5. Suricata
```bash
sudo apt install suricata -y
sudo systemctl enable suricata
sudo systemctl start suricata
```

> **Note:** Always restart a service after editing its configuration file.
> ```bash
> sudo systemctl restart <service-name>
> ```

---

## Configuration

### Elasticsearch (`/etc/elasticsearch/elasticsearch.yml`)

```yaml
network.host: "0.0.0.0"
http.port: 9200
transport.host: "0.0.0.0"
```

Reset the elastic user password:
```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
```

Fix permission errors if they occur:
```bash
sudo chown -R elasticsearch:elasticsearch /etc/elasticsearch
sudo chmod -R 750 /etc/elasticsearch
```

Verify Elasticsearch is running:
```bash
curl -k -u elastic:<password> https://localhost:9200
```

---

### Kibana (`/etc/kibana/kibana.yml`)

```yaml
server.port: 5061
server.host: "0.0.0.0"
elasticsearch.hosts: ["https://localhost:9200"]
elasticsearch.password: "<your-elastic-password>"
elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/ca.crt"]
elasticsearch.ssl.verificationMode: full
```

Copy the Elasticsearch CA certificate:
```bash
sudo cp /etc/elasticsearch/certs/http_ca.crt /etc/kibana/ca.crt
```

Generate encryption keys and add to `kibana.yml`:
```bash
sudo /usr/share/kibana/bin/kibana-encryption-keys generate
```

Generate a service account token (alternative to password):
```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-service-tokens create elastic/kibana kibana-token
```

---

### Logstash (`/etc/logstash/conf.d/pipeline.conf`)

```ruby
input {
  beats {
    port => 5044
  }
}

filter {
  if [message] =~ /^\{.*\}$/ {
    json {
      source => "message"
      target => "suricata"
    }
  }
}

output {
  elasticsearch {
    hosts => ["https://localhost:9200"]
    user => "elastic"
    password => "<your-elastic-password>"
    index => "suricata-%{+YYYY.MM.dd}"
    ssl_enabled => true
    ssl_certificate_authorities => ["/etc/logstash/certs/http_ca.crt"]
    ilm_enabled => false
  }
}
```

Copy CA cert and fix permissions:
```bash
sudo mkdir -p /etc/logstash/certs
sudo cp /etc/elasticsearch/certs/http_ca.crt /etc/logstash/certs/
sudo chown logstash:logstash /etc/logstash/certs/http_ca.crt
sudo chmod 644 /etc/logstash/certs/http_ca.crt
sudo chown -R logstash:logstash /var/lib/logstash /var/log/logstash
```

Verify Logstash is listening:
```bash
sudo ss -tulnp | grep 5044
```

---

### Suricata (`/etc/suricata/suricata.yaml`)

```yaml
af-packet:
  - interface: wlan0

- eve-log:
    enabled: yes
    filetype: regular
    filename: /var/log/suricata/eve.json

default-rule-path: /var/lib/suricata/rules
rule-files:
  - local.rules
```

Validate configuration:
```bash
sudo suricata -T -c /etc/suricata/suricata.yaml -v
```

---

### Filebeat (`/etc/filebeat/filebeat.yml`)

```yaml
filebeat.inputs:
  - type: filestream
    id: my-filestream-id
    enabled: true
    paths:
      - /var/log/suricata/eve.json
      - /var/log/auth.log

output.logstash:
  hosts: ["localhost:5044"]
```

Fix permissions and test:
```bash
sudo chmod 644 /var/log/suricata/eve.json
sudo chmod 644 /var/log/auth.log
sudo filebeat test output
```

---

## Detection Rules

File: `/etc/suricata/rules/local.rules`
alert icmp any any -> any any (msg:"ICMP Ping Detected"; itype:8; sid:1000001; rev:1;)

alert tcp any any -> any 22 (msg:"SSH Brute-Force Attempt"; flow:to_server,established; content:"SSH-"; threshold:type threshold, track by_src, count:5, seconds:60; sid:1000002; rev:1;)

alert tcp any any -> any any (msg:"Nmap SYN Scan Detected"; flags:S; threshold:type threshold, track by_src, count:20, seconds:10; sid:1000003; rev:1;)

alert tcp any any -> any any (msg:"Nmap NULL Scan Detected"; flags:0; sid:1000004; rev:1;)

alert tcp any any -> any any (msg:"Nmap Xmas Scan Detected"; flags:FPU; sid:1000005; rev:1;)
> **Important:** Every rule must have a unique `sid`.

Copy rules to Suricata's rule path:
```bash
sudo cp /etc/suricata/rules/local.rules /var/lib/suricata/rules/
```

---

## Dashboard Setup

1. Go to **Stack Management → Data Views → Create data view**
   - Index pattern: `suricata-*`
   - Timestamp field: `@timestamp`

2. Go to **Analytics → Discover**, select `suricata-*` — over 1,600 documents should appear

3. Filter for alerts: `suricata.event_type: alert`

4. Go to **Analytics → Visualize Library → Create visualization → Lens**

| Setting | Value |
|---|---|
| Data view | `suricata-*` |
| Filter | `suricata.event_type: alert` |
| Chart type | Bar |
| Horizontal axis | `@timestamp` |
| Vertical axis | Count of records |

5. Save as **"Alert Types Breakdown"** and add to dashboard

---

## Results

- **82 alert events** confirmed in Kibana Discover during testing
- All **5 custom Suricata rules** loaded and triggered successfully
- Dashboard showed clear **spikes in alert activity** during test periods
- Highest spike: **20+ alerts** on June 8th during active ICMP ping testing

---

## Challenges & Solutions

| Challenge | Solution |
|---|---|
| Kibana rejected the elastic superuser account | Used a service account token via `elasticsearch-service-tokens` |
| Elasticsearch file permission errors | Ran `sudo chown -R elasticsearch:elasticsearch /etc/elasticsearch` |
| Logstash permission issues | Fixed ownership on `/var/lib/logstash` and always ran via systemd |
| Suricata rule path mismatch | Copied rules from `/etc/suricata/rules/` to `/var/lib/suricata/rules/` |
| Filebeat failed to start | Replaced deprecated `log` input type with `filestream` (Filebeat 9) |
| Kibana couldn't connect to Elasticsearch over HTTPS | Copied `http_ca.crt` and set `ssl.certificateAuthorities` in kibana.yml |

---
##Project Structure
/

│── README.md
│── project.pdf
│── commands.sh

## Conclusion

This project successfully demonstrates how open-source tools can be integrated to build a working real-time intrusion detection and visualization system from scratch. Suricata monitored live host traffic, detected simulated attacks from a Windows VM, and the full ELK pipeline transported, stored, and visualized the resulting alerts.

While Suricata is primarily a Network IDS/IPS, deploying it on a host's own interface makes it effective for host-level monitoring. In a production environment, deploying it on a network gateway or SPAN port would scale this to an entire network.

---

## Author

**Senha Fathima**

---

## License

This project is for educational and research purposes.
