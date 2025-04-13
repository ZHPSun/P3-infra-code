monitoring-stack/
├── inventory.ini
├── playbook.yml
├── roles/
│ ├── common/
│ │ ├── tasks/
│ │ │ └── main.yml
│ ├── prometheus/
│ │ ├── tasks/
│ │ │ └── main.yml
│ ├── node_exporter/
│ │ ├── tasks/
│ │ │ └── main.yml
│ └── grafana/
│ ├── tasks/
│ │ └── main.yml

ansible-playbook -i inventory.ini playbook.yml

use T3 medium 4G and 20G gp3

Final Access URLs
• Prometheus: http://<ec2-ip>:9090
• Node Exporter: http://<ec2-ip>:9100/metrics
• Grafana: http://<ec2-ip>:3000 (default user/pass: admin/admin)
