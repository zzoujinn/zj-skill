# Security Checklist for DevOps Code Review

## Critical Security Issues

### 1. Command Injection

**Shell Scripts:**
```bash
# BAD - Command injection vulnerability
user_input="$1"
eval "ls $user_input"  # DANGEROUS
ssh $HOST "cd $user_input && ls"  # DANGEROUS

# GOOD - Properly quoted and validated
user_input="$1"
if [[ "$user_input" =~ ^[a-zA-Z0-9/_-]+$ ]]; then
    ls "$user_input"
else
    echo "Invalid input"
    exit 1
fi
```

**Python:**
```python
# BAD - Command injection
import os
user_input = sys.argv[1]
os.system(f"ls {user_input}")  # DANGEROUS
subprocess.call(f"ssh {host} 'cd {path}'", shell=True)  # DANGEROUS

# GOOD - Use list arguments
import subprocess
subprocess.run(["ls", user_input], check=True)
subprocess.run(["ssh", host, "cd", path], check=True)
```

**Go:**
```go
// BAD - Command injection
cmd := exec.Command("sh", "-c", "ls "+userInput)  // DANGEROUS

// GOOD - Separate arguments
cmd := exec.Command("ls", userInput)
```

### 2. Credential and Secret Management

**Common Issues:**
- Hardcoded passwords, API keys, tokens
- Secrets in environment variables without encryption
- Credentials in logs or error messages
- Unencrypted credential files

**Best Practices:**
```bash
# BAD
DB_PASSWORD="hardcoded_password"
API_KEY="sk-1234567890abcdef"

# GOOD - Use secret management
DB_PASSWORD=$(vault kv get -field=password secret/db)
API_KEY=$(aws secretsmanager get-secret-value --secret-id api-key --query SecretString --output text)

# Or use environment variables from secure sources
DB_PASSWORD="${DB_PASSWORD:?DB_PASSWORD not set}"
```

**Python:**
```python
# BAD
password = "hardcoded_password"

# GOOD
import os
from getpass import getpass

password = os.environ.get('DB_PASSWORD')
if not password:
    password = getpass('Enter password: ')
```

### 3. Privilege Escalation

**Check for:**
- Unnecessary sudo usage
- Running as root when not needed
- Overly permissive file permissions
- SUID/SGID binaries

```bash
# BAD
sudo rm -rf /tmp/*  # Unnecessary sudo

# GOOD - Check if sudo is actually needed
if [[ -w /tmp ]]; then
    rm -rf /tmp/*
else
    sudo rm -rf /tmp/*
fi

# BAD - Overly permissive
chmod 777 config.yaml

# GOOD - Minimal permissions
chmod 600 config.yaml  # Only owner can read/write
```

### 4. Path Traversal

**Shell:**
```bash
# BAD
filename="$1"
cat "/var/log/$filename"  # Can access ../../../etc/passwd

# GOOD - Validate and sanitize
filename="$1"
filename="${filename//[^a-zA-Z0-9._-]/}"  # Remove dangerous chars
if [[ "$filename" =~ \.\. ]]; then
    echo "Invalid filename"
    exit 1
fi
cat "/var/log/$filename"
```

**Python:**
```python
# BAD
import os
filename = sys.argv[1]
with open(f"/var/log/{filename}") as f:
    print(f.read())

# GOOD - Validate path
import os
from pathlib import Path

filename = sys.argv[1]
log_dir = Path("/var/log")
file_path = (log_dir / filename).resolve()

if not file_path.is_relative_to(log_dir):
    raise ValueError("Path traversal detected")

with open(file_path) as f:
    print(f.read())
```

### 5. Input Validation

**Always validate:**
- User input
- Environment variables
- Configuration files
- API responses
- Command-line arguments

```bash
# GOOD - Validate input format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

if validate_ip "$USER_IP"; then
    ping -c 1 "$USER_IP"
else
    echo "Invalid IP address"
    exit 1
fi
```

## High Priority Security Issues

### 6. Insecure Network Communication

```bash
# BAD - Unencrypted communication
curl http://api.example.com/data
wget http://files.example.com/package.tar.gz

# GOOD - Use HTTPS
curl https://api.example.com/data
wget https://files.example.com/package.tar.gz --secure-protocol=TLSv1_2

# GOOD - Verify certificates
curl --cacert /etc/ssl/certs/ca-bundle.crt https://api.example.com/data
```

