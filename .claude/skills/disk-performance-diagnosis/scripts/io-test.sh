#!/bin/bash

# I/O性能测试脚本
# 测试磁盘读写性能，包括顺序和随机I/O

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

echo "=== I/O性能测试 ==="
echo ""

# 检查是否安装了fio
if ! command -v fio &> /dev/null; then
    echo "错误：fio 未安装。请先安装fio工具。"
    echo "在Ubuntu/Debian上：sudo apt-get install fio"
    echo "在CentOS/RHEL上：sudo yum install fio"
    exit 1
fi

# 获取可用磁盘
disks=$(lsblk -n -o NAME,TYPE | grep disk | awk '{print $1}')

if [ -z "$disks" ]; then
    echo "未找到磁盘设备"
    exit 1
fi

echo "可用磁盘：$disks"
echo ""

# 让用户选择测试的磁盘
read -p "请输入要测试的磁盘设备（如sda, nvme0n1等）： " disk_device

# 检查磁盘是否存在
if ! lsblk -n -o NAME | grep -q "^$disk_device$"; then
    echo "错误：磁盘设备 $disk_device 不存在"
    exit 1
fi

# 测试配置
test_file="/tmp/${disk_device}_io_test.tmp"
test_size="1G"
block_sizes="4k 16k 64k 256k 1M"
io_modes="read write randread randwrite"

# 清理函数
cleanup() {
    rm -f "$test_file"
    echo "测试文件已清理"
}

# 捕获退出信号
trap cleanup EXIT

# 创建测试文件
echo "创建测试文件：$test_file，大小：$test_size"
fio --name=prepare --filename="$test_file" --size="$test_size" --bs=1M --rw=write --iodepth=1 --numjobs=1 --direct=1 --verify=0 --iodepth_batch=1 --iodepth_batch_submit=1 --iodepth_batch_complete=1 --runtime=1 --time_based --group_reporting

echo ""
echo "=== I/O性能测试开始 ==="
echo ""

# 执行测试
for bs in $block_sizes; do
    echo "=== 块大小: $bs ==="
    for mode in $io_modes; do
        echo "模式: $mode"
        fio --name=test --filename="$test_file" --size="$test_size" --bs="$bs" --rw="$mode" --iodepth=4 --numjobs=4 --direct=1 --verify=0 --iodepth_batch=1 --iodepth_batch_submit=1 --iodepth_batch_complete=1 --runtime=30 --time_based --group_reporting
        echo ""
    done
done

echo "=== I/O性能测试完成 ==="