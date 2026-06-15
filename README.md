# ELK-Host-Based-Intrusion-Detection-System
**Host-Based Intrusion Detection System using the ELK Stack and Suricata** integrates Suricata, Filebeat, Logstash, Elasticsearch, and Kibana to monitor network traffic, process security logs, and visualize threats in real time. It detects suspicious activities such as ICMP, SSH brute-force, and Nmap scans through custom rules.


---

## Features

* Real-time network traffic monitoring
* Custom Suricata detection rules
* Automated log collection using Filebeat
* Log processing and enrichment with Logstash
* Secure storage and indexing using Elasticsearch
* Interactive dashboards and visualizations in Kibana
* Detection of common reconnaissance and attack techniques
* End-to-end security event pipeline

---

## Technology Stack

* **Operating System:** Kali Linux
* **Intrusion Detection:** Suricata
* **Log Shipper:** Filebeat
* **Data Processing:** Logstash
* **Search Engine:** Elasticsearch
* **Visualization:** Kibana
* **Testing Environment:** Windows Virtual Machine (VirtualBox)

---

## Architecture

```
                Network Traffic
                       │
                       ▼
                ┌─────────────┐
                │  Suricata   │
                │ IDS Engine  │
                └──────┬──────┘
                       │
                 eve.json logs
                       │
                       ▼
                ┌─────────────┐
                │  Filebeat   │
                └──────┬──────┘
                       │
                       ▼
                ┌─────────────┐
                │  Logstash   │
                └──────┬──────┘
                       │
                       ▼
                ┌─────────────┐
                │Elasticsearch│
                └──────┬──────┘
                       │
                       ▼
                ┌─────────────┐
                │   Kibana    │
                │ Dashboards  │
                └─────────────┘
```

---

## Project Workflow

1. Suricata monitors network traffic on the host interface.
2. Security events are stored in `eve.json`.
3. Filebeat continuously watches the log file.
4. Filebeat forwards logs to Logstash.
5. Logstash parses and enriches the events.
6. Elasticsearch indexes the processed data.
7. Kibana visualizes alerts through dashboards and charts.

---

## Installation

### Install Elasticsearch

```bash
sudo dpkg -i elasticsearch-<version>.deb
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

### Install Logstash

```bash
sudo dpkg -i logstash-<version>.deb
sudo systemctl enable logstash
sudo systemctl start logstash
```

### Install Kibana

```bash
sudo dpkg -i kibana-<version>.deb
sudo systemctl enable kibana
sudo systemctl start kibana
```

### Install Filebeat

```bash
sudo dpkg -i filebeat-<version>.deb
sudo systemctl enable filebeat
sudo systemctl start filebeat
```

### Install Suricata

```bash
sudo apt install suricata
sudo systemctl enable suricata
sudo systemctl start suricata
```

---

## Configuration

* Configure Elasticsearch network settings.
* Configure Kibana connection and SSL certificates.
* Create a Logstash pipeline.
* Configure Suricata monitoring interface.
* Add custom detection rules.
* Configure Filebeat to monitor `eve.json`.
* Connect Filebeat to Logstash.
* Create Kibana data views and dashboards.

---

## Detection Rules

The project includes custom rules for:

* ICMP Ping Detection
* SSH Brute Force Attempts
* Nmap SYN Scan
* Nmap FIN Scan
* Nmap Xmas Scan

Each rule uses a unique SID and generates alerts whenever matching traffic is detected.

---

## Testing

A Windows virtual machine was used to generate attack traffic including:

* Continuous ICMP ping requests
* SSH connection attempts
* Nmap reconnaissance scans

Suricata successfully detected these activities and generated alerts that were processed through the ELK pipeline and displayed in Kibana.

---

## Dashboard

Kibana dashboards provide:

* Alert count over time
* Event filtering
* Security event exploration
* Visualization of intrusion attempts
* Timeline analysis

---

## Results

The integrated pipeline successfully:

* Captured live network traffic
* Processed thousands of log entries
* Indexed events in Elasticsearch
* Displayed alerts in Kibana dashboards
* Detected custom attack signatures in real time

The implementation demonstrates an effective open-source security monitoring solution suitable for learning and small-scale deployments.

---

## Future Improvements

* Integrate Elastic Security SIEM
* Add Email or Slack notifications
* Deploy Suricata in IPS mode
* Add threat intelligence feeds
* Implement machine learning-based anomaly detection
* Monitor multiple hosts simultaneously

---

## Conclusion

This project demonstrates the successful implementation of a Host-Based Intrusion Detection System using Suricata and the ELK Stack. By combining packet inspection, centralized log management, and interactive visualization, the system provides real-time visibility into network activity and helps identify potential security threats. It highlights the practical integration of open-source cybersecurity tools to build an effective monitoring and incident analysis platform.

---
Disclaimer:

This project was conducted strictly in a legal and controlled lab environment for educational purposes only.
t

## Author

**Senha Fathima**
cybersecurity student

Cybersecurity Project – Host-Based Intrusion Detection System Using the ELK Stack and Suricata
