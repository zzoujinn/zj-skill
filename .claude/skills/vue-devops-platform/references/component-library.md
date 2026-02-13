# 常用组件库和使用指南

## 公共组件

### PageHeader - 页面头部组件

```vue
<!-- src/components/common/PageHeader/index.vue -->
<script setup lang="ts">
interface Props {
  title: string
  subtitle?: string
  showBack?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showBack: false
})

const emit = defineEmits<{
  (e: 'back'): void
}>()

const handleBack = () => {
  emit('back')
}
</script>

<template>
  <div class="page-header">
    <div class="page-header__left">
      <el-button
        v-if="showBack"
        link
        icon="ArrowLeft"
        @click="handleBack"
      >
        返回
      </el-button>
      <div class="page-header__title">
        <h2>{{ title }}</h2>
        <span v-if="subtitle" class="subtitle">{{ subtitle }}</span>
      </div>
    </div>
    <div class="page-header__right">
      <slot name="extra" />
    </div>
  </div>
</template>

<style scoped lang="scss">
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 0;
  margin-bottom: 16px;

  &__left {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  &__title {
    h2 {
      margin: 0;
      font-size: 20px;
      font-weight: 600;
      line-height: 28px;
    }

    .subtitle {
      color: var(--el-text-color-secondary);
      font-size: 14px;
    }
  }

  &__right {
    display: flex;
    gap: 8px;
  }
}
</style>
```

**使用示例：**

```vue
<template>
  <div>
    <PageHeader
      title="集群列表"
      subtitle="共 10 个集群"
      show-back
      @back="handleBack"
    >
      <template #extra>
        <el-button type="primary" icon="Plus">
          创建集群
        </el-button>
      </template>
    </PageHeader>
  </div>
</template>
```

### SearchForm - 搜索表单组件

```vue
<!-- src/components/common/SearchForm/index.vue -->
<script setup lang="ts">
import { ref } from 'vue'

interface Props {
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

const emit = defineEmits<{
  (e: 'search'): void
  (e: 'reset'): void
}>()

const collapsed = ref(false)

const handleSearch = () => {
  emit('search')
}

const handleReset = () => {
  emit('reset')
}

const toggleCollapse = () => {
  collapsed.value = !collapsed.value
}
</script>

<template>
  <div class="search-form">
    <el-form :inline="true" label-width="80px">
      <slot />

      <el-form-item>
        <el-button
          type="primary"
          icon="Search"
          :loading="loading"
          @click="handleSearch"
        >
          搜索
        </el-button>
        <el-button icon="Refresh" @click="handleReset">
          重置
        </el-button>
        <el-button
          v-if="$slots.extra"
          link
          @click="toggleCollapse"
        >
          {{ collapsed ? '展开' : '收起' }}
          <el-icon>
            <component :is="collapsed ? 'ArrowDown' : 'ArrowUp'" />
          </el-icon>
        </el-button>
      </el-form-item>

      <div v-if="!collapsed && $slots.extra" class="search-form__extra">
        <slot name="extra" />
      </div>
    </el-form>
  </div>
</template>

<style scoped lang="scss">
.search-form {
  padding: 16px;
  background: var(--el-bg-color);
  border-radius: 4px;
  margin-bottom: 16px;

  &__extra {
    width: 100%;
  }
}
</style>
```

**使用示例：**

```vue
<template>
  <SearchForm :loading="loading" @search="handleSearch" @reset="handleReset">
    <el-form-item label="集群名称">
      <el-input v-model="searchForm.name" placeholder="请输入" clearable />
    </el-form-item>

    <el-form-item label="状态">
      <el-select v-model="searchForm.status" placeholder="请选择" clearable>
        <el-option label="运行中" value="running" />
        <el-option label="已停止" value="stopped" />
      </el-select>
    </el-form-item>

    <template #extra>
      <el-form-item label="创建时间">
        <el-date-picker
          v-model="searchForm.dateRange"
          type="daterange"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
        />
      </el-form-item>
    </template>
  </SearchForm>
</template>
```

### DataTable - 数据表格组件

```vue
<!-- src/components/common/DataTable/index.vue -->
<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  data: any[]
  total: number
  loading?: boolean
  page?: number
  pageSize?: number
  pageSizes?: number[]
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  page: 1,
  pageSize: 20,
  pageSizes: () => [10, 20, 50, 100]
})

const emit = defineEmits<{
  (e: 'update:page', value: number): void
  (e: 'update:pageSize', value: number): void
  (e: 'refresh'): void
}>()

const currentPage = computed({
  get: () => props.page,
  set: (val) => emit('update:page', val)
})

const currentPageSize = computed({
  get: () => props.pageSize,
  set: (val) => emit('update:pageSize', val)
})

const handleSizeChange = (val: number) => {
  currentPageSize.value = val
  emit('refresh')
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  emit('refresh')
}
</script>

<template>
  <div class="data-table">
    <el-table
      :data="data"
      v-loading="loading"
      border
      stripe
      style="width: 100%"
    >
      <slot />
    </el-table>

    <div class="data-table__pagination">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="currentPageSize"
        :page-sizes="pageSizes"
        :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.data-table {
  &__pagination {
    display: flex;
    justify-content: flex-end;
    margin-top: 16px;
  }
}
</style>
```

