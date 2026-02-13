# API 接口规范

## Axios 实例配置

### 基础配置 (src/api/request.ts)

```typescript
import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse, AxiosError } from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'

// API 响应统一格式
export interface ApiResponse<T = any> {
  code: number
  data: T
  message: string
  timestamp: number
}

// 创建 Axios 实例
const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
service.interceptors.request.use(
  (config: AxiosRequestConfig) => {
    const userStore = useUserStore()

    // 添加 Token
    if (userStore.token) {
      config.headers = config.headers || {}
      config.headers['Authorization'] = `Bearer ${userStore.token}`
    }

    // 添加请求 ID（用于追踪）
    config.headers['X-Request-ID'] = generateRequestId()

    return config
  },
  (error: AxiosError) => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
service.interceptors.response.use(
  (response: AxiosResponse<ApiResponse>) => {
    const { code, data, message } = response.data

    // 成功响应
    if (code === 0 || code === 200) {
      return data
    }

    // 业务错误
    ElMessage.error(message || '请求失败')
    return Promise.reject(new Error(message || '请求失败'))
  },
  (error: AxiosError<ApiResponse>) => {
    // HTTP 错误处理
    if (error.response) {
      const { status, data } = error.response

      switch (status) {
        case 401:
          ElMessage.error('未授权，请重新登录')
          // 跳转登录页
          useUserStore().logout()
          break
        case 403:
          ElMessage.error('权限不足')
          break
        case 404:
          ElMessage.error('请求的资源不存在')
          break
        case 500:
          ElMessage.error('服务器错误')
          break
        default:
          ElMessage.error(data?.message || '请求失败')
      }
    } else if (error.request) {
      ElMessage.error('网络错误，请检查网络连接')
    } else {
      ElMessage.error('请求配置错误')
    }

    return Promise.reject(error)
  }
)

// 生成请求 ID
function generateRequestId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}

export default service
```

## API 模块定义规范

### 模块文件结构 (src/api/modules/cluster.ts)

```typescript
import request from '../request'
import type {
  ClusterInfo,
  ClusterListParams,
  ClusterCreateParams,
  ClusterUpdateParams
} from '@/types/business'

// API 路径常量
const API = {
  LIST: '/clusters',
  DETAIL: '/clusters/:id',
  CREATE: '/clusters',
  UPDATE: '/clusters/:id',
  DELETE: '/clusters/:id',
  NODES: '/clusters/:id/nodes',
  METRICS: '/clusters/:id/metrics'
}

// 集群列表
export function getClusterList(params: ClusterListParams) {
  return request<{
    list: ClusterInfo[]
    total: number
  }>({
    url: API.LIST,
    method: 'get',
    params
  })
}

// 集群详情
export function getClusterDetail(id: string) {
  return request<ClusterInfo>({
    url: API.DETAIL.replace(':id', id),
    method: 'get'
  })
}

// 创建集群
export function createCluster(data: ClusterCreateParams) {
  return request<ClusterInfo>({
    url: API.CREATE,
    method: 'post',
    data
  })
}

// 更新集群
export function updateCluster(id: string, data: ClusterUpdateParams) {
  return request<ClusterInfo>({
    url: API.UPDATE.replace(':id', id),
    method: 'put',
    data
  })
}

// 删除集群
export function deleteCluster(id: string) {
  return request<void>({
    url: API.DELETE.replace(':id', id),
    method: 'delete'
  })
}

// 获取集群节点
export function getClusterNodes(id: string) {
  return request<any[]>({
    url: API.NODES.replace(':id', id),
    method: 'get'
  })
}

// 获取集群监控指标
export function getClusterMetrics(id: string, timeRange: string) {
  return request<any>({
    url: API.METRICS.replace(':id', id),
    method: 'get',
    params: { timeRange }
  })
}
```

## 类型定义规范

### API 参数类型 (src/types/business.d.ts)

```typescript
// 集群信息
export interface ClusterInfo {
  id: string
  name: string
  version: string
  status: 'running' | 'stopped' | 'error' | 'pending'
  nodeCount: number
  podCount: number
  namespace: string
  apiServer: string
  createdAt: string
  updatedAt: string
  labels?: Record<string, string>
  annotations?: Record<string, string>
}

// 列表查询参数
export interface ClusterListParams {
  page: number
  pageSize: number
  keyword?: string
  status?: string
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}

// 创建参数
export interface ClusterCreateParams {
  name: string
  version: string
  namespace: string
  apiServer: string
  labels?: Record<string, string>
  annotations?: Record<string, string>
}

// 更新参数
export interface ClusterUpdateParams {
  name?: string
  labels?: Record<string, string>
  annotations?: Record<string, string>
}
```

