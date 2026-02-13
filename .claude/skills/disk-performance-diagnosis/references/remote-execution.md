# 远程执行指南

## 远程执行概述

本skill支持通过SSH连接远程服务器执行磁盘性能诊断。远程执行功能允许您在不直接登录目标服务器的情况下，执行诊断脚本并获取结果。

## 远程执行配置

### 基本语法
```bash
# 远程执行磁盘信息收集
./disk-info.sh --remote --host=目标IP --user=用户名 --password=密码

# 远程执行I/O测试
./io-test.sh --remote --host=目标IP --user=用户名 --password=密码

# 远程执行磁盘使用分析
./disk-usage.sh --remote --host=目标IP --user=用户名 --password=密码
```

### 参数说明
- `--remote`: 启用远程执行模式
- `--host`: 目标服务器IP地址或主机名
- `--user`: SSH用户名
- `--password`: SSH密码（可选，推荐使用密钥认证）
- `--port`: SSH端口（默认22）
- `--timeout`: 连接超时（默认30秒）
- `--key`: SSH私钥文件路径（替代密码认证）

## 安全最佳实践

### 1. 认证方式选择
- **SSH密钥认证**（推荐）:
  ```bash
  ./disk-info.sh --remote --host=192.168.1.100 --user=admin --key=~/.ssh/id_rsa
  ```

- **密码认证**:
  ```bash
  ./disk-info.sh --remote --host=192.168.1.100 --user=admin --password=yourpassword
  ```

### 2. 密码安全
- 密码在内存中临时存储，执行后立即清除
- 避免在命令行中直接输入密码，可使用环境变量
- 考虑使用SSH配置文件中的别名

### 3. 网络安全
- 确保SSH连接使用加密
- 限制SSH访问的IP范围
- 定期更新SSH密钥

## 远程执行脚本

### 远程执行核心脚本
```bash
#!/bin/bash

# 远程执行核心脚本
# 处理远程SSH连接和命令执行

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --remote) REMOTE_MODE=1 ;;
        --host=*) HOST="${1#*=}" ;;
        --user=*) USER="${1#*=}" ;;
        --password=*) PASSWORD="${1#*=}" ;;
        --port=*) PORT="${1#*=}" ;;
        --timeout=*) TIMEOUT="${1#*=}" ;;
        --key=*) KEY="${1#*=}" ;;
        *) shift ;;
    esac
    shift
done

# 验证必需参数
if [ -z "$HOST" ] || [ -z "$USER" ]; then
    echo "错误：必须提供主机和用户名"
    exit 1
fi

# 设置默认值
PORT=${PORT:-22}
TIMEOUT=${TIMEOUT:-30}

# 构建SSH命令
SSH_CMD="ssh"
SSH_CMD+=" -o ConnectTimeout=$TIMEOUT"
SSH_CMD+=" -p $PORT"
SSH_CMD+=" $USER@$HOST"

# 如果提供了密钥
if [ -n "$KEY" ]; then
    SSH_CMD+=" -i $KEY"
fi

# 如果提供了密码
if [ -n "$PASSWORD" ]; then
    # 使用SSHpass处理密码（需要安装）
    if command -v sshpass &> /dev/null; then
        SSH_CMD="sshpass -p '$PASSWORD' $SSH_CMD"
    else
        echo "警告：sshpass未安装，密码认证可能失败"
    fi
fi

# 执行远程命令
echo "连接到 $HOST..."
$SSH_CMD "$@"
```

### 脚本集成示例
```bash
#!/bin/bash

# 集成远程执行的disk-info.sh示例

# 解析远程参数
REMOTE_MODE=0
HOST=""
USER=""
PASSWORD=""
PORT=22
TIMEOUT=30

while [[ $# -gt 0 ]]; do
    case $1 in
        --remote) REMOTE_MODE=1 ;;
        --host=*) HOST="${1#*=}" ;;
        --user=*) USER="${1#*=}" ;;
        --password=*) PASSWORD="${1#*=}" ;;
        --port=*) PORT="${1#*=}" ;;
        --timeout=*) TIMEOUT="${1#*=}" ;;
        *) shift ;;
    esac
    shift
done

# 如果是远程模式
if [ $REMOTE_MODE -eq 1 ]; then
    # 调用远程执行核心脚本
    ./remote-exec.sh --remote --host="$HOST" --user="$USER" --password="$PASSWORD" --port="$PORT" --timeout="$TIMEOUT" "$0" "$@"
    exit $?
fi

# 本地执行逻辑...
```

## 故障排除

### 常见问题

1. **连接超时**
   - 检查网络连接
   - 增加超时时间：`--timeout=60`
   - 确认SSH服务运行

2. **认证失败**
   - 验证用户名和密码
   - 检查SSH密钥权限
   - 确认目标服务器允许SSH访问

3. **权限不足**
   - 确保有足够的sudo权限
   - 检查目标用户的sudo配置
   - 考虑使用sudo命令

4. **脚本执行失败**
   - 确认目标服务器有相同的工具
   - 检查脚本依赖
   - 验证路径正确性

### 调试技巧

- 使用-v参数查看详细输出
- 测试基本的SSH连接
- 逐步执行命令验证每一步
- 检查目标服务器的日志

## 高级用法

### 使用SSH配置文件
```bash
# 在~/.ssh/config中配置
Host myserver
    HostName 192.168.1.100
    User admin
    Port 22
    IdentityFile ~/.ssh/id_rsa

# 使用配置的别名
./disk-info.sh --remote --host=myserver
```

### 批量执行
```bash
# 对多个服务器执行
for host in server1 server2 server3; do
    ./disk-info.sh --remote --host=$host --user=admin
done
```

### 结果收集
```bash
# 收集结果到文件
./disk-info.sh --remote --host=192.168.1.100 > results_$HOST.txt
```

## 性能考虑

### 网络影响
- 远程执行可能受网络延迟影响
- 大文件传输可能较慢
- 考虑本地执行性能测试

### 资源限制
- 目标服务器的负载情况
- 网络带宽限制
- SSH连接数限制

## 安全建议

1. **最小权限原则**: 使用专用诊断用户
2. **定期轮换凭证**: 定期更新密码和密钥
3. **网络隔离**: 在受控网络环境中执行
4. **审计日志**: 记录所有远程执行操作
5. **应急计划**: 准备连接失败的处理方案

通过遵循这些指南，您可以安全有效地使用远程执行功能进行磁盘性能诊断。