import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/dashboard'
    },
    {
      path: '/dashboard',
      name: 'Dashboard',
      component: () => import('../views/dashboard/index.vue'),
      meta: { title: '监控面板', icon: 'Odometer' }
    },
    {
      path: '/cluster',
      name: 'ClusterList',
      component: () => import('../views/cluster/list.vue'),
      meta: { title: '集群管理', icon: 'Coin' }
    },
    {
      path: '/cluster/detail/:id',
      name: 'ClusterDetail',
      component: () => import('../views/cluster/detail.vue'),
      meta: { title: '集群详情', hidden: true }
    }
  ]
})

export default router
