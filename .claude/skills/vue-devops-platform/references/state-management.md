# Pinia 状态管理规范

## Store 定义规范

### 用户状态 Store (src/stores/user.ts)

```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { login, logout, getUserInfo } from '@/api/modules/auth'
import type { UserInfo, LoginParams } from '@/types/business'
import { removeToken, setToken } from '@/utils/storage'

export const useUserStore = defineStore('user', () => {
  // State
  const token = ref<string>('')
  const userInfo = ref<UserInfo | null>(null)
  const permissions = ref<string[]>([])
  const roles = ref<string[]>([])

  // Getters
  const isLoggedIn = computed(() => !!token.value)
  const userName = computed(() => userInfo.value?.name || '')
  const hasPermission = computed(() => {
    return (permission: string) => permissions.value.includes(permission)
  })
  const hasRole = computed(() => {
    return (role: string) => roles.value.includes(role)
  })

  // Actions
  const setUserToken = (newToken: string) => {
    token.value = newToken
    setToken(newToken)
  }

  const setUserInfo = (info: UserInfo) => {
    userInfo.value = info
    permissions.value = info.permissions || []
    roles.value = info.roles || []
  }

  const loginAction = async (params: LoginParams) => {
    try {
      const data = await login(params)
      setUserToken(data.token)
      await fetchUserInfo()
      return data
    } catch (error) {
      console.error('登录失败:', error)
      throw error
    }
  }

  const fetchUserInfo = async () => {
    try {
      const data = await getUserInfo()
      setUserInfo(data)
      return data
    } catch (error) {
      console.error('获取用户信息失败:', error)
      throw error
    }
  }

  const logoutAction = async () => {
    try {
      await logout()
    } catch (error) {
      console.error('登出失败:', error)
    } finally {
      // 清除本地状态
      token.value = ''
      userInfo.value = null
      permissions.value = []
      roles.value = []
      removeToken()
    }
  }

  const resetStore = () => {
    token.value = ''
    userInfo.value = null
    permissions.value = []
    roles.value = []
  }

  return {
    // State
    token,
    userInfo,
    permissions,
    roles,
    // Getters
    isLoggedIn,
    userName,
    hasPermission,
    hasRole,
    // Actions
    setUserToken,
    setUserInfo,
    loginAction,
    fetchUserInfo,
    logoutAction,
    resetStore
  }
}, {
  persist: {
    key: 'user-store',
    storage: localStorage,
    paths: ['token', 'userInfo'] // 只持久化部分状态
  }
})
```

### 应用全局状态 Store (src/stores/app.ts)

```typescript
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
  // 侧边栏状态
  const sidebarCollapsed = ref(false)
  const sidebarWidth = ref(200)

  // 主题设置
  const theme = ref<'light' | 'dark'>('light')

  // 语言设置
  const locale = ref<'zh-CN' | 'en-US'>('zh-CN')

  // 页面加载状态
  const pageLoading = ref(false)

  // 全局配置
  const config = ref({
    apiBaseUrl: '',
    wsBaseUrl: '',
    enableDebug: false
  })

  // Actions
  const toggleSidebar = () => {
    sidebarCollapsed.value = !sidebarCollapsed.value
    sidebarWidth.value = sidebarCollapsed.value ? 64 : 200
  }

  const setSidebarCollapsed = (collapsed: boolean) => {
    sidebarCollapsed.value = collapsed
    sidebarWidth.value = collapsed ? 64 : 200
  }

  const setTheme = (newTheme: 'light' | 'dark') => {
    theme.value = newTheme
    document.documentElement.setAttribute('data-theme', newTheme)
  }

  const setLocale = (newLocale: 'zh-CN' | 'en-US') => {
    locale.value = newLocale
  }

  const setPageLoading = (loading: boolean) => {
    pageLoading.value = loading
  }

  const setConfig = (newConfig: Partial<typeof config.value>) => {
    config.value = { ...config.value, ...newConfig }
  }

  return {
    // State
    sidebarCollapsed,
    sidebarWidth,
    theme,
    locale,
    pageLoading,
    config,
    // Actions
    toggleSidebar,
    setSidebarCollapsed,
    setTheme,
    setLocale,
    setPageLoading,
    setConfig
  }
}, {
  persist: {
    key: 'app-store',
    storage: localStorage,
    paths: ['sidebarCollapsed', 'theme', 'locale']
  }
})
```

