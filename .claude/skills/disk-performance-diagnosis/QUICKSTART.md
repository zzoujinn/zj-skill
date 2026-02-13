# 快速开始指南

本指南帮助您快速上手使用磁盘性能诊断工具。

## Windows用户快速开始

### 1. 设置PowerShell执行策略（首次使用）

```powershell
# 以管理员身份运行PowerShell，执行以下命令
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. 本地磁盘诊断

```powershell
# 进入脚本目录
cd C:\Users\zoujin\gitfile\zj-skill\.claude\skills\disk-performance-diagnosis\scripts

# 查看磁盘信息
.\disk-info.ps1

# 分析磁盘使用情况
.\disk-usage.ps1

# 运行I/O性能测试
.\io-test.ps1
```

### 3. 远程Linux服务器诊断

```powershell
# 诊断远程服务器磁盘信息
.\disk-info.ps1 -Remote -Host 10.22.12.213 -User root -Password "yourpassword"

# 分析远程服务器磁盘使用（指定路径）
.\disk-usage.ps1 -Remote -Host 10.22.12.213 -User root -Password "yourpassword"

# 远程I/O性能测试（需要远程服务器安装fio）
.\io-test.ps1 -Remote -Host 10.22.12.213 -User root -Password "yourpassword"
```

**注意**: Windows SSH客户端可能需要手动输入密码。建议配置SSH密钥认证。

## Linux用户快速开始

### 1. 赋予脚本执行权限

```bash
cd /path/to/disk-performance-diagnosis/scripts
chmod +x *.sh
```

### 2. 安装依赖工具（可选）

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install sysstat smartmontools fio sshpass

# CentOS/RHEL
sudo yum install sysstat smartmontools fio sshpass
```

### 3. 本地磁盘诊断

```bash
# 查看磁盘信息
./disk-info.sh

# 分析磁盘使用情况
./disk-usage.sh

# 运行I/O性能测试
./io-test.sh
```

### 4. 远程服务器诊断

```bash
# 诊断远程服务器
./disk-info.sh --remote --host=192.168.1.100 --user=root --password=yourpassword

# 分析远程磁盘使用
./disk-usage.sh --remote --host=192.168.1.100 --user=root --password=yourpassword

# 远程I/O测试
./io-test.sh --remote --host=192.168.1.100 --user=root --password=yourpassword
```

## 使用SSH密钥认证（推荐）

### Windows配置SSH密钥

```powershell
# 生成SSH密钥对
ssh-keygen -t rsa -b 4096

# 复制公钥到远程服务器
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh root@10.22.12.213 "cat >> ~/.ssh/authorized_keys"

# 使用密钥连接（无需密码参数）
.\disk-info.ps1 -Remote -Host 10.22.12.213 -User root
```

### Linux配置SSH密钥

```bash
# 生成SSH密钥对
ssh-keygen -t rsa -b 4096

# 复制公钥到远程服务器
ssh-copy-id root@192.168.1.100

# 使用密钥连接（无需密码参数）
./disk-info.sh --remote --host=192.168.1.100 --user=root
```

## 常见使用场景

### 场景1: 磁盘空间不足排查

```powershell
# Windows
.\disk-usage.ps1
# 查看输出中的"按目录排序的空间使用"和"大文件"部分

# Linux
./disk-usage.sh
# 查看输出中的前20个最大目录和大文件列表
```

### 场景2: 系统响应慢，怀疑磁盘性能问题

```powershell
# Windows
.\io-test.ps1
# 查看顺序读写速度和随机IOPS

# Linux
./io-test.sh
# 需要先安装fio: sudo apt-get install fio
```

### 场景3: 定期健康检查

```powershell
# Windows - 完整诊断
.\disk-info.ps1 > disk-report-$(Get-Date -Format 'yyyyMMdd').txt
.\disk-usage.ps1 >> disk-report-$(Get-Date -Format 'yyyyMMdd').txt

# Linux - 完整诊断
./disk-info.sh > disk-report-$(date +%Y%m%d).txt
./disk-usage.sh >> disk-report-$(date +%Y%m%d).txt
```

### 场景4: 批量远程服务器诊断

**Windows PowerShell批量脚本**:
```powershell
$servers = @("10.22.12.213", "10.22.12.214", "10.22.12.215")
$user = "root"
$password = "yourpassword"

foreach ($server in $servers) {
    Write-Host "=== 诊断服务器: $server ===" -ForegroundColor Cyan
    .\disk-info.ps1 -Remote -Host $server -User $user -Password $password
    Write-Host ""
}
```

**Linux Bash批量脚本**:
```bash
#!/bin/bash
servers=("192.168.1.100" "192.168.1.101" "192.168.1.102")
user="root"
password="yourpassword"

for server in "${servers[@]}"; do
    echo "=== 诊断服务器: $server ==="
    ./disk-info.sh --remote --host=$server --user=$user --password=$password
    echo ""
done
```

## 输出结果解读

### 磁盘使用率警告级别
- **0-70%**: 正常，无需担心
- **70-85%**: 注意，建议开始清理或扩容规划
- **85-95%**: 警告，应尽快清理或扩容
- **95-100%**: 危险，立即处理

### I/O性能参考值

**顺序读写速度**:
- **HDD**: 80-160 MB/s
- **SATA SSD**: 400-550 MB/s
- **NVMe SSD**: 1500-3500 MB/s

**随机读取IOPS**:
- **HDD**: 80-160 IOPS
- **SATA SSD**: 10,000-90,000 IOPS
- **NVMe SSD**: 100,000-500,000 IOPS

## 故障排除

### Windows问题

**问题**: "无法加载文件，因为在此系统上禁止运行脚本"
```powershell
# 解决方案
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**问题**: "拒绝访问"或权限错误
```powershell
# 解决方案：以管理员身份运行PowerShell
```

**问题**: SSH连接失败
```powershell
# 检查SSH服务是否运行
Get-Service ssh-agent
# 如果未运行，启动服务
Start-Service ssh-agent
```

### Linux问题

**问题**: "fio: command not found"
```bash
# Ubuntu/Debian
sudo apt-get install fio

# CentOS/RHEL
sudo yum install fio
```

**问题**: "sshpass: command not found"
```bash
# Ubuntu/Debian
sudo apt-get install sshpass

# CentOS/RHEL
sudo yum install sshpass
```

**问题**: "Permission denied"
```bash
# 赋予执行权限
chmod +x *.sh
```

## 获取帮助

如果遇到问题，请检查：
1. 是否有足够的权限
2. 是否安装了必要的依赖工具
3. 网络连接是否正常（远程执行时）
4. 参考SKILL.md中的详细文档
