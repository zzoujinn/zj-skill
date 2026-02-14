---
name: shell-toolkit
description: Shell 脚本工具箱。帮助生成常用运维脚本（备份、清理、监控、巡检、部署），提供 Shell 脚本编写规范和最佳实践。当用户需要：(1) 编写运维自动化 Shell 脚本，(2) 生成备份/清理/监控/巡检脚本，(3) 审查 Shell 脚本质量和安全性，(4) 编写定时任务脚本，(5) 编写批量操作脚本，(6) Shell 脚本调试和优化时使用。触发条件："shell脚本"、"bash脚本"、"运维脚本"、"备份脚本"、"清理脚本"、"监控脚本"、"巡检脚本"、"定时任务"、"crontab"。
---

# Shell 脚本工具箱

## 脚本编写规范

### 通用模板

```bash
#!/bin/bash
set -euo pipefail

# ============================================================
# 脚本名称: script_name.sh
# 功能描述: 简要描述
# 使用方法: ./script_name.sh [参数]
# ============================================================

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"
DATE_STR=$(date +%Y%m%d_%H%M%S)

# 日志函数
log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*" | tee -a "$LOG_FILE"; }
log_warn()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]  $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" | tee -a "$LOG_FILE" >&2; }

# 错误处理
cleanup() {
    # 清理临时文件等
    log_info "脚本结束"
}
trap cleanup EXIT

# 用法说明
usage() {
    cat <<EOF
用法: $SCRIPT_NAME [选项]

选项:
  -h, --help     显示帮助信息
  -v, --verbose  详细输出

EOF
    exit 0
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage ;;
        -v|--verbose) VERBOSE=1; shift ;;
        *)            log_error "未知参数: $1"; usage ;;
    esac
done

# 主逻辑
main() {
    log_info "脚本开始执行"
    # 在此编写业务逻辑
}

main "$@"
```

### 编写要点

1. **安全头部**：`set -euo pipefail`（遇错退出、未定义变量报错、管道错误传递）
2. **日志规范**：统一日志格式，区分 INFO/WARN/ERROR
3. **参数校验**：检查必需参数，提供 usage 说明
4. **错误处理**：trap EXIT 清理资源，trap ERR 处理异常
5. **变量引用**：始终用双引号包裹变量 `"$var"`
6. **命令替换**：使用 `$()` 而非反引号
7. **幂等设计**：重复执行不会产生副作用

## 常用脚本模板

### 数据库备份

```bash
#!/bin/bash
set -euo pipefail

# 配置
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS}"
DB_NAME="${DB_NAME:-mydb}"
BACKUP_DIR="/data/backup/mysql"
KEEP_DAYS=7

DATE_STR=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE_STR}.sql.gz"

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2; }

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 执行备份
log_info "开始备份数据库 ${DB_NAME}"
if mysqldump -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" \
    --single-transaction --routines --triggers \
    "$DB_NAME" | gzip > "$BACKUP_FILE"; then
    FILESIZE=$(du -sh "$BACKUP_FILE" | awk '{print $1}')
    log_info "备份成功: ${BACKUP_FILE} (${FILESIZE})"
else
    log_error "备份失败"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# 清理过期备份
log_info "清理 ${KEEP_DAYS} 天前的备份"
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +${KEEP_DAYS} -delete
log_info "当前备份数: $(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" | wc -l)"
```

### 日志清理

```bash
#!/bin/bash
set -euo pipefail

# 配置
LOG_DIRS=(
    "/var/log/nginx"
    "/var/log/app"
    "/opt/app/logs"
)
KEEP_DAYS=30
MIN_FREE_PERCENT=20
DRY_RUN=${DRY_RUN:-false}

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"; }

# 检查磁盘空间
check_disk() {
    local mount_point=$1
    local usage
    usage=$(df "$mount_point" | awk 'NR==2 {print int($5)}')
    echo "$usage"
}

# 清理日志
clean_logs() {
    local dir=$1
    local days=$2

    if [[ ! -d "$dir" ]]; then
        log_info "目录不存在，跳过: $dir"
        return
    fi

    local count
    count=$(find "$dir" -name "*.log" -o -name "*.log.*" -o -name "*.gz" | \
            xargs -I{} find {} -mtime +"$days" 2>/dev/null | wc -l)

    if [[ "$count" -eq 0 ]]; then
        log_info "无需清理: $dir"
        return
    fi

    log_info "发现 ${count} 个过期文件: $dir"

    if [[ "$DRY_RUN" == "true" ]]; then
        find "$dir" \( -name "*.log" -o -name "*.log.*" -o -name "*.gz" \) \
            -mtime +"$days" -ls
    else
        find "$dir" \( -name "*.log" -o -name "*.log.*" -o -name "*.gz" \) \
            -mtime +"$days" -delete
        log_info "已清理 ${count} 个文件"
    fi
}

# 主逻辑
for dir in "${LOG_DIRS[@]}"; do
    clean_logs "$dir" "$KEEP_DAYS"
done

# 清理空目录
for dir in "${LOG_DIRS[@]}"; do
    [[ -d "$dir" ]] && find "$dir" -type d -empty -delete 2>/dev/null || true
done

log_info "清理完成"
```

