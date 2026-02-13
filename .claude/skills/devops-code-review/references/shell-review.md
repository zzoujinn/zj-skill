# Shell Script Review Guidelines

## Shell Best Practices

### 1. Script Header and Shebang

```bash
#!/bin/bash
# GOOD - Explicit bash shebang
# Script: deploy.sh
# Description: Deploy application to production
# Author: DevOps Team
# Date: 2024-01-01

set -euo pipefail  # Exit on error, undefined vars, pipe failures
# set -x  # Uncomment for debugging

# BAD - Generic sh shebang (behavior varies)
#!/bin/sh

# BAD - No error handling
# (script continues even after errors)
```

### 2. Variable Quoting

```bash
# ALWAYS quote variables to prevent word splitting and globbing

# BAD - Unquoted variables
file=$1
rm -rf $file  # DANGEROUS: "my file.txt" becomes "my" and "file.txt"
if [ $status = "success" ]; then  # Fails if status is empty

# GOOD - Quoted variables
file="$1"
rm -rf "$file"
if [ "$status" = "success" ]; then

# GOOD - Array handling
files=("file1.txt" "file 2.txt" "file3.txt")
for file in "${files[@]}"; do  # Preserves spaces
    process "$file"
done
```

### 3. Error Handling

```bash
# GOOD - Check command success
if ! command -v docker &> /dev/null; then
    echo "Error: docker not found" >&2
    exit 1
fi

# GOOD - Check file operations
if ! cp source.txt dest.txt; then
    echo "Error: Failed to copy file" >&2
    exit 1
fi

# GOOD - Use trap for cleanup
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# GOOD - Validate required variables
: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:?DB_PORT is required}"

# GOOD - Function error handling
deploy() {
    local app=$1

    if [ -z "$app" ]; then
        echo "Error: app name required" >&2
        return 1
    fi

    if ! docker build -t "$app" .; then
        echo "Error: Build failed" >&2
        return 1
    fi

    return 0
}
```

### 4. Input Validation

```bash
# GOOD - Validate arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source> <destination>" >&2
    exit 1
fi

source="$1"
dest="$2"

# GOOD - Validate file exists
if [ ! -f "$source" ]; then
    echo "Error: Source file not found: $source" >&2
    exit 1
fi

# GOOD - Validate format
validate_ip() {
    local ip=$1
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "Error: Invalid IP address: $ip" >&2
        return 1
    fi
    return 0
}

# GOOD - Validate environment
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo "Error: Invalid environment: $ENVIRONMENT" >&2
    exit 1
fi
```

### 5. Functions and Modularity

```bash
# GOOD - Use functions for reusability
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

check_prerequisites() {
    local missing=0

    for cmd in docker kubectl helm; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command not found: $cmd"
            missing=1
        fi
    done

    return $missing
}

deploy_service() {
    local service=$1
    local version=$2

    log_info "Deploying $service version $version"

    if ! kubectl apply -f "manifests/$service.yaml"; then
        log_error "Failed to deploy $service"
        return 1
    fi

    log_info "Successfully deployed $service"
    return 0
}

# Main execution
main() {
    if ! check_prerequisites; then
        exit 1
    fi

    deploy_service "api" "v1.2.3"
    deploy_service "worker" "v1.2.3"
}

main "$@"
```

### 6. Avoid Common Pitfalls

```bash
# BAD - Using ls for file iteration
for file in $(ls *.txt); do  # Breaks on spaces, globs
    process "$file"
done

# GOOD - Use glob directly
for file in *.txt; do
    [ -f "$file" ] || continue  # Skip if no matches
    process "$file"
done

# BAD - Parsing ls output
files=$(ls -l | awk '{print $9}')

# GOOD - Use find or arrays
mapfile -t files < <(find . -name "*.txt")

# BAD - Using cat unnecessarily
cat file.txt | grep pattern

# GOOD - Direct input redirection
grep pattern file.txt
# or
grep pattern < file.txt

# BAD - Useless use of echo
echo "$var" | command

# GOOD - Use here-string
command <<< "$var"

# BAD - Testing with ==
if [ "$var" == "value" ]; then  # Not POSIX

# GOOD - Use =
if [ "$var" = "value" ]; then

# BETTER - Use [[ for bash
if [[ "$var" == "value" ]]; then  # Bash-specific, more features
```

### 7. Secure Practices

```bash
# GOOD - Avoid eval
# BAD
eval "$user_input"

# GOOD - Use arrays or proper quoting
cmd=(docker run -it "$image")
"${cmd[@]}"

# GOOD - Secure temp files
temp_file=$(mktemp)
chmod 600 "$temp_file"
trap 'rm -f "$temp_file"' EXIT

# GOOD - Avoid exposing secrets in process list
# BAD
mysql -u root -p"$PASSWORD" -e "SELECT * FROM users"

# GOOD - Use config file or stdin
mysql --defaults-extra-file=<(cat <<EOF
[client]
user=root
password=$PASSWORD
EOF
) -e "SELECT * FROM users"

# GOOD - Sanitize user input
sanitize() {
    local input=$1
    # Remove everything except alphanumeric, dash, underscore
    echo "$input" | tr -cd '[:alnum:]_-'
}

user_input=$(sanitize "$1")
```