**使用示例：**

```vue
<template>
  <DataTable
    :data="tableData"
    :total="total"
    :loading="loading"
    v-model:page="page"
    v-model:page-size="pageSize"
    @refresh="fetchData"
  >
    <el-table-column prop="name" label="集群名称" />
    <el-table-column prop="status" label="状态">
      <template #default="{ row }">
        <el-tag :type="getStatusType(row.status)">
          {{ row.status }}
        </el-tag>
      </template>
    </el-table-column>
    <el-table-column label="操作" width="200">
      <template #default="{ row }">
        <el-button link type="primary" @click="handleView(row)">
          查看
        </el-button>
        <el-button link type="primary" @click="handleEdit(row)">
          编辑
        </el-button>
        <el-button link type="danger" @click="handleDelete(row)">
          删除
        </el-button>
      </template>
    </el-table-column>
  </DataTable>
</template>
```

## 业务组件

### PodStatus - Pod 状态组件

```vue
<!-- src/components/business/PodStatus/index.vue -->
<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  status: 'Running' | 'Pending' | 'Failed' | 'Succeeded' | 'Unknown'
  showIcon?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showIcon: true
})

const statusConfig = computed(() => {
  const configs = {
    Running: { type: 'success', icon: 'CircleCheck', text: '运行中' },
    Pending: { type: 'warning', icon: 'Clock', text: '等待中' },
    Failed: { type: 'danger', icon: 'CircleClose', text: '失败' },
    Succeeded: { type: 'success', icon: 'Select', text: '成功' },
    Unknown: { type: 'info', icon: 'QuestionFilled', text: '未知' }
  }
  return configs[props.status] || configs.Unknown
})
</script>

<template>
  <el-tag :type="statusConfig.type">
    <el-icon v-if="showIcon">
      <component :is="statusConfig.icon" />
    </el-icon>
    {{ statusConfig.text }}
  </el-tag>
</template>
```

### MetricChart - 监控图表组件

```vue
<!-- src/components/business/MetricChart/index.vue -->
<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import * as echarts from 'echarts'

interface Props {
  title: string
  data: any[]
  type?: 'line' | 'bar' | 'pie'
  height?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'line',
  height: '300px'
})

const chartRef = ref<HTMLDivElement>()
let chartInstance: echarts.ECharts | null = null

const initChart = () => {
  if (!chartRef.value) return

  chartInstance = echarts.init(chartRef.value)

  const option = {
    title: {
      text: props.title,
      left: 'center'
    },
    tooltip: {
      trigger: 'axis'
    },
    xAxis: {
      type: 'category',
      data: props.data.map(item => item.name)
    },
    yAxis: {
      type: 'value'
    },
    series: [
      {
        type: props.type,
        data: props.data.map(item => item.value),
        smooth: true
      }
    ]
  }

  chartInstance.setOption(option)
}

onMounted(() => {
  initChart()
  window.addEventListener('resize', () => {
    chartInstance?.resize()
  })
})

watch(() => props.data, () => {
  initChart()
}, { deep: true })
</script>

<template>
  <div ref="chartRef" :style="{ height }" />
</template>
```

## Composables 组合式函数

### useTable - 表格逻辑复用

```typescript
// src/composables/useTable.ts
import { ref, reactive } from 'vue'

interface TableOptions<T = any> {
  fetchApi: (params: any) => Promise<{ list: T[]; total: number }>
  immediate?: boolean
}

export function useTable<T = any>(options: TableOptions<T>) {
  const { fetchApi, immediate = true } = options

  const loading = ref(false)
  const tableData = ref<T[]>([])
  const total = ref(0)

  const pagination = reactive({
    page: 1,
    pageSize: 20
  })

  const searchForm = reactive<Record<string, any>>({})

  const fetchData = async () => {
    loading.value = true
    try {
      const params = {
        page: pagination.page,
        pageSize: pagination.pageSize,
        ...searchForm
      }
      const { list, total: totalCount } = await fetchApi(params)
      tableData.value = list
      total.value = totalCount
    } catch (error) {
      console.error('获取数据失败:', error)
    } finally {
      loading.value = false
    }
  }

  const handleSearch = () => {
    pagination.page = 1
    fetchData()
  }

  const handleReset = () => {
    Object.keys(searchForm).forEach(key => {
      searchForm[key] = undefined
    })
    pagination.page = 1
    fetchData()
  }

  const handleRefresh = () => {
    fetchData()
  }

  if (immediate) {
    fetchData()
  }

  return {
    loading,
    tableData,
    total,
    pagination,
    searchForm,
    fetchData,
    handleSearch,
    handleReset,
    handleRefresh
  }
}
```

