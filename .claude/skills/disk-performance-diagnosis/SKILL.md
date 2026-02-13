---
name: disk-performance-diagnosis
description: 用于诊断服务器磁盘性能，包括磁盘使用情况分析、I/O性能测试、瓶颈识别和优化建议。支持本地和远程执行，通过指定IP、用户名和密码进行远程服务器诊断。使用当需要：1) 检查磁盘空间使用情况，2) 分析磁盘读写性能，3) 识别磁盘瓶颈，4) 提供性能优化建议。
---

# 磁盘性能诊断

## 概述

本skill提供跨平台的服务器磁盘性能诊断工具，帮助识别磁盘性能问题和优化机会。通过综合分析磁盘使用情况、I/O性能和系统指标，提供全面的磁盘性能评估报告。

**平台支持**：
- **Windows**: 使用PowerShell脚本（.ps1），支持本地Windows磁盘诊断和远程Linux服务器诊断
- **Linux**: 使用Bash脚本（.sh），支持本地和远程Linux服务器诊断

**执行模式**：
- 本地执行：诊断当前机器的磁盘性能
- 远程执行：通过SSH连接远程Linux服务器进行诊断

## 工作流程

### 1. 确定执行环境
- **Windows环境**: 使用PowerShell脚本（.ps1文件）
- **Linux环境**: 使用Bash脚本（.sh文件）
- 自动检测操作系统并选择合适的脚本

### 2. 连接目标服务器
- 支持本地执行和远程SSH执行
- 通过IP、用户名和密码连接远程Linux服务器
- Windows通过OpenSSH客户端连接远程服务器

### 3. 收集磁盘信息
- 使用 `disk-info.ps1` (Windows) 或 `disk-info.sh` (Linux)
- Windows: 收集磁盘、分区、卷信息
- Linux: 分析磁盘分区、文件系统和挂载点

### 4. 性能测试
- 使用 `io-test.ps1` (Windows) 或 `io-test.sh` (Linux)
- 测量顺序/随机读写速度、IOPS、延迟

### 5. 使用情况分析
- 使用 `disk-usage.ps1` (Windows) 或 `disk-usage.sh` (Linux)
- 识别大文件和占用空间较多的目录
- 分析文件类型分布

### 6. 生成报告
- 综合分析结果生成性能报告
- 提供优化建议和改进措施

## 脚本使用指南

### disk-info (磁盘信息收集)
**Windows**: `disk-info.ps1` | **Linux**: `disk-info.sh`

收集磁盘基本信息，包括：
- **Windows**: 物理磁盘、分区、卷信息、健康状态、实时I/O性能计数器
- **Linux**: 磁盘分区信息、文件系统类型、挂载点、磁盘大小和可用空间
- 支持本地和远程执行

### io-test (I/O性能测试)
**Windows**: `io-test.ps1` | **Linux**: `io-test.sh`

进行I/O性能测试，测量：
- 顺序读写速度（MB/s）
- 随机读写性能（IOPS）
- 延迟时间（ms）
- 吞吐量
- **Windows**: 使用原生.NET文件I/O进行测试
- **Linux**: 使用fio工具进行专业测试（需要安装fio）

### disk-usage (磁盘使用分析)
**Windows**: `disk-usage.ps1` | **Linux**: `disk-usage.sh`

分析磁盘使用情况：
- 按目录排序的空间使用（前20个）
- 大文件识别（>100MB）
- 文件类型统计（Windows特有）
- 最近修改的文件
- 空间使用趋势分析

## 远程执行功能

### Windows环境 (PowerShell)

**本地Windows磁盘诊断**：
```powershell
# 磁盘信息收集
.\disk-info.ps1

# 磁盘使用分析
.\disk-usage.ps1

# I/O性能测试
.\io-test.ps1
```

**远程Linux服务器诊断**：
```powershell
# 磁盘信息收集
.\disk-info.ps1 -Remote -Host 10.22.12.213 -User root -Password yourpassword -Port 22

# 磁盘使用分析
.\disk-usage.ps1 -Remote -Host 10.22.12.213 -User root -Password yourpassword

# I/O性能测试（需要远程服务器安装fio）
.\io-test.ps1 -Remote -Host 10.22.12.213 -User root -Password yourpassword
```

**注意**：Windows环境下使用OpenSSH客户端连接远程服务器，密码参数仅用于标识，实际连接时可能需要手动输入密码。

### Linux环境 (Bash)

**本地执行**：
```bash
# 磁盘信息收集
./disk-info.sh

# 磁盘使用分析
./disk-usage.sh

# I/O性能测试
./io-test.sh
```

