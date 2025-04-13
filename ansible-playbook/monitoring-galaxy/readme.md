ansible-galaxy install \
 cloudalchemy.prometheus \
 cloudalchemy.node_exporter \
 cloudalchemy.grafana

structure

monitoring-stack/
├── hosts.ini
├── prometheus_stack.yml
├── group_vars/
│ └── all.yml

ansible-playbook -i inventory.ini prometheus-grafana-nodexporter.yml
