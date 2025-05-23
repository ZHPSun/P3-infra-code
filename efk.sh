#!/bin/bash
set -xe

# 安装基础依赖
dnf update -y
dnf install -y java-11-amazon-corretto wget

# 安装 Elasticsearch
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.0-x86_64.rpm
rpm --install elasticsearch-7.17.0-x86_64.rpm

# 配置 Elasticsearch
cat <<EOT > /etc/elasticsearch/elasticsearch.yml
cluster.name: dev-cluster
node.name: node-1
network.host: 0.0.0.0
discovery.type: single-node
EOT

# JVM heap 设置为 1GB（适合 t3.medium）
echo "-Xms1g" > /etc/elasticsearch/jvm.options.d/heap.options
echo "-Xmx1g" >> /etc/elasticsearch/jvm.options.d/heap.options

# 修复日志和数据目录权限（关键）
mkdir -p /usr/share/elasticsearch/logs
mkdir -p /usr/share/elasticsearch/data
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/logs
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/data

# 启动 Elasticsearch
systemctl daemon-reexec
systemctl enable elasticsearch
systemctl start elasticsearch

# 安装 Kibana
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.17.0-x86_64.rpm
rpm --install kibana-7.17.0-x86_64.rpm

# 配置 Kibana
cat <<EOT > /etc/kibana/kibana.yml
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
EOT

# 启动 Kibana
systemctl enable kibana
systemctl start kibana