### 权限状态 Store (src/stores/permission.ts)

```typescript
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { RouteRecordRaw } from 'vue-router'
import { useUserStore } from './user'

export const usePermissionStore = defineStore('permission', () => {
  const routes = ref<RouteRecordRaw[]>([])
  const dynamicRoutes = ref<RouteRecordRaw[]>([])
  const menuList = ref<any[]>([])

  // 生成路由
  const generateRoutes = async () => {
    const userStore = useUserStore()
    const roles = userStore.roles

    // 根据角色过滤路由
    const accessedRoutes = filterRoutesByRoles(asyncRoutes, roles)
    dynamicRoutes.value = accessedRoutes
    routes.value = constantRoutes.concat(accessedRoutes)

    return accessedRoutes
  }

  // 生成菜单
  const generateMenus = () => {
    menuList.value = filterMenus(routes.value)
    return menuList.value
  }

  // 重置路由
  const resetRoutes = () => {
    routes.value = []
    dynamicRoutes.value = []
    menuList.value = []
  }

  return {
    routes,
    dynamicRoutes,
    menuList,
    generateRoutes,
    generateMenus,
    resetRoutes
  }
})

// 根据角色过滤路由
function filterRoutesByRoles(routes: RouteRecordRaw[], roles: string[]): RouteRecordRaw[] {
  const result: RouteRecordRaw[] = []

  routes.forEach(route => {
    const tmp = { ...route }
    if (hasPermission(roles, tmp)) {
      if (tmp.children) {
        tmp.children = filterRoutesByRoles(tmp.children, roles)
      }
      result.push(tmp)
    }
  })

  return result
}

// 检查权限
function hasPermission(roles: string[], route: RouteRecordRaw): boolean {
  if (route.meta?.roles) {
    return roles.some(role => route.meta!.roles!.includes(role))
  }
  return true
}

// 过滤菜单
function filterMenus(routes: RouteRecordRaw[]): any[] {
  return routes
    .filter(route => !route.meta?.hidden)
    .map(route => ({
      path: route.path,
      name: route.name,
      title: route.meta?.title,
      icon: route.meta?.icon,
      children: route.children ? filterMenus(route.children) : undefined
    }))
}
```

## Store 使用规范

### 在组件中使用

```vue
<script setup lang="ts">
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'
import { storeToRefs } from 'pinia'

// 获取 store 实例
const userStore = useUserStore()
const appStore = useAppStore()

// 使用 storeToRefs 保持响应式
const { userInfo, isLoggedIn } = storeToRefs(userStore)
const { theme, sidebarCollapsed } = storeToRefs(appStore)

// 调用 actions
const handleLogin = async () => {
  await userStore.loginAction({
    username: 'admin',
    password: '123456'
  })
}

const toggleTheme = () => {
  const newTheme = theme.value === 'light' ? 'dark' : 'light'
  appStore.setTheme(newTheme)
}
</script>
```

### 在路由守卫中使用

