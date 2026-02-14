---
name: k8s-troubleshooting
description: Kubernetes 故障排查与诊断工具。帮助排查 Pod 异常、节点问题、网络故障、资源不足等 K8s 集群问题，审查 YAML 配置，提供修复建议。当用户需要：(1) 排查 Pod CrashLoopBackOff/Pending/OOMKilled 等异常状态，(2) 诊断节点 NotReady 或资源不足，(3) 排查 Service/Ingress 网络不通，(4) 审查 K8s YAML 配置文件，(5) 分析集群事件和资源使用，(6) 排查存储卷挂载问题时使用。触发条件："k8s"、"kubernetes"、"pod异常"、"容器排查"、"kubectl"、"集群故障"、"pod排查"、"节点问题"。
---

# Kubernetes 故障排查

## 排查流程

1. 确认问题现象（Pod 状态/服务不通/性能异常）
2. 收集信息（事件、日志、资源状态）
3. 定位根因
4. 提供修复方案

## Pod 异常状态排查

### CrashLoopBackOff

```bash
# 查看 Pod 事件
kubectl describe pod <pod> -n <ns>
# 查看当前日志
kubectl logs <pod> -n <ns>
# 查看上一次崩溃日志
kubectl logs <pod> -n <ns> --previous
# 查看所有容器日志（多容器 Pod）
kubectl logs <pod> -n <ns> --all-containers
```

常见原因：
- 应用启动失败（配置错误、依赖服务不可用）
- OOM 被 kill（检查 resources.limits.memory）
- 健康检查失败（livenessProbe 配置不当）
- 镜像入口命令错误

### Pending

```bash
# 查看调度事件
kubectl describe pod <pod> -n <ns> | grep -A10 Events
# 检查节点资源
kubectl describe nodes | grep -A5 "Allocated resources"
kubectl top nodes
```

常见原因：
- 资源不足（CPU/内存请求超出可用量）
- 节点选择器/亲和性不匹配
- PVC 未绑定
- 污点未容忍

### ImagePullBackOff

```bash
# 查看拉取错误详情
kubectl describe pod <pod> -n <ns> | grep -A5 "Events"
# 检查 imagePullSecrets
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.imagePullSecrets}'
# 验证镜像是否存在
docker pull <image>
```

### OOMKilled

```bash
# 确认 OOM
kubectl describe pod <pod> -n <ns> | grep -i oom
# 查看实际内存使用
kubectl top pod <pod> -n <ns>
# 查看 limits 设置
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.containers[*].resources}'
```

修复方向：增大 memory limits、排查内存泄漏、优化应用内存使用。

## 节点排查

```bash
# 节点状态
kubectl get nodes -o wide
# 节点详情和 Conditions
kubectl describe node <node>
# 节点资源使用
kubectl top node <node>
# 节点上的 Pod
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node>
# 系统组件状态
kubectl get componentstatuses
```

### 节点 NotReady 常见原因

- kubelet 进程异常 → `systemctl status kubelet`
- 磁盘压力 → 检查 DiskPressure condition
- 内存压力 → 检查 MemoryPressure condition
- 网络插件异常 → 检查 CNI Pod 状态
- 证书过期 → 检查 kubelet 日志

## 网络排查

### Service 不通

```bash
# 检查 Service 和 Endpoints
kubectl get svc <svc> -n <ns>
kubectl get endpoints <svc> -n <ns>
# 检查 Pod 标签是否匹配 Service selector
kubectl get pods -n <ns> -l <selector-key>=<selector-value>
# DNS 解析测试
kubectl run tmp-dns --rm -it --image=busybox -- nslookup <svc>.<ns>.svc.cluster.local
# 连通性测试
kubectl run tmp-curl --rm -it --image=curlimages/curl -- curl -v <svc>.<ns>:<port>
```

### Ingress 不通

```bash
# 检查 Ingress 配置
kubectl get ingress <name> -n <ns> -o yaml
# 检查 Ingress Controller 日志
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
# 检查后端 Service 是否正常
kubectl get endpoints <backend-svc> -n <ns>
```

## 存储排查

```bash
# PVC 状态
kubectl get pvc -n <ns>
# PV 状态
kubectl get pv
# 查看绑定关系
kubectl describe pvc <pvc> -n <ns>
# StorageClass
kubectl get sc
```

PVC Pending 常见原因：无可用 PV、StorageClass 不存在、容量不满足。

## 资源分析

```bash
# 集群资源总览
kubectl top nodes
kubectl top pods -A --sort-by=memory | head -20

# 查看资源配额
kubectl get resourcequota -n <ns>
kubectl describe resourcequota -n <ns>

# 查看 LimitRange
kubectl get limitrange -n <ns>

# HPA 状态
kubectl get hpa -n <ns>
kubectl describe hpa <name> -n <ns>
```

## 常用诊断命令速查

```bash
# 集群事件（按时间排序）
kubectl get events -A --sort-by='.lastTimestamp' | tail -30

# 查找非 Running 的 Pod
kubectl get pods -A --field-selector 'status.phase!=Running' | grep -v Completed

# 查看 Pod 的完整 YAML（含默认值）
kubectl get pod <pod> -n <ns> -o yaml

# 进入容器调试
kubectl exec -it <pod> -n <ns> -- /bin/sh

# 临时调试容器（K8s 1.23+）
kubectl debug <pod> -n <ns> -it --image=busybox

# 端口转发调试
kubectl port-forward pod/<pod> -n <ns> <local-port>:<pod-port>
```

## YAML 配置审查要点

审查 K8s YAML 时关注：

1. **资源配置**：是否设置 requests 和 limits，值是否合理
2. **健康检查**：是否配置 livenessProbe 和 readinessProbe
3. **安全上下文**：是否使用非 root、是否限制权限
4. **镜像标签**：避免使用 latest，使用固定版本
5. **副本数**：生产环境至少 2 个副本
6. **反亲和性**：关键服务是否配置 Pod 反亲和以分散部署
7. **优雅终止**：terminationGracePeriodSeconds 是否合理
8. **ConfigMap/Secret**：敏感信息是否使用 Secret