**使用示例：**

```vue
<script setup lang="ts">
import { useTable } from '@/composables/useTable'
import { getClusterList } from '@/api/modules/cluster'

const {
  loading,
  tableData,
  total,
  pagination,
  searchForm,
  handleSearch,
  handleReset,
  handleRefresh
} = useTable({
  fetchApi: getClusterList
})

// 扩展搜索表单
searchForm.name = ''
searchForm.status = ''
</script>
```

### useForm - 表单逻辑复用

```typescript
// src/composables/useForm.ts
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'

interface FormOptions<T = any> {
  initialValues?: Partial<T>
  rules?: FormRules
  createApi?: (data: T) => Promise<any>
  updateApi?: (id: string, data: T) => Promise<any>
  onSuccess?: () => void
}

export function useForm<T extends Record<string, any>>(options: FormOptions<T>) {
  const {
    initialValues = {},
    rules = {},
    createApi,
    updateApi,
    onSuccess
  } = options

  const formRef = ref<FormInstance>()
  const loading = ref(false)
  const isEdit = ref(false)
  const formData = reactive<T>({ ...initialValues } as T)

  const setFormData = (data: Partial<T>) => {
    Object.assign(formData, data)
  }

  const resetForm = () => {
    formRef.value?.resetFields()
    Object.assign(formData, initialValues)
  }

  const validate = async (): Promise<boolean> => {
    if (!formRef.value) return false
    try {
      await formRef.value.validate()
      return true
    } catch {
      return false
    }
  }

  const handleSubmit = async () => {
    const valid = await validate()
    if (!valid) return

    loading.value = true
    try {
      if (isEdit.value && updateApi) {
        await updateApi(formData.id, formData)
        ElMessage.success('更新成功')
      } else if (createApi) {
        await createApi(formData)
        ElMessage.success('创建成功')
      }
      onSuccess?.()
    } catch (error) {
      console.error('提交失败:', error)
    } finally {
      loading.value = false
    }
  }

  return {
    formRef,
    formData,
    loading,
    isEdit,
    rules,
    setFormData,
    resetForm,
    validate,
    handleSubmit
  }
}
```

**使用示例：**

```vue
<script setup lang="ts">
import { useForm } from '@/composables/useForm'
import { createCluster, updateCluster } from '@/api/modules/cluster'

const {
  formRef,
  formData,
  loading,
  isEdit,
  rules,
  handleSubmit
} = useForm({
  initialValues: {
    name: '',
    version: '',
    namespace: 'default'
  },
  rules: {
    name: [{ required: true, message: '请输入集群名称', trigger: 'blur' }],
    version: [{ required: true, message: '请选择版本', trigger: 'change' }]
  },
  createApi: createCluster,
  updateApi: updateCluster,
  onSuccess: () => {
    router.push('/cluster/list')
  }
})
</script>

<template>
  <el-form ref="formRef" :model="formData" :rules="rules" label-width="100px">
    <el-form-item label="集群名称" prop="name">
      <el-input v-model="formData.name" />
    </el-form-item>

    <el-form-item label="版本" prop="version">
      <el-select v-model="formData.version">
        <el-option label="1.28" value="1.28" />
        <el-option label="1.29" value="1.29" />
      </el-select>
    </el-form-item>

    <el-form-item>
      <el-button type="primary" :loading="loading" @click="handleSubmit">
        提交
      </el-button>
    </el-form-item>
  </el-form>
</template>
```

## 工具函数

### 格式化工具 (src/utils/format.ts)

```typescript
// 格式化时间
export function formatTime(time: string | number | Date, format = 'YYYY-MM-DD HH:mm:ss'): string {
  // 使用 dayjs 或其他日期库
  return dayjs(time).format(format)
}

// 格式化文件大小
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`
}

// 格式化数字
export function formatNumber(num: number): string {
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

// 格式化百分比
export function formatPercent(value: number, total: number): string {
  if (total === 0) return '0%'
  return `${((value / total) * 100).toFixed(2)}%`
}
```

### 验证工具 (src/utils/validate.ts)

```typescript
// 验证 IP 地址
export function isValidIP(ip: string): boolean {
  const reg = /^(\d{1,3}\.){3}\d{1,3}$/
  if (!reg.test(ip)) return false
  return ip.split('.').every(num => parseInt(num) <= 255)
}

// 验证端口号
export function isValidPort(port: number): boolean {
  return port >= 1 && port <= 65535
}

// 验证 K8s 资源名称
export function isValidK8sName(name: string): boolean {
  const reg = /^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/
  return reg.test(name) && name.length <= 253
}

// 验证 URL
export function isValidURL(url: string): boolean {
  try {
    new URL(url)
    return true
  } catch {
    return false
  }
}
```
