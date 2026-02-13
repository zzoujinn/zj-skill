---
name: devops-code-review
description: 专业的运维开发代码审核工具，支持Shell、Python和Go代码审查。关注性能优化、代码质量、安全性和最佳实践。适用场景：(1) 审核部署脚本和CI/CD代码，(2) 审核监控告警脚本，(3) 审核运维自动化工具，(4) 审核基础设施即代码(IaC)，(5) 代码提交前的质量检查。触发条件包括："review this code"、"code review"、"check for bugs"、"analyze this code"、"审核代码"、"代码审查"、"检查问题"等。
---

# DevOps Code Review

## Overview

本skill提供专业的运维开发代码审核能力，针对Shell、Python和Go三种主要运维开发语言，从性能优化、代码质量、安全性和最佳实践四个维度进行全面审查。

## Review Workflow

### 1. 识别代码类型和场景

首先确定代码的语言和使用场景：

**语言识别**：
- Shell脚本 (.sh, .bash) - 查看 [references/shell-review.md](references/shell-review.md)
- Python代码 (.py) - 查看 [references/python-review.md](references/python-review.md)
- Go代码 (.go) - 查看 [references/go-review.md](references/go-review.md)

**场景识别**：
- 部署脚本：CI/CD流水线、自动化部署、版本发布
- 监控告警：指标采集、日志分析、告警处理
- 运维工具：系统管理、资源调度、配置管理
- 基础设施代码：Terraform、Ansible、Kubernetes配置

### 2. 执行多维度审查

按以下优先级进行审查：

#### 2.1 安全性审查（最高优先级）

参考 [references/security-checklist.md](references/security-checklist.md) 检查：
- 命令注入漏洞
- 权限管理问题
- 敏感信息泄露
- 输入验证缺失
- 不安全的依赖

#### 2.2 性能优化审查

参考 [references/performance-checklist.md](references/performance-checklist.md) 检查：
- 资源使用效率
- 并发处理能力
- 算法复杂度
- 网络I/O优化
- 缓存策略

#### 2.3 代码质量审查

检查代码规范和可维护性：
- 命名规范
- 代码结构
- 错误处理
- 日志记录
- 注释文档

#### 2.4 最佳实践审查

检查是否遵循语言和领域的最佳实践：
- 语言特定的惯用法
- 运维领域的通用模式
- 可测试性
- 可观测性

### 3. 生成审查报告

审查报告应包含：

**报告结构**：
```
## 代码审查报告

### 概述
- 代码类型：[Shell/Python/Go]
- 使用场景：[部署/监控/工具/基础设施]
- 代码规模：[行数/文件数]

### 严重问题（Critical）
[必须立即修复的问题，如安全漏洞]

### 重要问题（High）
[应该尽快修复的问题，如性能瓶颈]

### 一般问题（Medium）
[建议修复的问题，如代码规范]

### 优化建议（Low）
[可选的改进建议]

### 优点
[代码中做得好的地方]

### 总体评分
- 安全性：[1-10分]
- 性能：[1-10分]
- 质量：[1-10分]
- 最佳实践：[1-10分]
```

## Quick Start Examples

### Example 1: 审查Shell部署脚本

```bash
# 用户请求
"请审查这个部署脚本，检查是否有安全问题"

# 审查流程
1. 识别为Shell脚本 + 部署场景
2. 读取 references/shell-review.md
3. 读取 references/security-checklist.md
4. 执行审查并生成报告
```

### Example 2: 审查Python监控脚本

```python
# 用户请求
"帮我review这个监控脚本的性能"

# 审查流程
1. 识别为Python代码 + 监控场景
2. 读取 references/python-review.md
3. 读取 references/performance-checklist.md
4. 执行审查并生成报告
```

### Example 3: 审查Go运维工具

```go
// 用户请求
"检查这个Go工具的代码质量"

// 审查流程
1. 识别为Go代码 + 运维工具场景
2. 读取 references/go-review.md
3. 执行全面审查
4. 生成报告
```

## Review Principles

### 1. 安全优先原则

运维代码通常具有高权限，安全问题可能导致严重后果。始终将安全性放在首位。

### 2. 生产环境意识

运维代码直接影响生产系统稳定性。审查时考虑：
- 故障影响范围
- 回滚能力
- 监控和告警
- 错误恢复

### 3. 可维护性原则

运维代码需要长期维护和迭代。重视：
- 代码可读性
- 文档完整性
- 测试覆盖率
- 模块化设计

### 4. 实用主义

平衡理想与现实，提供可执行的建议：
- 区分必须修复和建议改进
- 考虑修复成本和收益
- 提供具体的修改方案

## Advanced Features

### 批量审查

当需要审查多个文件时：
1. 先审查核心/关键文件
2. 识别共性问题
3. 提供整体改进建议

### 对比审查

当审查代码变更时：
1. 对比新旧代码差异
2. 评估变更影响
3. 检查是否引入新问题

### 持续改进

基于审查结果：
1. 识别团队常见问题
2. 建议制定编码规范
3. 推荐自动化检查工具

## Tools and Automation

推荐的自动化检查工具：

**Shell**:
- shellcheck - 静态分析工具
- shfmt - 代码格式化

**Python**:
- pylint - 代码质量检查
- black - 代码格式化
- bandit - 安全漏洞扫描
- mypy - 类型检查

**Go**:
- golangci-lint - 综合检查工具
- go vet - 官方静态分析
- gosec - 安全扫描

## Notes

- 审查报告应该具体、可执行，避免泛泛而谈
- 提供代码示例说明问题和解决方案
- 考虑代码的实际运行环境和约束
- 尊重现有代码风格，除非有明显问题
