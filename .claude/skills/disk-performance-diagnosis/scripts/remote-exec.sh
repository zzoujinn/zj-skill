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
        echo "建议安装sshpass：sudo apt-get install sshpass 或 sudo yum install sshpass"
    fi
fi

# 执行远程命令
echo "连接到 $HOST..."
$SSH_CMD "$@"