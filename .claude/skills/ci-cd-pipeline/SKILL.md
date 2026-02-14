---
name: ci-cd-pipeline
description: CI/CD 流水线配置工具。帮助编写和优化 GitLab CI、GitHub Actions、Jenkins 等 CI/CD 流水线配置，包含构建、测试、部署各阶段的最佳实践。当用户需要：(1) 编写 GitLab CI (.gitlab-ci.yml) 配置，(2) 编写 GitHub Actions workflow，(3) 编写 Jenkinsfile，(4) 优化流水线执行效率，(5) 配置自动化测试和部署流程，(6) 审查现有 CI/CD 配置时使用。触发条件："ci/cd"、"流水线"、"pipeline"、"gitlab-ci"、"github actions"、"jenkins"、"自动化部署"、"持续集成"、"持续部署"。
---

# CI/CD 流水线配置

## 流水线设计流程

1. 确定 CI/CD 平台（GitLab CI / GitHub Actions / Jenkins）
2. 明确流水线阶段（构建 → 测试 → 扫描 → 部署）
3. 确定部署策略（直接部署/蓝绿/金丝雀/滚动更新）
4. 配置环境变量和密钥管理
5. 设置触发条件和分支策略

## GitLab CI

### 基础模板

```yaml
stages:
  - build
  - test
  - scan
  - deploy

variables:
  DOCKER_REGISTRY: registry.example.com
  IMAGE_NAME: ${DOCKER_REGISTRY}/${CI_PROJECT_PATH}
  IMAGE_TAG: ${CI_COMMIT_SHORT_SHA}

# 构建镜像
build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
    - docker push ${IMAGE_NAME}:${IMAGE_TAG}
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# 单元测试
test:
  stage: test
  image: python:3.12-slim
  script:
    - pip install -r requirements-test.txt
    - pytest --junitxml=report.xml --cov=src
  artifacts:
    reports:
      junit: report.xml
    expire_in: 7 days

# 安全扫描
security-scan:
  stage: scan
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}
  allow_failure: true

# 部署到测试环境
deploy-staging:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/${CI_PROJECT_NAME} app=${IMAGE_NAME}:${IMAGE_TAG} -n staging
    - kubectl rollout status deployment/${CI_PROJECT_NAME} -n staging --timeout=300s
  environment:
    name: staging
    url: https://staging.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# 部署到生产环境（手动触发）
deploy-production:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/${CI_PROJECT_NAME} app=${IMAGE_NAME}:${IMAGE_TAG} -n production
    - kubectl rollout status deployment/${CI_PROJECT_NAME} -n production --timeout=300s
  environment:
    name: production
    url: https://example.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
```

### GitLab CI 优化技巧

```yaml
# 缓存依赖加速构建
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .cache/pip
    - node_modules/

# 并行测试
test:
  parallel: 3
  script:
    - pytest --splits 3 --group $CI_NODE_INDEX

# 仅在相关文件变更时触发
deploy:
  rules:
    - changes:
        - src/**/*
        - Dockerfile
```

## GitHub Actions

### 基础模板

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 设置 Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"

      - name: 安装依赖
        run: pip install -r requirements-test.txt

      - name: 运行测试
        run: pytest --junitxml=report.xml --cov=src

      - name: 上传测试报告
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-report
          path: report.xml

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: 登录容器仓库
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: 构建并推送镜像
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: 部署到 K8s
        uses: steebchen/kubectl@v2.0.0
        with:
          config: ${{ secrets.KUBE_CONFIG }}
          command: set image deployment/myapp app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

## Jenkins (Declarative Pipeline)

### 基础模板

```groovy
pipeline {
    agent any

    environment {
        REGISTRY = 'registry.example.com'
        IMAGE_NAME = "${REGISTRY}/${env.JOB_NAME}"
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }

    stages {
        stage('构建') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('测试') {
            steps {
                sh 'pip install -r requirements-test.txt'
                sh 'pytest --junitxml=report.xml'
            }
            post {
                always {
                    junit 'report.xml'
                }
            }
        }

        stage('部署测试环境') {
            when {
                branch 'main'
            }
            steps {
                sh "kubectl set image deployment/${env.JOB_NAME} app=${IMAGE_NAME}:${IMAGE_TAG} -n staging"
            }
        }

        stage('部署生产环境') {
            when {
                branch 'main'
            }
            input {
                message '确认部署到生产环境？'
                ok '部署'
            }
            steps {
                sh "kubectl set image deployment/${env.JOB_NAME} app=${IMAGE_NAME}:${IMAGE_TAG} -n production"
            }
        }
    }

    post {
        failure {
            // 通知（钉钉/企业微信/邮件）
            echo "流水线失败，请检查日志"
        }
    }
}
```

## 流水线审查清单

1. **构建阶段**：是否使用缓存加速、是否固定依赖版本
2. **测试阶段**：是否包含单元测试和集成测试、是否生成测试报告
3. **安全扫描**：是否包含镜像扫描、代码扫描
4. **部署策略**：生产部署是否需要手动确认、是否支持回滚
5. **密钥管理**：敏感信息是否使用 CI/CD 平台的 Secret 管理
6. **触发条件**：分支策略是否合理、是否避免不必要的执行
7. **通知机制**：失败时是否有通知
8. **产物管理**：构建产物是否设置过期时间
