#!/bin/bash

# 磁盘使用情况分析脚本
# 分析磁盘空间使用情况，识别大文件和占用空间较多的目录

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

echo "=== 磁盘使用情况分析 ==="
echo ""

# 检查是否安装了必要的工具
for tool in du find sort; do
    if ! command -v $tool &> /dev/null; then
        echo "错误：$tool 未安装。请先安装该工具。"
        exit 1
    fi
done

# 获取所有挂载点
mount_points=$(findmnt -n -o TARGET | grep -v '^/$' | sort)

if [ -z "$mount_points" ]; then
    echo "未找到非根挂载点"
    exit 1
fi

echo "发现的挂载点："
echo "$mount_points"
echo ""

# 让用户选择要分析的挂载点
read -p "请输入要分析的挂载点（如/home, /var等）： " target_mount

# 检查挂载点是否存在
if ! echo "$mount_points" | grep -q "^$target_mount$"; then
    echo "错误：挂载点 $target_mount 不存在"
    exit 1
fi

# 检查挂载点是否可访问
if [ ! -d "$target_mount" ]; then
    echo "错误：挂载点 $target_mount 不可访问"
    exit 1
fi

echo "分析挂载点：$target_mount"
echo ""

# 1. 挂载点总体使用情况
echo "1. 挂载点总体使用情况："
echo "----------------------------------------"
df -h "$target_mount"
echo ""

# 2. 按目录排序的空间使用（前20个）
echo "2. 按目录排序的空间使用（前20个）："
echo "----------------------------------------"
du -sh "$target_mount"/* 2>/dev/null | sort -hr | head -n 20
echo ""

# 3. 查找大文件（大于100M）
echo "3. 大文件（大于100M）："
echo "----------------------------------------"
find "$target_mount" -type f -size +100M -exec du -h {} + 2>/dev/null | sort -hr | head -n 20
echo ""

# 4. 查找最旧的文件（前20个）
echo "4. 最旧的文件（前20个）："
echo "----------------------------------------"
find "$target_mount" -type f -printf '%T+ %p\n' 2>/dev/null | sort | head -n 20
echo ""

# 5. 查找最近修改的文件（前20个）
echo "5. 最近修改的文件（前20个）："
echo "----------------------------------------"
find "$target_mount" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 20 | awk '{print $2}'
echo ""

# 6. 空闲空间分析
echo "6. 空闲空间分析："
echo "----------------------------------------"
df -h "$target_mount"
echo ""

# 7. inode使用情况
echo "7. inode使用情况："
echo "----------------------------------------"
df -i "$target_mount"
echo ""

echo "=== 磁盘使用情况分析完成 ==="