### 服务健康检查

```bash
#!/bin/bash
set -euo pipefail

# 配置检查项
declare -A SERVICES=(
    ["nginx"]="http://localhost:80/health"
    ["api"]="http://localhost:8080/health"
    ["redis"]="redis-cli ping"
)

ALERT_CMD="curl -s -X POST https://hooks.example.com/alert"
CHECK_TIMEOUT=5

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*"; }

check_http() {
    local url=$1
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$CHECK_TIMEOUT" "$url" 2>/dev/null || echo "000")
    [[ "$status" == "200" ]]
}

check_command() {
    local cmd=$1
    eval "$cmd" &>/dev/null
}

send_alert() {
    local service=$1
    local message=$2
    log_error "告警: ${service} - ${message}"
    $ALERT_CMD -d "{\"service\":\"${service}\",\"message\":\"${message}\"}" 2>/dev/null || true
}

# 执行检查
for service in "${!SERVICES[@]}"; do
    target="${SERVICES[$service]}"

    if [[ "$target" == http* ]]; then
        if check_http "$target"; then
            log_info "${service}: 正常"
        else
            send_alert "$service" "HTTP 健康检查失败: $target"
        fi
    else
        if check_command "$target"; then
            log_info "${service}: 正常"
        else
            send_alert "$service" "命令检查失败: $target"
        fi
    fi
done
```

### 批量远程执行

```bash
#!/bin/bash
set -euo pipefail

# 配置
HOSTS_FILE="${1:?用法: $0 <hosts_file> <command>}"
REMOTE_CMD="${2:?用法: $0 <hosts_file> <command>}"
SSH_USER="${SSH_USER:-root}"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
PARALLEL=${PARALLEL:-5}

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*"; }

execute_on_host() {
    local host=$1
    local cmd=$2
    local output
    if output=$(ssh $SSH_OPTS "${SSH_USER}@${host}" "$cmd" 2>&1); then
        echo "[${host}] 成功:"
        echo "$output" | sed "s/^/  [${host}] /"
    else
        echo "[${host}] 失败:"
        echo "$output" | sed "s/^/  [${host}] /"
        return 1
    fi
}

# 读取主机列表并并行执行
log_info "开始执行命令: ${REMOTE_CMD}"
log_info "目标主机: $(wc -l < "$HOSTS_FILE") 台"

export -f execute_on_host log_info log_error
export SSH_USER SSH_OPTS

cat "$HOSTS_FILE" | grep -v "^#" | grep -v "^$" | \
    xargs -P "$PARALLEL" -I{} bash -c "execute_on_host '{}' '$REMOTE_CMD'"

log_info "执行完成"
```

## Crontab 规范

```bash
# 格式: 分 时 日 月 周 命令
# 重要：重定向输出，避免邮件堆积

# 每天凌晨2点数据库备份
0 2 * * * /opt/scripts/backup_db.sh >> /var/log/backup_db.log 2>&1

# 每天凌晨3点清理日志
0 3 * * * /opt/scripts/clean_logs.sh >> /var/log/clean_logs.log 2>&1

# 每5分钟健康检查
*/5 * * * * /opt/scripts/health_check.sh >> /var/log/health_check.log 2>&1

# 每周日凌晨4点全量备份
0 4 * * 0 /opt/scripts/full_backup.sh >> /var/log/full_backup.log 2>&1
```

## 脚本审查清单

1. **安全头部**：是否有 `set -euo pipefail`
2. **变量引用**：变量是否用双引号包裹
3. **输入校验**：是否校验参数和用户输入
4. **日志输出**：是否有规范的日志记录
5. **错误处理**：是否有 trap 处理异常退出
6. **幂等性**：重复执行是否安全
7. **权限检查**：是否检查执行权限（root 检查等）
8. **锁机制**：长时间任务是否防止重复执行（flock）
9. **超时控制**：外部命令是否设置超时
10. **敏感信息**：密码等是否从环境变量读取而非硬编码