### 8. Performance Optimization

```bash
# BAD - Spawning processes in loop
while read line; do
    echo "$line" | awk '{print $1}'
done < file.txt

# GOOD - Single process
awk '{print $1}' file.txt

# BAD - Multiple greps
grep "ERROR" app.log > errors.txt
grep "WARNING" app.log > warnings.txt

# GOOD - Single pass with awk
awk '/ERROR/ {print > "errors.txt"} /WARNING/ {print > "warnings.txt"}' app.log

# BAD - Reading file multiple times
count=$(grep -c "pattern" file.txt)
lines=$(grep "pattern" file.txt)

# GOOD - Read once
lines=$(grep "pattern" file.txt)
count=$(echo "$lines" | wc -l)

# BETTER - Use process substitution
while IFS= read -r line; do
    process "$line"
done < <(grep "pattern" file.txt)
```

### 9. Logging and Output

```bash
# GOOD - Structured logging
readonly LOG_FILE="/var/log/deploy.log"
readonly LOG_LEVEL="${LOG_LEVEL:-INFO}"

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_debug() {
    [ "$LOG_LEVEL" = "DEBUG" ] && log "DEBUG" "$@"
}

log_info() {
    log "INFO" "$@"
}

log_error() {
    log "ERROR" "$@" >&2
}

# GOOD - Separate stdout and stderr
log_info "Starting deployment"
if ! deploy_app; then
    log_error "Deployment failed"
    exit 1
fi
log_info "Deployment completed"
```

### 10. Configuration Management

```bash
# GOOD - Use configuration file
readonly CONFIG_FILE="${CONFIG_FILE:-/etc/app/config.sh}"

if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
else
    log_error "Config file not found: $CONFIG_FILE"
    exit 1
fi

# GOOD - Environment variable defaults
: "${APP_PORT:=8080}"
: "${APP_HOST:=localhost}"
: "${LOG_LEVEL:=INFO}"

# GOOD - Validate configuration
validate_config() {
    local errors=0

    if [ -z "$DB_HOST" ]; then
        log_error "DB_HOST not configured"
        errors=$((errors + 1))
    fi

    if ! [[ "$APP_PORT" =~ ^[0-9]+$ ]]; then
        log_error "Invalid APP_PORT: $APP_PORT"
        errors=$((errors + 1))
    fi

    return $errors
}
```

## Shell Script Review Checklist

### Script Structure
- [ ] Proper shebang (#!/bin/bash)
- [ ] set -euo pipefail for error handling
- [ ] Script header with description
- [ ] Functions for reusability
- [ ] Main function for entry point

### Variable Handling
- [ ] All variables quoted
- [ ] Arrays used for lists
- [ ] Local variables in functions
- [ ] Readonly for constants
- [ ] Parameter validation

### Error Handling
- [ ] Exit codes checked
- [ ] Trap for cleanup
- [ ] Error messages to stderr
- [ ] Meaningful error messages
- [ ] Graceful failure handling

### Security
- [ ] No eval usage
- [ ] Input sanitization
- [ ] Secure temp files
- [ ] No secrets in process list
- [ ] Proper file permissions

### Performance
- [ ] No unnecessary process spawning
- [ ] Efficient loops
- [ ] Single-pass processing
- [ ] Appropriate use of built-ins

### Code Quality
- [ ] Consistent naming convention
- [ ] Comments for complex logic
- [ ] No useless use of cat
- [ ] Proper use of [[ vs [
- [ ] ShellCheck clean

### DevOps Specific
- [ ] Idempotent operations
- [ ] Proper logging
- [ ] Configuration externalized
- [ ] Rollback capability
- [ ] Health checks

## Common Shell Anti-Patterns

### 1. Not Checking Exit Codes
```bash
# BAD
docker build -t myapp .
docker push myapp:latest

# GOOD
if ! docker build -t myapp .; then
    echo "Build failed" >&2
    exit 1
fi

if ! docker push myapp:latest; then
    echo "Push failed" >&2
    exit 1
fi
```

### 2. Parsing ls Output
```bash
# BAD
for file in $(ls /path); do

# GOOD
for file in /path/*; do
    [ -e "$file" ] || continue
```

### 3. Not Quoting Variables
```bash
# BAD
if [ $var = "value" ]; then

# GOOD
if [ "$var" = "value" ]; then
```

### 4. Using Backticks
```bash
# BAD
result=`command`

# GOOD
result=$(command)
```

### 5. Not Using Local Variables
```bash
# BAD
function process() {
    result="value"  # Global variable
}

# GOOD
function process() {
    local result="value"
}
```

## Shell Tools and Linters

- **shellcheck**: Static analysis tool (highly recommended)
- **shfmt**: Shell script formatter
- **bashate**: Style checker
- **shellharden**: Hardening suggestions

Run shellcheck on all scripts:
```bash
shellcheck -x script.sh
```
