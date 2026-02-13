---
name: vue-devops-platform
description: Vue 3 + Element Plus 运维开发平台规范和代码生成工具。专注于 K8s 管理、工具集成等运维平台开发场景。当用户需要创建运维平台页面、组件或需要遵循运维开发规范时使用。适用场景：(1) 创建资源管理页面（列表、详情、表单），(2) 生成监控面板和图表，(3) 实现 API 集成和错误处理，(4) 配置路由和权限管理，(5) 遵循 TypeScript + Composition API 编码规范。
---

# Vue DevOps 运维开发平台规范

## 概述

本规范为运维开发平台（K8s 管理、工具集成等）提供标准化的 Vue 3 + Element Plus + TypeScript 开发指南，包括项目结构、编码规范、常见页面模板和最佳实践。

## 技术栈

- **框架**: Vue 3.4+ (Composition API)
- **UI 组件库**: Element Plus 2.5+
- **语言**: TypeScript 5.0+
- **状态管理**: Pinia 2.1+
- **路由**: Vue Router 4.2+
- **HTTP 客户端**: Axios 1.6+
- **构建工具**: Vite 5.0+

## 项目结构规范

```
src/
├── api/                    # API 接口定义
│   ├── modules/           # 按业务模块划分
│   │   ├── cluster.ts    # K8s 集群相关接口
│   │   ├── pod.ts        # Pod 管理接口
│   │   └── deployment.ts # Deployment 接口
│   ├── request.ts        # Axios 封装和拦截器
│   └── types.ts          # API 通用类型定义
├── assets/                # 静态资源
│   ├── icons/            # SVG 图标
│   └── styles/           # 全局样式
│       ├── variables.scss # SCSS 变量
│       └── common.scss   # 通用样式
├── components/            # 公共组件
│   ├── common/           # 通用组件
│   │   ├── PageHeader/   # 页面头部
│   │   ├── SearchForm/   # 搜索表单
│   │   └── DataTable/    # 数据表格
│   └── business/         # 业务组件
│       ├── PodStatus/    # Pod 状态组件
│       └── MetricChart/  # 监控图表
├── composables/           # 组合式函数
│   ├── useTable.ts       # 表格逻辑复用
│   ├── useForm.ts        # 表单逻辑复用
│   └── usePermission.ts  # 权限判断
├── layouts/               # 布局组件
│   ├── DefaultLayout.vue # 默认布局
│   └── BlankLayout.vue   # 空白布局
├── router/                # 路由配置
│   ├── index.ts          # 路由主文件
│   └── modules/          # 路由模块
│       ├── cluster.ts    # 集群管理路由
│       └── monitor.ts    # 监控路由
├── stores/                # Pinia 状态管理
│   ├── user.ts           # 用户状态
│   ├── permission.ts     # 权限状态
│   └── app.ts            # 应用全局状态
├── types/                 # TypeScript 类型定义
│   ├── api.d.ts          # API 响应类型
│   ├── common.d.ts       # 通用类型
│   └── business.d.ts     # 业务类型
├── utils/                 # 工具函数
│   ├── format.ts         # 格式化工具
│   ├── validate.ts       # 验证工具
│   └── storage.ts        # 本地存储封装
├── views/                 # 页面视图
│   ├── cluster/          # 集群管理
│   │   ├── list.vue     # 列表页
│   │   ├── detail.vue   # 详情页
│   │   └── form.vue     # 创建/编辑表单
│   └── monitor/          # 监控面板
│       └── dashboard.vue
├── App.vue               # 根组件
└── main.ts               # 入口文件
```

## 核心编码规范

### 1. 组件编写规范

使用 `<script setup>` + TypeScript：

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import type { ClusterInfo } from '@/types/business'

// Props 定义
interface Props {
  clusterId: string
  readonly?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  readonly: false
})

// Emits 定义
interface Emits {
  (e: 'update', data: ClusterInfo): void
  (e: 'delete', id: string): void
}

const emit = defineEmits<Emits>()

// 响应式数据
const loading = ref(false)
const clusterData = ref<ClusterInfo | null>(null)

// 计算属性
const isHealthy = computed(() => {
  return clusterData.value?.status === 'running'
})

// 方法
const fetchData = async () => {
  loading.value = true
  try {
    // API 调用
  } finally {
    loading.value = false
  }
}

// 生命周期
onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="cluster-info">
    <el-card v-loading="loading">
      <!-- 内容 -->
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.cluster-info {
  // 样式
}
</style>
```

### 2. API 接口规范

详见 `references/api-standards.md`

### 3. 状态管理规范

详见 `references/state-management.md`

### 4. 路由和权限规范

详见 `references/router-permission.md`

## 常见页面模板

### 资源列表页

使用 `assets/templates/list-page/` 模板，包含：
- 搜索表单
- 操作按钮（新建、批量删除等）
- 数据表格（分页、排序、筛选）
- 状态标签和操作列

### 资源详情页

使用 `assets/templates/detail-page/` 模板，包含：
- 页面头部（返回、标题、操作按钮）
- 基本信息卡片
- 详细配置展示
- 关联资源列表

### 表单页面

使用 `assets/templates/form-page/` 模板，包含：
- 表单验证
- 动态表单项
- 提交和取消操作
- 错误提示

### 监控面板

使用 `assets/templates/dashboard-page/` 模板，包含：
- 指标卡片
- 图表组件（ECharts 集成）
- 时间范围选择
- 自动刷新

## 命名规范

### 文件命名
- 组件文件：PascalCase（如 `PodList.vue`）
- 工具文件：camelCase（如 `formatTime.ts`）
- 类型文件：camelCase + `.d.ts`（如 `api.d.ts`）

### 变量命名
- 普通变量：camelCase（如 `clusterName`）
- 常量：UPPER_SNAKE_CASE（如 `API_BASE_URL`）
- 类型/接口：PascalCase（如 `ClusterInfo`）
- 组合式函数：use 前缀（如 `useTable`）

### CSS 类名
- BEM 命名法：`block__element--modifier`
- 示例：`pod-list__item--active`

## 代码质量要求

1. **类型安全**：所有 API 响应、Props、Emits 必须定义类型
2. **错误处理**：所有异步操作必须有 try-catch 和用户友好的错误提示
3. **加载状态**：异步操作必须显示 loading 状态
4. **权限控制**：操作按钮和路由必须进行权限判断
5. **响应式设计**：支持常见分辨率（1920x1080, 1366x768）
6. **无障碍访问**：重要操作提供键盘快捷键

## 性能优化建议

1. 使用 `v-memo` 优化列表渲染
2. 大数据表格使用虚拟滚动
3. 图片使用懒加载
4. 路由懒加载
5. 合理使用 `computed` 缓存计算结果
6. 避免在模板中使用复杂表达式

## 安全规范

1. **XSS 防护**：用户输入必须转义，使用 `v-text` 而非 `v-html`
2. **CSRF 防护**：请求携带 CSRF Token
3. **敏感信息**：不在前端存储密码、密钥等敏感信息
4. **权限验证**：前后端双重验证，前端权限仅用于 UI 控制

## 资源文件

- `references/api-standards.md` - API 接口规范详解
- `references/state-management.md` - Pinia 状态管理规范
- `references/router-permission.md` - 路由和权限配置规范
- `references/component-library.md` - 常用组件库和使用指南
- `assets/templates/` - 页面模板文件