**远程执行**：
```bash
# 磁盘信息收集
./disk-info.sh --remote --host=192.168.1.100 --user=admin --password=yourpassword

# 磁盘使用分析
./disk-usage.sh --remote --host=192.168.1.100 --user=admin --password=yourpassword

# I/O性能测试
./io-test.sh --remote --host=192.168.1.100 --user=admin --password=yourpassword
```

### 支持的参数

**PowerShell参数**：
- `-Remote`: 启用远程执行模式（开关参数）
- `-Host`: 目标服务器IP地址或主机名
- `-User`: SSH用户名
- `-Password`: SSH密码（可选）
- `-Port`: SSH端口（默认22）
- `-Timeout`: 连接超时秒数（默认30）
- `-TargetPath`: 要分析的路径（disk-usage专用）

**Bash参数**：
- `--remote`: 启用远程执行模式
- `--host=<IP>`: 目标服务器IP地址
- `--user=<username>`: SSH用户名
- `--password=<password>`: SSH密码（需要sshpass）
- `--port=<port>`: SSH端口（默认22）
- `--timeout=<seconds>`: 连接超时（默认30秒）

### 安全注意事项

**通用安全建议**：
1. 密码在内存中临时存储，执行后清除
2. 建议使用SSH密钥认证替代密码
3. 确保网络连接安全
4. 避免在生产高峰期进行性能测试

**Windows特定**：
- Windows OpenSSH客户端不支持命令行密码传递，连接时需要手动输入密码
- 建议配置SSH密钥认证以实现自动化
- 确保PowerShell执行策略允许运行脚本：`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Linux特定**：
- 远程密码认证需要安装`sshpass`工具
- Ubuntu/Debian: `sudo apt-get install sshpass`
- CentOS/RHEL: `sudo yum install sshpass`
- 生产环境建议使用SSH密钥而非密码

## 系统要求

### Windows环境
- **操作系统**: Windows 10/11 或 Windows Server 2016+
- **PowerShell**: 5.1 或更高版本
- **SSH客户端**: OpenSSH客户端（Windows 10 1809+自带）
- **权限**: 管理员权限（用于访问磁盘性能计数器）

### Linux环境
- **操作系统**: Ubuntu 18.04+, CentOS 7+, 或其他主流发行版
- **必需工具**: bash, df, du, find, lsblk
- **可选工具**: iostat (sysstat包), smartctl (smartmontools包), fio (性能测试)
- **远程执行**: sshpass (用于密码认证)

## 参考文档

- [磁盘性能指标说明](references/performance-metrics.md) - 详细解释各项性能指标的含义
- [常见磁盘问题诊断](references/common-issues.md) - 常见磁盘问题的识别和解决方法
- [优化建议指南](references/optimization-guide.md) - 针对不同问题的优化建议
- [远程执行指南](references/remote-execution.md) - 远程执行详细说明和安全建议

## 注意事项

### 通用注意事项
1. 执行性能测试可能影响系统性能，建议在非高峰时段进行
2. 确保有足够的权限执行相关命令
3. 测试结果应结合实际业务需求进行评估
4. 对于生产环境，建议先在小规模测试环境验证优化方案

### Windows环境注意事项
1. **执行策略**: 首次运行PowerShell脚本前，需要设置执行策略：
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
2. **管理员权限**: 某些磁盘操作需要管理员权限，建议以管理员身份运行PowerShell
3. **磁盘扫描时间**: 大容量磁盘的使用情况分析可能需要较长时间
4. **远程连接**: Windows SSH客户端连接远程Linux服务器时，密码需要手动输入

### Linux环境注意事项
1. **工具依赖**:
   - I/O测试需要安装`fio`工具
   - 远程密码认证需要安装`sshpass`
   - 高级诊断需要`iostat`和`smartctl`
2. **远程执行**: 需要目标服务器开启SSH服务
3. **网络稳定性**: 确保网络连接稳定，避免中断导致的不完整结果
4. **权限要求**: 某些操作需要root权限或sudo权限

### 性能测试注意事项
1. **Windows I/O测试**:
   - 会创建1GB临时测试文件
   - 测试期间会占用磁盘I/O资源
   - 自动清理测试文件
2. **Linux I/O测试**:
   - 需要fio工具支持
   - 测试时间较长（每个测试约30秒）
   - 会在/tmp目录创建测试文件

### 最佳实践
1. **首次使用**: 先在测试环境运行，熟悉工具行为
2. **定期诊断**: 建议每月进行一次磁盘健康检查
3. **结果保存**: 将诊断结果保存为文本文件，便于历史对比
4. **SSH密钥**: 生产环境建议配置SSH密钥认证，避免密码泄露风险