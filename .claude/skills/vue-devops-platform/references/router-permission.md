# 路由和权限配置规范

## 路由配置

### 路由主文件 (src/router/index.ts)

```typescript
import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { usePermissionStore } from '@/stores/permission'
import { ElMessage } from 'element-plus'

// 常量路由（无需权限）
export const constantRoutes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: {
      title: '登录',
      hidden: true
    }
  },
  {
    path: '/404',
    name: 'NotFound',
    component: () => import('@/views/error/404.vue'),
    meta: {
      title: '404',
      hidden: true
    }
  },
  {
    path: '/',
    redirect: '/dashboard',
    component: () => import('@/layouts/DefaultLayout.vue'),
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/index.vue'),
        meta: {
          title: '仪表盘',
          icon: 'dashboard',
          affix: true // 固定标签页
        }
      }
    ]
  }
]

// 异步路由（需要权限）
export const asyncRoutes: RouteRecordRaw[] = [
  {
    path: '/cluster',
    name: 'Cluster',
    component: () => import('@/layouts/DefaultLayout.vue'),
    redirect: '/cluster/list',
    meta: {
      title: '集群管理',
      icon: 'cluster',
      roles: ['admin', 'operator'] // 角色权限
    },
    children: [
      {
        path: 'list',
        name: 'ClusterList',
        component: () => import('@/views/cluster/list.vue'),
        meta: {
          title: '集群列表',
          icon: 'list',
          permissions: ['cluster:view'] // 细粒度权限
        }
      },
      {
        path: 'detail/:id',
        name: 'ClusterDetail',
        component: () => import('@/views/cluster/detail.vue'),
        meta: {
          title: '集群详情',
          hidden: true,
          activeMenu: '/cluster/list', // 高亮菜单
          permissions: ['cluster:view']
        }
      },
      {
        path: 'create',
        name: 'ClusterCreate',
        component: () => import('@/views/cluster/form.vue'),
        meta: {
          title: '创建集群',
          hidden: true,
          activeMenu: '/cluster/list',
          permissions: ['cluster:create']
        }
      },
      {
        path: 'edit/:id',
        name: 'ClusterEdit',
        component: () => import('@/views/cluster/form.vue'),
        meta: {
          title: '编辑集群',
          hidden: true,
          activeMenu: '/cluster/list',
          permissions: ['cluster:edit']
        }
      }
    ]
  },
  {
    path: '/pod',
    name: 'Pod',
    component: () => import('@/layouts/DefaultLayout.vue'),
    redirect: '/pod/list',
    meta: {
      title: 'Pod 管理',
      icon: 'pod',
      roles: ['admin', 'operator']
    },
    children: [
      {
        path: 'list',
        name: 'PodList',
        component: () => import('@/views/pod/list.vue'),
        meta: {
          title: 'Pod 列表',
          icon: 'list',
          permissions: ['pod:view']
        }
      },
      {
        path: 'detail/:id',
        name: 'PodDetail',
        component: () => import('@/views/pod/detail.vue'),
        meta: {
          title: 'Pod 详情',
          hidden: true,
          activeMenu: '/pod/list',
          permissions: ['pod:view']
        }
      }
    ]
  },
  {
    path: '/monitor',
    name: 'Monitor',
    component: () => import('@/layouts/DefaultLayout.vue'),
    redirect: '/monitor/dashboard',
    meta: {
      title: '监控中心',
      icon: 'monitor',
      roles: ['admin', 'operator', 'viewer']
    },
    children: [
      {
        path: 'dashboard',
        name: 'MonitorDashboard',
        component: () => import('@/views/monitor/dashboard.vue'),
        meta: {
          title: '监控面板',
          icon: 'dashboard',
          permissions: ['monitor:view']
        }
      },
      {
        path: 'alert',
        name: 'MonitorAlert',
        component: () => import('@/views/monitor/alert.vue'),
        meta: {
          title: '告警管理',
          icon: 'alert',
          permissions: ['monitor:alert']
        }
      }
    ]
  },
  {
    path: '/system',
    name: 'System',
    component: () => import('@/layouts/DefaultLayout.vue'),
    redirect: '/system/user',
    meta: {
      title: '系统管理',
      icon: 'system',
      roles: ['admin']
    },
    children: [
      {
        path: 'user',
        name: 'SystemUser',
        component: () => import('@/views/system/user.vue'),
        meta: {
          title: '用户管理',
          icon: 'user',
          permissions: ['system:user']
        }
      },
      {
        path: 'role',
        name: 'SystemRole',
        component: () => import('@/views/system/role.vue'),
        meta: {
          title: '角色管理',
          icon: 'role',
          permissions: ['system:role']
        }
      },
      {
        path: 'menu',
        name: 'SystemMenu',
        component: () => import('@/views/system/menu.vue'),
        meta: {
          title: '菜单管理',
          icon: 'menu',
          permissions: ['system:menu']
        }
      }
    ]
  }
]

// 创建路由实例
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: constantRoutes,
  scrollBehavior: () => ({ top: 0 })
})

// 白名单（无需登录）
const whiteList = ['/login', '/404']

// 路由守卫
router.beforeEach(async (to, from, next) => {
  // 设置页面标题
  document.title = `${to.meta.title || ''} - 运维管理平台`

  const userStore = useUserStore()
  const permissionStore = usePermissionStore()

  if (userStore.isLoggedIn) {
    if (to.path === '/login') {
      next({ path: '/' })
    } else {
      // 检查是否已生成动态路由
      if (permissionStore.routes.length === 0) {
        try {
          // 获取用户信息（包含权限）
          await userStore.fetchUserInfo()

          // 生成可访问路由
          const accessRoutes = await permissionStore.generateRoutes()

          // 动态添加路由
          accessRoutes.forEach(route => {
            router.addRoute(route)
          })

          // 添加 404 路由（必须在最后）
          router.addRoute({
            path: '/:pathMatch(.*)*',
            redirect: '/404',
            meta: { hidden: true }
          })

          // 重新导航到目标路由
          next({ ...to, replace: true })
        } catch (error) {
          console.error('路由初始化失败:', error)
          ElMessage.error('获取权限失败，请重新登录')
          await userStore.logoutAction()
          next(`/login?redirect=${to.path}`)
        }
      } else {
        // 检查路由权限
        if (hasRoutePermission(to, userStore)) {
          next()
        } else {
          ElMessage.error('无权限访问该页面')
          next({ path: '/404' })
        }
      }
    }
  } else {
    // 未登录
    if (whiteList.includes(to.path)) {
      next()
    } else {
      next(`/login?redirect=${to.path}`)
    }
  }
})

// 检查路由权限
function hasRoutePermission(route: any, userStore: any): boolean {
  const { roles, permissions } = route.meta || {}

  // 检查角色权限
  if (roles && roles.length > 0) {
    const hasRole = userStore.roles.some((role: string) => roles.includes(role))
    if (!hasRole) return false
  }

  // 检查细粒度权限
  if (permissions && permissions.length > 0) {
    const hasPermission = permissions.some((permission: string) =>
      userStore.permissions.includes(permission)
    )
    if (!hasPermission) return false
  }

  return true
}

// 路由错误处理
router.onError((error) => {
  console.error('路由错误:', error)
  ElMessage.error('页面加载失败')
})

export default router
```