```typescript
import { useUserStore } from '@/stores/user'
import { usePermissionStore } from '@/stores/permission'

router.beforeEach(async (to, from, next) => {
  const userStore = useUserStore()
  const permissionStore = usePermissionStore()

  if (userStore.isLoggedIn) {
    if (to.path === '/login') {
      next({ path: '/' })
    } else {
      // 检查是否已生成路由
      if (permissionStore.routes.length === 0) {
        try {
          const accessRoutes = await permissionStore.generateRoutes()
          accessRoutes.forEach(route => {
            router.addRoute(route)
          })
          next({ ...to, replace: true })
        } catch (error) {
          await userStore.logoutAction()
          next(`/login?redirect=${to.path}`)
        }
      } else {
        next()
      }
    }
  } else {
    if (whiteList.includes(to.path)) {
      next()
    } else {
      next(`/login?redirect=${to.path}`)
    }
  }
})
```

## 状态持久化

使用 `pinia-plugin-persistedstate` 插件：

```typescript
// src/main.ts
import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'

const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)

app.use(pinia)
```

配置持久化选项：

```typescript
export const useUserStore = defineStore('user', () => {
  // ... store 定义
}, {
  persist: {
    key: 'user-store',              // 存储键名
    storage: localStorage,           // 存储方式
    paths: ['token', 'userInfo'],   // 需要持久化的字段
    beforeRestore: (ctx) => {       // 恢复前钩子
      console.log('恢复状态前')
    },
    afterRestore: (ctx) => {        // 恢复后钩子
      console.log('恢复状态后')
    }
  }
})
```

## Store 组织最佳实践

### 1. 按业务模块划分

```
stores/
├── user.ts           # 用户相关
├── permission.ts     # 权限相关
├── app.ts           # 应用全局状态
├── cluster.ts       # 集群管理
├── pod.ts           # Pod 管理
└── monitor.ts       # 监控数据
```

### 2. 避免过度使用 Store

不是所有状态都需要放在 Store 中：
- **需要 Store**：跨组件共享、需要持久化、全局配置
- **不需要 Store**：组件内部状态、临时数据、表单数据

### 3. 合理拆分 Store

- 单一职责：每个 Store 只负责一个业务领域
- 避免循环依赖：Store 之间的依赖关系要清晰
- 适当粒度：不要过度拆分，也不要全部放在一个 Store

### 4. 命名规范

- Store 文件：小写 + 连字符（如 `user-profile.ts`）
- Store ID：小写 + 连字符（如 `'user-profile'`）
- State：名词（如 `userInfo`, `clusterList`）
- Getters：`is/has/get` 前缀（如 `isLoggedIn`, `hasPermission`）
- Actions：动词（如 `fetchData`, `updateUser`, `deleteCluster`）

## 性能优化

### 1. 使用 storeToRefs

```typescript
// ❌ 错误：失去响应式
const { userInfo } = userStore

// ✅ 正确：保持响应式
const { userInfo } = storeToRefs(userStore)
```

### 2. 按需导入

```typescript
// ❌ 避免：导入整个 store
import { useUserStore } from '@/stores/user'
const userStore = useUserStore()
console.log(userStore.userInfo)

// ✅ 推荐：只导入需要的状态
import { useUserStore } from '@/stores/user'
import { storeToRefs } from 'pinia'
const { userInfo } = storeToRefs(useUserStore())
```

### 3. 避免在 Store 中存储大量数据

对于列表数据，考虑使用分页和虚拟滚动，不要一次性加载所有数据到 Store。

## 调试技巧

### 1. 使用 Vue DevTools

Pinia 完全支持 Vue DevTools，可以查看和修改 Store 状态。

### 2. 添加日志

```typescript
export const useUserStore = defineStore('user', () => {
  const loginAction = async (params: LoginParams) => {
    console.log('[UserStore] 开始登录', params)
    try {
      const data = await login(params)
      console.log('[UserStore] 登录成功', data)
      setUserToken(data.token)
      return data
    } catch (error) {
      console.error('[UserStore] 登录失败', error)
      throw error
    }
  }

  return { loginAction }
})
```

### 3. 订阅 Store 变化

```typescript
const userStore = useUserStore()

userStore.$subscribe((mutation, state) => {
  console.log('Store 变化:', mutation.type)
  console.log('新状态:', state)
})
```
