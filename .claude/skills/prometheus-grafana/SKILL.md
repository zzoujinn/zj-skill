---
name: prometheus-grafana
description: Prometheus + Grafana 监控告警配置工具。帮助编写 PromQL 查询、配置告警规则、设计 Grafana 仪表盘、配置 Alertmanager 通知。当用户需要：(1) 编写 PromQL 查询表达式，(2) 配置 Prometheus 告警规则，(3) 设计 Grafana 仪表盘和面板，(4) 配置 Alertmanager 告警路由和通知，(5) 规划监控指标体系，(6) 排查监控告警问题时使用。触发条件："prometheus"、"grafana"、"监控配置"、"告警规则"、"promql"、"仪表盘"、"alertmanager"、"监控指标"。
---

# Prometheus + Grafana 监控告警

## 监控设计方法论

### 四大黄金指标（Google SRE）

| 指标 | 含义 | PromQL 示例 |
|------|------|------------|
| 延迟 | 请求耗时 | `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))` |
| 流量 | 请求速率 | `sum(rate(http_requests_total[5m]))` |
| 错误 | 错误比率 | `sum(rate(http_requests_total{code=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))` |
| 饱和度 | 资源使用率 | `1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))` |

### USE 方法（基础设施）

- **Utilization**（使用率）：资源忙碌的时间比例
- **Saturation**（饱和度）：排队或等待的工作量
- **Errors**（错误）：错误事件数

### RED 方法（微服务）

- **Rate**（速率）：每秒请求数
- **Errors**（错误）：每秒失败请求数
- **Duration**（耗时）：请求耗时分布

## PromQL 常用查询

### CPU