## 路由 Meta 配置说明

```typescript
interface RouteMeta {
  title: string              // 页面标题
  icon?: string             // 菜单图标
  hidden?: boolean          // 是否在菜单中隐藏
  affix?: boolean           // 是否固定在标签页
  activeMenu?: string       // 高亮的菜单路径
  noCache?: boolean         // 是否不缓存页面
  breadcrumb?: boolean      // 是否显示面包屑
  roles?: string[]          // 角色权限（粗粒度）
  permissions?: string[]    // 操作权限（细粒度）
}
```

## 权限指令

### 按钮级权限控制 (src/directives/permission.ts)

```typescript
import { Directive, DirectiveBinding } from 'vue'
import { useUserStore } from '@/stores/user'

// v-permission 指令
export const permission: Directive = {
  mounted(el: HTMLElement, binding: DirectiveBinding) {
    const { value } = binding
    const userStore = useUserStore()

    if (value && value.length > 0) {
      const permissions = userStore.permissions
      const hasPermission = value.some((permission: string) =>
        permissions.includes(permission)
      )

      if (!hasPermission) {
        el.style.display = 'none'
        // 或者直接移除元素
        // el.parentNode?.removeChild(el)
      }
    }
  }
}

// v-role 指令
export const role: Directive = {
  mounted(el: HTMLElement, binding: DirectiveBinding) {
    const { value } = binding
    const userStore = useUserStore()

    if (value && value.length > 0) {
      const roles = userStore.roles
      const hasRole = value.some((role: string) => roles.includes(role))

      if (!hasRole) {
        el.style.display = 'none'
      }
    }
  }
}

// 注册指令 (src/main.ts)
import { permission, role } from '@/directives/permission'

app.directive('permission', permission)
app.directive('role', role)
```