## 错误处理最佳实践

### 组件中的错误处理

```typescript
import { ElMessage, ElMessageBox } from 'element-plus'
import { getClusterDetail, deleteCluster } from '@/api/modules/cluster'

// 1. 数据加载错误处理
const loading = ref(false)
const clusterData = ref<ClusterInfo | null>(null)

const fetchData = async () => {
  loading.value = true
  try {
    clusterData.value = await getClusterDetail(props.clusterId)
  } catch (error) {
    console.error('加载集群详情失败:', error)
    ElMessage.error('加载失败，请稍后重试')
    // 可选：返回上一页或显示空状态
  } finally {
    loading.value = false
  }
}

// 2. 操作确认和错误处理
const handleDelete = async (id: string) => {
  try {
    await ElMessageBox.confirm(
      '确定要删除该集群吗？此操作不可恢复。',
      '删除确认',
      {
        type: 'warning',
        confirmButtonText: '确定',
        cancelButtonText: '取消'
      }
    )

    await deleteCluster(id)
    ElMessage.success('删除成功')
    // 刷新列表或跳转
    await fetchData()
  } catch (error) {
    if (error === 'cancel') {
      // 用户取消操作
      return
    }
    console.error('删除失败:', error)
    ElMessage.error('删除失败，请稍后重试')
  }
}
```

## 请求优化

### 1. 请求取消（防止重复请求）

```typescript
import { ref, onUnmounted } from 'vue'
import axios, { CancelTokenSource } from 'axios'

const cancelToken = ref<CancelTokenSource | null>(null)

const fetchData = async () => {
  // 取消之前的请求
  if (cancelToken.value) {
    cancelToken.value.cancel('新请求已发起')
  }

  cancelToken.value = axios.CancelToken.source()

  try {
    const data = await request({
      url: '/api/data',
      cancelToken: cancelToken.value.token
    })
    // 处理数据
  } catch (error) {
    if (axios.isCancel(error)) {
      console.log('请求已取消')
    }
  }
}

onUnmounted(() => {
  if (cancelToken.value) {
    cancelToken.value.cancel('组件已卸载')
  }
})
```

### 2. 请求防抖

```typescript
import { useDebounceFn } from '@vueuse/core'

const searchKeyword = ref('')

const debouncedSearch = useDebounceFn(async () => {
  await fetchData()
}, 500)

watch(searchKeyword, () => {
  debouncedSearch()
})
```

### 3. 并发请求控制

```typescript
// 批量获取数据
const fetchMultipleData = async (ids: string[]) => {
  try {
    const results = await Promise.all(
      ids.map(id => getClusterDetail(id))
    )
    return results
  } catch (error) {
    console.error('批量获取失败:', error)
    throw error
  }
}

// 限制并发数量
const fetchWithLimit = async (ids: string[], limit = 5) => {
  const results: ClusterInfo[] = []

  for (let i = 0; i < ids.length; i += limit) {
    const batch = ids.slice(i, i + limit)
    const batchResults = await Promise.all(
      batch.map(id => getClusterDetail(id))
    )
    results.push(...batchResults)
  }

  return results
}
```

## WebSocket 集成（实时数据）

```typescript
// src/api/websocket.ts
export class WebSocketClient {
  private ws: WebSocket | null = null
  private reconnectTimer: number | null = null
  private heartbeatTimer: number | null = null

  constructor(private url: string) {}

  connect() {
    this.ws = new WebSocket(this.url)

    this.ws.onopen = () => {
      console.log('WebSocket 连接成功')
      this.startHeartbeat()
    }

    this.ws.onmessage = (event) => {
      const data = JSON.parse(event.data)
      // 处理消息
    }

    this.ws.onerror = (error) => {
      console.error('WebSocket 错误:', error)
    }

    this.ws.onclose = () => {
      console.log('WebSocket 连接关闭')
      this.reconnect()
    }
  }

  private startHeartbeat() {
    this.heartbeatTimer = window.setInterval(() => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ type: 'ping' }))
      }
    }, 30000)
  }

  private reconnect() {
    this.reconnectTimer = window.setTimeout(() => {
      console.log('尝试重新连接...')
      this.connect()
    }, 5000)
  }

  disconnect() {
    if (this.heartbeatTimer) clearInterval(this.heartbeatTimer)
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer)
    this.ws?.close()
  }
}
```
