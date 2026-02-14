---
name: log-analysis
description: 日志分析与故障排查工具。帮助分析应用日志、系统日志、中间件日志，定位错误根因，提取关键信息，统计错误频率和趋势。当用户需要：(1) 分析应用或系统日志文件，(2) 定位错误或异常的根因，(3) 提取和过滤关键日志信息，(4) 统计错误频率和趋势，(5) 分析慢查询或性能日志，(6) 关联多个日志源排查问题时使用。触发条件："日志分析"、"log analysis"、"错误排查"、"日志过滤"、"慢查询分析"、"分析日志"、"查看日志"。
---

# 日志分析

## 分析流程

1. 确认日志类型和格式（应用日志/系统日志/中间件日志）
2. 确定分析目标（错误定位/性能分析/安全审计/趋势统计）
3. 选择分析方法和工具
4. 执行分析并输出结论

## 常用日志路径

| 日志类型 | 常见路径 |
|---------|---------|
| 系统日志 | `/var/log/syslog`, `/var/log/messages` |
| 认证日志 | `/var/log/auth.log`, `/var/log/secure` |
| 内核日志 | `/var/log/kern.log`, `dmesg` |
| Nginx | `/var/log/nginx/access.log`, `/var/log/nginx/error.log` |
| MySQL | `/var/log/mysql/error.log`, 慢查询日志看配置 |
| Docker | `docker logs <容器>`, `/var/lib/docker/containers/` |
| K8s | `kubectl logs`, `/var/log/pods/` |
| 应用日志 | 根据部署路径确定，常见 `/opt/app/logs/` |

## 分析工具速查

### 基础过滤

```bash
# 按关键词过滤
grep -i "error\|exception\|fatal" app.log

# 按时间范围过滤（假设日志格式含时间戳）
awk '/2024-01-15 10:00/,/2024-01-15 11:00/' app.log

# 排除干扰信息
grep -v "HealthCheck\|heartbeat" app.log | grep -i error

# 查看错误前后上下文（前5行后10行）
grep -B5 -A10 "OutOfMemoryError" app.log
```

### 统计分析

```bash
# 错误频率统计（按小时）
grep -i error app.log | awk '{print $1" "$2}' | cut -d: -f1 | sort | uniq -c | sort -rn

# HTTP 状态码分布
awk '{print $9}' access.log | sort | uniq -c | sort -rn

# Top 10 慢请求
awk '$NF > 1.0 {print $7, $NF}' access.log | sort -k2 -rn | head -10

# Top IP 访问量
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -20
```

### JSON 日志分析

```bash
# 使用 jq 过滤 JSON 日志
cat app.log | jq -r 'select(.level == "ERROR") | [.timestamp, .message] | @tsv'

# 统计错误类型
cat app.log | jq -r 'select(.level == "ERROR") | .error_type' | sort | uniq -c | sort -rn
```

## 常见问题排查模式

### OOM 排查

```bash
# 检查系统 OOM killer 日志
dmesg | grep -i "out of memory\|oom"
grep -i "oom\|out of memory" /var/log/syslog

# Java 应用 OOM
grep -A5 "OutOfMemoryError" app.log
# 检查 GC 日志
grep "Full GC" gc.log | tail -20
```

### 服务不可用排查

```bash
# 检查服务端口
ss -tlnp | grep <端口>
# 检查连接数
ss -s
# 检查最近重启
journalctl -u <服务名> --since "1 hour ago" | grep -i "start\|stop\|fail"
```

### 请求链路追踪

```bash
# 按 traceId/requestId 关联日志
grep "trace_id=abc123" *.log
# 跨多个日志文件追踪
find /var/log/app/ -name "*.log" -exec grep -l "abc123" {} \;
```

## Nginx 访问日志分析

```bash
# QPS 统计（按秒）
awk '{print $4}' access.log | cut -d: -f1-3 | uniq -c | sort -rn | head

# 响应时间分布
awk '{print $NF}' access.log | awk '{
  if($1<0.1) a++;
  else if($1<0.5) b++;
  else if($1<1) c++;
  else d++
} END {print "<100ms:",a, "<500ms:",b, "<1s:",c, ">1s:",d}'

# 4xx/5xx 错误 URL 排行
awk '$9 >= 400 {print $9, $7}' access.log | sort | uniq -c | sort -rn | head -20
```

## MySQL 慢查询分析

```bash
# 使用 mysqldumpslow 分析
mysqldumpslow -s t -t 10 slow-query.log

# 手动分析
grep -A2 "^# Time:" slow-query.log | grep "Query_time" | awk '{print $3}' | sort -rn | head
```

## 输出规范

分析结果按以下格式输出：

1. **问题摘要**：一句话描述发现的问题
2. **关键证据**：支持结论的日志片段（标注时间和来源）
3. **根因分析**：问题产生的原因
4. **影响范围**：受影响的时间段、服务、用户量
5. **建议措施**：具体的修复或优化建议