```promql
# CPU 使用率（按实例）
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 各模式 CPU 占比
avg by(mode) (rate(node_cpu_seconds_total[5m])) * 100

# CPU 使用率 Top 5 主机
topk(5, 100 - avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### 内存

```promql
# 内存使用率
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# 可用内存（GB）
node_memory_MemAvailable_bytes / 1024^3
```

### 磁盘

```promql
# 磁盘使用率
(1 - node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100

# 磁盘空间预测（4小时后耗尽的分区）
predict_linear(node_filesystem_avail_bytes{fstype!="tmpfs"}[6h], 4*3600) < 0

# 磁盘 I/O 使用率
rate(node_disk_io_time_seconds_total[5m]) * 100
```

### 网络

```promql
# 网络流入速率（MB/s）
rate(node_network_receive_bytes_total{device!="lo"}[5m]) / 1024^2

# 网络流出速率（MB/s）
rate(node_network_transmit_bytes_total{device!="lo"}[5m]) / 1024^2

# TCP 连接数
node_netstat_Tcp_CurrEstab
```

### HTTP 服务

```promql
# QPS
sum(rate(http_requests_total[5m]))

# 错误率
sum(rate(http_requests_total{code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# P99 延迟
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# P95 延迟
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

### 容器（cAdvisor）

```promql
# 容器 CPU 使用率
sum(rate(container_cpu_usage_seconds_total{container!="POD",container!=""}[5m])) by (namespace, pod) * 100

# 容器内存使用率
container_memory_working_set_bytes{container!="POD",container!=""} / container_spec_memory_limit_bytes * 100

# 容器重启次数
increase(kube_pod_container_status_restarts_total[1h])
```

## 告警规则配置

### 规则文件格式

```yaml
groups:
  - name: 主机告警
    rules:
      - alert: 主机CPU使用率过高
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "主机 {{ $labels.instance }} CPU 使用率过高"
          description: "CPU 使用率 {{ $value | printf \"%.1f\" }}%，持续超过 85% 达 5 分钟"

      - alert: 主机内存使用率过高
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "主机 {{ $labels.instance }} 内存使用率过高"
          description: "内存使用率 {{ $value | printf \"%.1f\" }}%，超过 90%"

      - alert: 磁盘空间不足
        expr: (1 - node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "主机 {{ $labels.instance }} 磁盘空间不足"
          description: "挂载点 {{ $labels.mountpoint }} 使用率 {{ $value | printf \"%.1f\" }}%"

      - alert: 磁盘空间即将耗尽
        expr: predict_linear(node_filesystem_avail_bytes{fstype!="tmpfs"}[6h], 24*3600) < 0
        for: 30m
        labels:
          severity: critical
        annotations:
          summary: "主机 {{ $labels.instance }} 磁盘空间预计 24 小时内耗尽"
          description: "挂载点 {{ $labels.mountpoint }}，按当前趋势将在 24 小时内用完"

      - alert: 主机宕机
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "主机 {{ $labels.instance }} 不可达"
          description: "主机已离线超过 1 分钟"

  - name: 应用告警
    rules:
      - alert: HTTP错误率过高
        expr: sum(rate(http_requests_total{code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100 > 5
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "HTTP 5xx 错误率过高"
          description: "错误率 {{ $value | printf \"%.2f\" }}%，超过 5%"

      - alert: 请求延迟过高
        expr: histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "P99 请求延迟超过 2 秒"
          description: "P99 延迟 {{ $value | printf \"%.2f\" }} 秒"

  - name: 容器告警
    rules:
      - alert: Pod频繁重启
        expr: increase(kube_pod_container_status_restarts_total[1h]) > 3
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} 频繁重启"
          description: "过去 1 小时重启 {{ $value }} 次"

      - alert: PodOOMKilled
        expr: kube_pod_container_status_last_terminated_reason{reason="OOMKilled"} == 1
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} OOM Killed"
```

### 告警级别规范

| 级别 | 含义 | for 时间 | 通知方式 |
|------|------|---------|---------|
| critical | 需要立即处理 | 1-3m | 电话 + 即时消息 |
| warning | 需要关注 | 5-15m | 即时消息 |
| info | 信息通知 | 15-30m | 邮件 |

## Alertmanager 配置

```yaml
global:
  resolve_timeout: 5m

route:
  receiver: default
  group_by: ['alertname', 'instance']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: critical-channel
      repeat_interval: 1h
    - match:
        severity: warning
      receiver: warning-channel
      repeat_interval: 4h

receivers:
  - name: default
    webhook_configs:
      - url: 'http://alertmanager-webhook:8080/alert'

  - name: critical-channel
    webhook_configs:
      - url: 'http://alertmanager-webhook:8080/alert/critical'

  - name: warning-channel
    webhook_configs:
      - url: 'http://alertmanager-webhook:8080/alert/warning'

inhibit_rules:
  - source_match:
      severity: critical
    target_match:
      severity: warning
    equal: ['alertname', 'instance']
```

## Grafana 仪表盘设计

### 面板类型选择

| 面板类型 | 适用场景 |
|---------|---------|
| Stat | 单一数值（当前 CPU、在线主机数） |
| Gauge | 百分比指标（使用率、完成度） |
| Time series | 时间序列趋势（QPS、延迟） |
| Table | 多维数据展示（Top N 列表） |
| Heatmap | 分布数据（延迟分布） |
| Bar chart | 对比数据（各服务错误数） |

### 仪表盘布局原则

1. **概览在上**：顶部放 Stat 面板展示关键指标（总QPS、错误率、在线数）
2. **趋势在中**：中间放 Time series 面板展示趋势
3. **详情在下**：底部放 Table 面板展示详细数据
4. **使用变量**：添加数据源、实例、命名空间等下拉变量方便筛选
5. **时间范围**：默认显示最近 1 小时，支持自定义

### 变量配置示例

```
# 数据源变量
类型: Data source
名称: datasource

# 实例变量
类型: Query
名称: instance
查询: label_values(up, instance)

# 命名空间变量
类型: Query
名称: namespace
查询: label_values(kube_pod_info, namespace)
```

## 告警排查

```bash
# 查看 Prometheus 告警状态
curl -s http://prometheus:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state}'

# 查看 Alertmanager 活跃告警
curl -s http://alertmanager:9093/api/v2/alerts | jq '.[] | {alertname: .labels.alertname, status: .status.state}'

# 验证 PromQL 表达式
curl -s 'http://prometheus:9090/api/v1/query?query=up' | jq

# 检查告警规则加载状态
curl -s http://prometheus:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.type=="alerting") | {name: .name, state: .state}'

# 重新加载 Prometheus 配置
curl -X POST http://prometheus:9090/-/reload
```
