#!/bin/bash

# 磁盘信息收集脚本
# 收集服务器磁盘基本信息，包括分区、文件系统和挂载点

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

# 如果是远程模式
if [ "$REMOTE_MODE" = "1" ]; then
    # 调用远程执行脚本
    ./remote-exec.sh --remote --host="$HOST" --user="$USER" --password="$PASSWORD" --port="$PORT" --timeout="$TIMEOUT" "$0"
    exit $?
fi

echo "=== 磁盘信息收集 ==="
echo ""

# 磁盘分区信息
echo "1. 磁盘分区信息："
echo "----------------------------------------"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
echo ""

# 文件系统信息
echo "2. 文件系统信息："
echo "----------------------------------------"
df -hT
echo ""

# 挂载点详细信息
echo "3. 挂载点详细信息："
echo "----------------------------------------"
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS
echo ""

# 磁盘使用情况
echo "4. 磁盘使用情况（按百分比）："
echo "----------------------------------------"
df -h --output=source,fstype,size,used,avail,pcent,target | sort -k6 -h
echo ""

# 磁盘I/O统计
echo "5. 磁盘I/O统计（如果有iostat）："
echo "----------------------------------------"
if command -v iostat &> /dev/null; then
    iostat -dx 1 3
else
    echo "iostat 未安装，跳过I/O统计"
fi
echo ""

# 磁盘健康状态（如果有smartctl）
echo "6. 磁盘健康状态："
echo "----------------------------------------"
if command -v smartctl &> /dev/null; then
    for disk in $(lsblk -n -o NAME | grep -E '^[a-z]+$'); do
        echo "磁盘 $disk:"
        smartctl -H /dev/$disk
        echo ""
    done
else
    echo "smartctl 未安装，跳过健康状态检查"
fi

echo "=== 磁盘信息收集完成 ==="