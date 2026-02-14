---
name: nginx-config
description: Nginx 配置生成与审查工具。帮助生成反向代理、负载均衡、SSL、限流等 Nginx 配置，审查现有配置的安全性和性能问题。当用户需要：(1) 生成 Nginx 反向代理配置，(2) 配置负载均衡，(3) 配置 SSL/TLS 和 HTTPS，(4) 设置限流/限速/访问控制，(5) 审查现有 Nginx 配置的问题，(6) 优化 Nginx 性能参数，(7) 配置 WebSocket 代理，(8) 配置静态文件服务和缓存时使用。触发条件："nginx"、"反向代理"、"负载均衡"、"nginx配置"、"ssl配置"、"限流配置"、"nginx优化"。
---

# Nginx 配置

## 配置生成流程

1. 确认需求场景（反向代理/负载均衡/静态服务/SSL）
2. 收集参数（域名、后端地址、端口、证书路径）
3. 生成配置
4. 提供测试命令

## 反向代理配置

### 基础反向代理

```nginx
upstream backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### 负载均衡

```nginx
upstream backend {
    # 轮询（默认）
    server 10.0.0.1:8080;
    server 10.0.0.2:8080;

    # 加权轮询
    # server 10.0.0.1:8080 weight=3;
    # server 10.0.0.2:8080 weight=1;

    # IP 哈希（会话保持）
    # ip_hash;

    # 最少连接
    # least_conn;

    # 健康检查（被动）
    server 10.0.0.1:8080 max_fails=3 fail_timeout=30s;
    server 10.0.0.2:8080 max_fails=3 fail_timeout=30s;
}
```

### WebSocket 代理

```nginx
location /ws {
    proxy_pass http://backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 3600s;
}
```

## SSL/TLS 配置

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate     /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # 协议和加密套件
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;

    # SSL 优化
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}
```

## 限流配置

```nginx
# 在 http 块中定义
http {
    # 按 IP 限制请求速率（每秒 10 个请求）
    limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;

    # 按 IP 限制并发连接数
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
}

server {
    # 应用请求限速（突发允许 20 个排队）
    location /api/ {
        limit_req zone=req_limit burst=20 nodelay;
        limit_req_status 429;
    }

    # 应用连接数限制
    location /download/ {
        limit_conn conn_limit 5;
        limit_rate 1m;  # 每连接限速 1MB/s
    }
}
```

## 静态文件和缓存

```nginx
# 静态文件服务
location /static/ {
    alias /var/www/static/;
    expires 30d;
    add_header Cache-Control "public, immutable";

    # 开启 gzip
    gzip on;
    gzip_types text/css application/javascript image/svg+xml;
    gzip_min_length 1024;
}

# 代理缓存
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;

location /api/ {
    proxy_pass http://backend;
    proxy_cache my_cache;
    proxy_cache_valid 200 10m;
    proxy_cache_valid 404 1m;
    add_header X-Cache-Status $upstream_cache_status;
}
```

## 安全配置

```nginx
# 安全响应头
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;

# 隐藏版本号
server_tokens off;

# 限制请求体大小
client_max_body_size 10m;

# IP 访问控制
location /admin/ {
    allow 10.0.0.0/8;
    deny all;
}

# 禁止访问隐藏文件
location ~ /\. {
    deny all;
    access_log off;
    log_not_found off;
}
```

## 性能优化参数

```nginx
# worker 进程数（通常等于 CPU 核数）
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 10240;
    use epoll;
    multi_accept on;
}

http {
    # 文件传输优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    # 超时设置
    keepalive_timeout 65;
    keepalive_requests 1000;
    client_body_timeout 10;
    client_header_timeout 10;
    send_timeout 10;

    # 缓冲区
    client_body_buffer_size 16k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 8k;

    # 开启 gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 4;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml image/svg+xml;
}
```

## 配置审查清单

审查 Nginx 配置时检查：

1. **安全性**：是否隐藏版本号、是否有安全响应头、SSL 配置是否安全
2. **性能**：worker 数量、连接数、keepalive、gzip、缓存
3. **代理头**：是否传递 X-Real-IP、X-Forwarded-For
4. **超时**：各项超时是否合理
5. **日志**：access_log 和 error_log 是否配置
6. **限流**：是否有请求速率和连接数限制
7. **错误处理**：是否配置自定义错误页面
8. **HTTPS**：是否强制 HTTPS、证书是否有效

## 常用运维命令

```bash
# 测试配置语法
nginx -t
# 重新加载配置（不中断服务）
nginx -s reload
# 查看编译参数和模块
nginx -V
# 查看当前连接状态（需 stub_status 模块）
curl http://localhost/nginx_status
```