**Python:**
```python
# BAD
import requests
response = requests.get('http://api.example.com/data', verify=False)

# GOOD
response = requests.get('https://api.example.com/data', verify=True, timeout=30)
```

### 7. Insecure Temporary Files

```bash
# BAD - Predictable temp file
temp_file="/tmp/myapp.tmp"
echo "sensitive data" > $temp_file

# GOOD - Use mktemp
temp_file=$(mktemp)
trap "rm -f $temp_file" EXIT
echo "sensitive data" > "$temp_file"
chmod 600 "$temp_file"
```

**Python:**
```python
# BAD
with open('/tmp/data.tmp', 'w') as f:
    f.write(sensitive_data)

# GOOD
import tempfile
with tempfile.NamedTemporaryFile(mode='w', delete=True) as f:
    f.write(sensitive_data)
    f.flush()
    # Use f.name
```

### 8. SQL Injection (for database scripts)

**Python:**
```python
# BAD
query = f"SELECT * FROM users WHERE username = '{username}'"
cursor.execute(query)

# GOOD - Use parameterized queries
query = "SELECT * FROM users WHERE username = %s"
cursor.execute(query, (username,))
```

### 9. Unsafe Deserialization

**Python:**
```python
# BAD
import pickle
data = pickle.loads(untrusted_data)  # DANGEROUS

# GOOD - Use safe formats
import json
data = json.loads(untrusted_data)
```

### 10. Race Conditions

```bash
# BAD - TOCTOU vulnerability
if [ -f "$file" ]; then
    cat "$file"  # File could be replaced between check and use
fi

# GOOD - Atomic operations
cat "$file" 2>/dev/null || echo "File not found"
```

## Medium Priority Security Issues

### 11. Information Disclosure

**Avoid exposing:**
- Stack traces in production
- Internal paths and structure
- Version information
- Debug information

```python
# BAD
try:
    process_data()
except Exception as e:
    print(f"Error: {e}")  # May expose sensitive info
    traceback.print_exc()  # Exposes stack trace

# GOOD
import logging
try:
    process_data()
except Exception as e:
    logging.error("Failed to process data", exc_info=True)  # Log to file
    print("An error occurred. Please check logs.")  # Generic message to user
```

### 12. Insecure Randomness

```python
# BAD - Predictable random
import random
token = random.randint(1000, 9999)  # NOT cryptographically secure

# GOOD - Cryptographically secure
import secrets
token = secrets.token_urlsafe(32)
```

### 13. Weak Cryptography

```bash
# BAD
echo "password" | md5sum  # MD5 is broken

# GOOD
echo "password" | sha256sum
# Better: Use bcrypt, scrypt, or Argon2 for passwords
```

## Security Review Checklist

- [ ] No hardcoded credentials or secrets
- [ ] All user input is validated and sanitized
- [ ] No command injection vulnerabilities
- [ ] No SQL injection vulnerabilities
- [ ] Secure communication (HTTPS, SSH)
- [ ] Proper error handling without information disclosure
- [ ] Secure temporary file handling
- [ ] Appropriate file permissions
- [ ] No path traversal vulnerabilities
- [ ] Cryptographically secure random generation
- [ ] Strong cryptographic algorithms
- [ ] Proper authentication and authorization
- [ ] Secure session management
- [ ] Protection against CSRF/XSS (for web interfaces)
- [ ] Rate limiting and DoS protection
- [ ] Secure logging (no sensitive data in logs)
- [ ] Dependencies are up-to-date and scanned for vulnerabilities
- [ ] Principle of least privilege applied
- [ ] Security headers configured (for web services)
- [ ] Input size limits enforced

## DevOps-Specific Security Concerns

### CI/CD Pipeline Security

- Validate all pipeline inputs
- Use signed commits
- Scan container images for vulnerabilities
- Secure artifact storage
- Implement approval gates for production deployments

### Infrastructure as Code

- No secrets in IaC files
- Use encrypted state files (Terraform)
- Implement policy as code (OPA, Sentinel)
- Version control for all infrastructure changes

### Container Security

- Use minimal base images
- Run as non-root user
- Scan images for vulnerabilities
- Implement resource limits
- Use read-only filesystems where possible

### Kubernetes Security

- Use RBAC properly
- Enable Pod Security Standards
- Network policies for isolation
- Secrets management (not ConfigMaps)
- Regular security audits