### 使用示例

```vue
<template>
  <div>
    <!-- 按权限显示按钮 -->
    <el-button
      v-permission="['cluster:create']"
      type="primary"
      @click="handleCreate"
    >
      创建集群
    </el-button>

    <!-- 按角色显示按钮 -->
    <el-button
      v-role="['admin']"
      type="danger"
      @click="handleDelete"
    >
      删除
    </el-button>

    <!-- 多个权限（满足任一即可） -->
    <el-button
      v-permission="['cluster:edit', 'cluster:delete']"
      @click="handleEdit"
    >
      编辑
    </el-button>
  </div>
</template>
```

## 权限判断函数

### Composable 函数 (src/composables/usePermission.ts)

```typescript
import { computed } from 'vue'
import { useUserStore } from '@/stores/user'

export function usePermission() {
  const userStore = useUserStore()

  // 检查是否有指定权限
  const hasPermission = (permissions: string | string[]): boolean => {
    const userPermissions = userStore.permissions
    const permissionArray = Array.isArray(permissions) ? permissions : [permissions]

    return permissionArray.some(permission =>
      userPermissions.includes(permission)
    )
  }

  // 检查是否有所有权限
  const hasAllPermissions = (permissions: string[]): boolean => {
    const userPermissions = userStore.permissions
    return permissions.every(permission =>
      userPermissions.includes(permission)
    )
  }

  // 检查是否有指定角色
  const hasRole = (roles: string | string[]): boolean => {
    const userRoles = userStore.roles
    const roleArray = Array.isArray(roles) ? roles : [roles]

    return roleArray.some(role => userRoles.includes(role))
  }

  // 检查是否有所有角色
  const hasAllRoles = (roles: string[]): boolean => {
    const userRoles = userStore.roles
    return roles.every(role => userRoles.includes(role))
  }

  // 是否是管理员
  const isAdmin = computed(() => hasRole('admin'))

  return {
    hasPermission,
    hasAllPermissions,
    hasRole,
    hasAllRoles,
    isAdmin
  }
}
```

### 使用示例

```vue
<script setup lang="ts">
import { usePermission } from '@/composables/usePermission'

const { hasPermission, hasRole, isAdmin } = usePermission()

// 在逻辑中判断权限
const handleOperation = () => {
  if (!hasPermission('cluster:delete')) {
    ElMessage.warning('无删除权限')
    return
  }
  // 执行删除操作
}

// 在模板中使用
const canCreate = hasPermission('cluster:create')
const canEdit = hasPermission(['cluster:edit', 'cluster:update'])
</script>

<template>
  <div>
    <el-button v-if="canCreate" @click="handleCreate">
      创建
    </el-button>

    <el-button v-if="isAdmin" type="danger">
      管理员操作
    </el-button>
  </div>
</template>
```

