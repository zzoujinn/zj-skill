---
name: docker-helper
description: Docker 容器化辅助工具。帮助编写和优化 Dockerfile、docker-compose 配置，进行镜像瘦身和多阶段构建，排查容器运行问题。当用户需要：(1) 编写或优化 Dockerfile，(2) 配置 docker-compose，(3) 优化镜像大小（多阶段构建、镜像瘦身），(4) 排查容器启动或运行问题，(5) 设计容器化部署方案，(6) 配置容器网络或存储时使用。触发条件："dockerfile"、"docker-compose"、"容器化"、"镜像优化"、"docker配置"、"容器排查"、"多阶段构建"。
---

# Docker 容器化辅助

## Dockerfile 编写规范

### 基础镜像选择

| 镜像类型 | 大小 | 适用场景 |
|---------|------|---------|
| alpine | ~5MB | 生产环境首选，包小但用 musl libc |
| slim | ~80MB | 需要 glibc 兼容性时 |
| distroless | ~20MB | 安全要求高，无 shell |
| 完整镜像 | ~200MB+ | 开发调试环境 |

### 分层优化原则

1. 不常变化的指令放前面（FROM、ENV、安装系统依赖）
2. 频繁变化的指令放后面（COPY 源码、RUN 编译）
3. 合并 RUN 指令减少层数
4. 每层结束清理缓存

### 多阶段构建模式

**Go 应用：**

```dockerfile
# 构建阶段
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server ./cmd/server

# 运行阶段
FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata \
    && adduser -D -u 1000 appuser
COPY --from=builder /app/server /usr/local/bin/server
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:8080/health || exit 1
ENTRYPOINT ["server"]
```

**Python 应用：**

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
RUN useradd -r -u 1000 appuser
COPY --from=builder /install /usr/local
COPY . .
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "app:app"]
```

**Node.js 应用：**

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine
WORKDIR /app
RUN adduser -D -u 1000 appuser
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "server.js"]
```

### .dockerignore 模板

```
.git
.gitignore
node_modules
__pycache__
*.pyc
.env
.env.*
docker-compose*.yml
Dockerfile*
README.md
.vscode
.idea
*.log
tmp/
dist/
build/
```

## Dockerfile 审查清单

- [ ] 基础镜像使用固定版本标签（避免 latest）
- [ ] 使用多阶段构建减小最终镜像
- [ ] RUN 指令合理合并，清理包管理器缓存
- [ ] 设置非 root 用户运行（USER）
- [ ] COPY 指令精确指定文件（避免 `COPY .`）
- [ ] 设置 HEALTHCHECK
- [ ] 暴露必要端口（EXPOSE）
- [ ] 使用 .dockerignore 排除不必要文件
- [ ] 敏感信息不硬编码（使用环境变量或 secrets）
- [ ] 安装命令包含 `--no-cache` 或清理缓存

## docker-compose 编写

### 典型三层架构示例

```yaml
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - REDIS_HOST=redis
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    restart: unless-stopped
    networks:
      - app-net

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME:-myapp}
      POSTGRES_USER: ${DB_USER:-appuser}
      POSTGRES_PASSWORD: ${DB_PASS}
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-appuser}"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped
    networks:
      - app-net

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --maxmemory 256mb
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped
    networks:
      - app-net

volumes:
  db-data:
  redis-data:

networks:
  app-net:
    driver: bridge
```

### 环境变量管理

使用 `.env` 文件管理变量，docker-compose 自动加载：

```bash
# .env
DB_NAME=myapp
DB_USER=appuser
DB_PASS=changeme
```

## 容器排查命令

```bash
# 查看容器日志
docker logs <容器> --tail 100 -f
docker logs <容器> --since 1h

# 查看容器详情
docker inspect <容器> | jq '.[0].State'
docker inspect <容器> | jq '.[0].NetworkSettings.Networks'

# 资源使用
docker stats --no-stream
docker top <容器>

# 进入容器调试
docker exec -it <容器> /bin/sh

# 文件系统变更
docker diff <容器>

# 导出容器文件系统用于分析
docker export <容器> | tar tf - | head -50

# 网络排查
docker network ls
docker network inspect <网络>

# 存储排查
docker volume ls
docker volume inspect <卷>

# 清理资源
docker system prune -f          # 清理停止的容器、悬空镜像、未使用网络
docker image prune -a -f         # 清理所有未使用的镜像
docker volume prune -f           # 清理未使用的卷
```

## 镜像优化技巧

```bash
# 查看镜像层和大小
docker history <镜像>
# 使用 dive 分析镜像层（需安装 dive）
dive <镜像>
# 安全扫描
docker scout cves <镜像>
trivy image <镜像>
```
