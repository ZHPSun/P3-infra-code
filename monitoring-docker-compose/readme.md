使用方式

unzip full-monitoring-stack.zip
cd full-monitoring-stack
docker-compose up -d

✅ 一、Grafana 自动导入 Dashboard

🎯 目标：

部署时自动在 Grafana 中导入仪表盘，无需手动点击 UI。

🧩 方法：

通过配置 grafana/provisioning/dashboards 和 grafana/dashboards 目录实现。

📁 目录结构：

full-monitoring-stack/
├── docker-compose.yml
├── prometheus/
│ ├── prometheus.yml
│ └── alert.rules.yml
├── grafana/
│ ├── dashboards/
│ │ └── node_exporter.json
│ └── provisioning/
│ ├── dashboards/dashboards.yml
│ └── datasources/datasource.yml
└── alertmanager/
└── config.yml

📝 dashboards.yml 示例：

apiVersion: 1

providers:

- name: "default"
  orgId: 1
  folder: ""
  type: file
  updateIntervalSeconds: 10
  options:
  path: /etc/grafana/dashboards

📝 导入的 Dashboard JSON 示例：
• 从 Grafana.com Dashboards 下载，例如：
Node Exporter Full
• 把 JSON 文件放到 grafana/dashboards/ 目录中。

⸻

✅ 二、Prometheus 自动发现 EC2 实例

🎯 目标：

自动抓取 AWS EC2 实例的 Node Exporter 指标，而不是手写 IP 地址。

🔧 步骤： 1. IAM 权限配置：
给 EC2 实例或 Prometheus 所在机器一个带如下权限的 IAM Role：

{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": "ec2:DescribeInstances",
"Resource": "*"
}
]
}

    2.	修改 prometheus.yml 加入 AWS 服务发现：

scrape_configs:

- job_name: 'ec2'
  ec2_sd_configs:
  - region: us-east-1
    port: 9100
    relabel_configs:
  - source_labels: [__meta_ec2_private_ip]
    target_label: instance
  - source_labels: [__meta_ec2_public_ip]
    target_label: **address**
    replacement: '${1}:9100'

✅ 你可以根据 tag、VPC、security group 做更多过滤。

    3.	需要添加 EC2 Metadata 环境变量：

如果用 Docker 运行 Prometheus，要把 AWS 凭证以 env_file 或挂载方式注入容器。

⸻

✅ 三、Alertmanager 配置通知（Slack、邮件、钉钉等）

🎯 目标：

当服务器宕机、磁盘满时发送告警。

🧩 文件结构：

prometheus/
├── prometheus.yml
└── alert.rules.yml
alertmanager/
└── config.yml

📦 Prometheus 配置（prometheus.yml）中添加：

alerting:
alertmanagers: - static_configs: - targets: ["alertmanager:9093"]

rule_files:

- "alert.rules.yml"

📝 alert.rules.yml 示例：

groups:

- name: node_alerts
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 1m
    labels:
    severity: critical
    annotations:
    summary: "Instance {{ $labels.instance }} is down"

📝 Alertmanager config.yml 示例（Slack 通知）：

global:
slack_api_url: 'https://hooks.slack.com/services/XXX/YYY/ZZZ'

route:
receiver: 'slack-notifications'

receivers:

- name: 'slack-notifications'
  slack_configs:
  - channel: '#monitoring'
    text: '{{ .CommonAnnotations.summary }}'

⸻

✅ 总结功能 & 实现方式

功能 如何实现
Grafana 自动导入 Dashboard provisioning/dashboards/ + dashboards/\*.json
Prometheus EC2 自动发现 ec2_sd_configs + IAM 权限 + region/port 配置
Alertmanager 配置通知 alert.rules.yml + alertmanager/config.yml

⸻