## 动态路由加载流程

```
1. 用户登录
   ↓
2. 获取 Token 并存储
   ↓
3. 跳转到首页
   ↓
4. 路由守卫拦截
   ↓
5. 获取用户信息（包含角色和权限）
   ↓
6. 根据角色过滤异步路由
   ↓
7. 动态添加路由到 router
   ↓
8. 生成菜单列表
   ↓
9. 放行路由导航
```

## 路由模块化

### 按业务模块拆分 (src/router/modules/cluster.ts)

```typescript
import type { RouteRecordRaw } from 'vue-router'

const clusterRoutes: RouteRecordRaw = {
  path: '/cluster',
  name: 'Cluster',
  component: () => import('@/layouts/DefaultLayout.vue'),
  redirect: '/cluster/list',
  meta: {
    title: '集群管理',
    icon: 'cluster',
    roles: ['admin', 'operator']
  },
  children: [
    {
      path: 'list',
      name: 'ClusterList',
      component: () => import('@/views/cluster/list.vue'),
      meta: {
        title: '集群列表',
        icon: 'list',
        permissions: ['cluster:view']
      }
    },
    {
      path: 'detail/:id',
      name: 'ClusterDetail',
      component: () => import('@/views/cluster/detail.vue'),
      meta: {
        title: '集群详情',
        hidden: true,
        activeMenu: '/cluster/list',
        permissions: ['cluster:view']
      }
    }
  ]
}

export default clusterRoutes
```

### 导入模块路由

```typescript
// src/router/index.ts
import clusterRoutes from './modules/cluster'
import podRoutes from './modules/pod'
import monitorRoutes from './modules/monitor'

export const asyncRoutes: RouteRecordRaw[] = [
  clusterRoutes,
  podRoutes,
  monitorRoutes
]
```

## 面包屑导航

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

const breadcrumbs = computed(() => {
  const matched = route.matched.filter(item => item.meta?.title)
  return matched.map(item => ({
    title: item.meta.title as string,
    path: item.path
  }))
})

const handleBreadcrumbClick = (path: string) => {
  router.push(path)
}
</script>

<template>
  <el-breadcrumb separator="/">
    <el-breadcrumb-item
      v-for="(item, index) in breadcrumbs"
      :key="index"
      :to="index < breadcrumbs.length - 1 ? item.path : undefined"
    >
      {{ item.title }}
    </el-breadcrumb-item>
  </el-breadcrumb>
</template>
```

## 标签页导航

```typescript
// src/stores/tagsView.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { RouteLocationNormalized } from 'vue-router'

export interface TagView {
  path: string
  name: string
  title: string
  affix?: boolean
}

export const useTagsViewStore = defineStore('tagsView', () => {
  const visitedViews = ref<TagView[]>([])

  const addView = (route: RouteLocationNormalized) => {
    if (visitedViews.value.some(v => v.path === route.path)) return

    visitedViews.value.push({
      path: route.path,
      name: route.name as string,
      title: route.meta.title as string,
      affix: route.meta.affix as boolean
    })
  }

  const delView = (view: TagView) => {
    const index = visitedViews.value.findIndex(v => v.path === view.path)
    if (index > -1) {
      visitedViews.value.splice(index, 1)
    }
  }

  const delOthersViews = (view: TagView) => {
    visitedViews.value = visitedViews.value.filter(
      v => v.affix || v.path === view.path
    )
  }

  const delAllViews = () => {
    visitedViews.value = visitedViews.value.filter(v => v.affix)
  }

  return {
    visitedViews,
    addView,
    delView,
    delOthersViews,
    delAllViews
  }
})
```
