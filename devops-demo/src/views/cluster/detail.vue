<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import * as echarts from 'echarts'
import { mockClusters, mockNodes, mockPods, mockEvents } from '../../mock/data'
import type { ClusterInfo } from '../../types/business'

const route = useRoute()
const router = useRouter()

const activeTab = ref('basic')
const loading = ref(false)

// Find cluster from mock data
const cluster = computed<ClusterInfo | undefined>(() => {
  return mockClusters.find(c => c.id === route.params.id)
})

const getStatusType = (status: string): '' | 'success' | 'info' | 'warning' | 'danger' => {
  const map: Record<string, '' | 'success' | 'info' | 'warning' | 'danger'> = {
    running: 'success',
    stopped: 'info',
    error: 'danger',
    pending: 'warning',
    Running: 'success',
    Ready: 'success',
    NotReady: 'danger',
    Pending: 'warning',
    Failed: 'danger',
    CrashLoopBackOff: 'danger',
    Succeeded: '',
    master: 'warning',
    worker: ''
  }
  return map[status] || 'info'
}

const getStatusLabel = (status: string): string => {
  const map: Record<string, string> = {
    running: '运行中',
    stopped: '已停止',
    error: '错误',
    pending: '等待中'
  }
  return map[status] || status
}

// Metrics chart
let metricsChart: echarts.ECharts | null = null

const initMetricsChart = () => {
  if (activeTab.value !== 'metrics') return
  const dom = document.getElementById('detail-metrics-chart')
  if (!dom || !cluster.value) return

  metricsChart = echarts.init(dom)
  const c = cluster.value

  metricsChart.setOption({
    tooltip: { trigger: 'item', formatter: '{b}: {c}%' },
    series: [{
      type: 'gauge',
      startAngle: 180,
      endAngle: 0,
      center: ['25%', '70%'],
      radius: '90%',
      min: 0,
      max: 100,
      splitNumber: 5,
      axisLine: {
        lineStyle: {
          width: 12,
          color: [[0.6, '#67C23A'], [0.8, '#E6A23C'], [1, '#F56C6C']]
        }
      },
      pointer: { itemStyle: { color: 'auto' } },
      axisTick: { distance: -12, length: 4, lineStyle: { color: '#fff', width: 1 } },
      splitLine: { distance: -14, length: 10, lineStyle: { color: '#fff', width: 2 } },
      axisLabel: { color: 'inherit', distance: 20, fontSize: 10 },
      detail: { valueAnimation: true, formatter: '{value}%', fontSize: 16, offsetCenter: [0, '10%'] },
      title: { offsetCenter: [0, '35%'], fontSize: 12, color: '#909399' },
      data: [{ value: c.cpuUsage.toFixed(1), name: 'CPU' }]
    }, {
      type: 'gauge',
      startAngle: 180,
      endAngle: 0,
      center: ['75%', '70%'],
      radius: '90%',
      min: 0,
      max: 100,
      splitNumber: 5,
      axisLine: {
        lineStyle: {
          width: 12,
          color: [[0.6, '#67C23A'], [0.8, '#E6A23C'], [1, '#F56C6C']]
        }
      },
      pointer: { itemStyle: { color: 'auto' } },
      axisTick: { distance: -12, length: 4, lineStyle: { color: '#fff', width: 1 } },
      splitLine: { distance: -14, length: 10, lineStyle: { color: '#fff', width: 2 } },
      axisLabel: { color: 'inherit', distance: 20, fontSize: 10 },
      detail: { valueAnimation: true, formatter: '{value}%', fontSize: 16, offsetCenter: [0, '10%'] },
      title: { offsetCenter: [0, '35%'], fontSize: 12, color: '#909399' },
      data: [{ value: c.memoryUsage.toFixed(1), name: '内存' }]
    }]
  })
}

const handleResize = () => {
  metricsChart?.resize()
}

const handleBack = () => {
  router.push('/cluster')
}

const handleRefresh = () => {
  loading.value = true
  setTimeout(() => {
    loading.value = false
    ElMessage.success('已刷新')
  }, 300)
}

onMounted(() => {
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  metricsChart?.dispose()
})
</script>

<template>
  <div class="cluster-detail" v-loading="loading">
    <!-- Not found -->
    <el-result v-if="!cluster" icon="warning" title="集群不存在" sub-title="未找到对应的集群信息">
      <template #extra>
        <el-button type="primary" @click="handleBack">返回列表</el-button>
      </template>
    </el-result>

    <template v-else>
      <!-- Header -->
      <div class="detail-header">
        <div class="detail-header__left">
          <el-button :icon="'ArrowLeft'" @click="handleBack" text>返回</el-button>
          <div class="detail-header__info">
            <div class="detail-header__title-row">
              <h2 class="detail-header__title">{{ cluster.name }}</h2>
              <el-tag :type="getStatusType(cluster.status)" size="large">
                {{ getStatusLabel(cluster.status) }}
              </el-tag>
            </div>
            <div class="detail-header__meta">
              <span>ID: {{ cluster.id }}</span>
              <el-divider direction="vertical" />
              <span>版本: {{ cluster.version }}</span>
              <el-divider direction="vertical" />
              <span>命名空间: {{ cluster.namespace }}</span>
            </div>
          </div>
        </div>
        <div class="detail-header__right">
          <el-button :icon="'Refresh'" @click="handleRefresh">刷新</el-button>
        </div>
      </div>

      <!-- Tabs -->
      <el-card shadow="never">
        <el-tabs v-model="activeTab" @tab-change="() => { if (activeTab === 'metrics') setTimeout(initMetricsChart, 100) }">
          <!-- Basic info -->
          <el-tab-pane label="基本信息" name="basic">
            <el-descriptions :column="2" border>
              <el-descriptions-item label="集群名称">{{ cluster.name }}</el-descriptions-item>
              <el-descriptions-item label="集群 ID">{{ cluster.id }}</el-descriptions-item>
              <el-descriptions-item label="K8s 版本">{{ cluster.version }}</el-descriptions-item>
              <el-descriptions-item label="状态">
                <el-tag :type="getStatusType(cluster.status)">{{ getStatusLabel(cluster.status) }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="节点数">{{ cluster.nodeCount }}</el-descriptions-item>
              <el-descriptions-item label="Pod 数">{{ cluster.podCount }}</el-descriptions-item>
              <el-descriptions-item label="命名空间">{{ cluster.namespace }}</el-descriptions-item>
              <el-descriptions-item label="API Server">{{ cluster.apiServer }}</el-descriptions-item>
              <el-descriptions-item label="创建时间">{{ cluster.createdAt }}</el-descriptions-item>
              <el-descriptions-item label="描述" :span="2">{{ cluster.description }}</el-descriptions-item>
            </el-descriptions>

            <h4 style="margin: 20px 0 12px; color: #303133">标签</h4>
            <div class="labels-area">
              <el-tag
                v-for="(value, key) in cluster.labels"
                :key="key"
                class="label-tag"
                type="info"
              >
                {{ key }}={{ value }}
              </el-tag>
            </div>

            <!-- Resource usage cards -->
            <h4 style="margin: 20px 0 12px; color: #303133">资源使用</h4>
            <el-row :gutter="16">
              <el-col :span="8">
                <el-card shadow="hover">
                  <div class="resource-item">
                    <span class="resource-item__label">CPU 使用率</span>
                    <el-progress
                      :percentage="cluster.cpuUsage"
                      :color="cluster.cpuUsage > 80 ? '#F56C6C' : '#409EFF'"
                      :stroke-width="8"
                    />
                  </div>
                </el-card>
              </el-col>
              <el-col :span="8">
                <el-card shadow="hover">
                  <div class="resource-item">
                    <span class="resource-item__label">内存使用率</span>
                    <el-progress
                      :percentage="cluster.memoryUsage"
                      :color="cluster.memoryUsage > 80 ? '#F56C6C' : '#67C23A'"
                      :stroke-width="8"
                    />
                  </div>
                </el-card>
              </el-col>
              <el-col :span="8">
                <el-card shadow="hover">
                  <div class="resource-item">
                    <span class="resource-item__label">磁盘使用率</span>
                    <el-progress
                      :percentage="cluster.diskUsage"
                      :color="cluster.diskUsage > 80 ? '#F56C6C' : '#E6A23C'"
                      :stroke-width="8"
                    />
                  </div>
                </el-card>
              </el-col>
            </el-row>
          </el-tab-pane>

          <!-- Nodes -->
          <el-tab-pane label="节点列表" name="nodes">
            <el-table :data="mockNodes" stripe border style="width: 100%">
              <el-table-column prop="name" label="节点名称" min-width="160" />
              <el-table-column prop="status" label="状态" width="100">
                <template #default="{ row }">
                  <el-tag :type="getStatusType(row.status)" size="small">{{ row.status }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="role" label="角色" width="100">
                <template #default="{ row }">
                  <el-tag :type="row.role === 'master' ? 'warning' : 'info'" size="small">{{ row.role }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="ip" label="IP 地址" width="130" />
              <el-table-column prop="os" label="操作系统" width="130" />
              <el-table-column prop="kubeletVersion" label="Kubelet 版本" width="120" />
              <el-table-column prop="cpu" label="CPU" width="100" />
              <el-table-column prop="memory" label="内存" width="100" />
            </el-table>
          </el-tab-pane>

          <!-- Pods -->
          <el-tab-pane label="Pod 列表" name="pods">
            <el-table :data="mockPods" stripe border style="width: 100%">
              <el-table-column prop="name" label="Pod 名称" min-width="280" show-overflow-tooltip />
              <el-table-column prop="namespace" label="命名空间" width="120" />
              <el-table-column prop="status" label="状态" width="140">
                <template #default="{ row }">
                  <el-tag :type="getStatusType(row.status)" size="small">{{ row.status }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="restarts" label="重启次数" width="90" align="center">
                <template #default="{ row }">
                  <span :style="{ color: row.restarts > 5 ? '#F56C6C' : 'inherit', fontWeight: row.restarts > 5 ? 'bold' : 'normal' }">
                    {{ row.restarts }}
                  </span>
                </template>
              </el-table-column>
              <el-table-column prop="age" label="运行时间" width="100" />
              <el-table-column prop="node" label="所在节点" width="150" />
              <el-table-column prop="ip" label="Pod IP" width="130" />
            </el-table>
          </el-tab-pane>

          <!-- Metrics -->
          <el-tab-pane label="监控指标" name="metrics">
            <el-row :gutter="16" style="margin-bottom: 20px">
              <el-col :span="6">
                <el-card shadow="hover" class="metric-card">
                  <div class="metric-card__label">CPU 使用率</div>
                  <div class="metric-card__value" :style="{ color: cluster.cpuUsage > 80 ? '#F56C6C' : '#409EFF' }">
                    {{ cluster.cpuUsage.toFixed(1) }}%
                  </div>
                </el-card>
              </el-col>
              <el-col :span="6">
                <el-card shadow="hover" class="metric-card">
                  <div class="metric-card__label">内存使用率</div>
                  <div class="metric-card__value" :style="{ color: cluster.memoryUsage > 80 ? '#F56C6C' : '#67C23A' }">
                    {{ cluster.memoryUsage.toFixed(1) }}%
                  </div>
                </el-card>
              </el-col>
              <el-col :span="6">
                <el-card shadow="hover" class="metric-card">
                  <div class="metric-card__label">磁盘使用率</div>
                  <div class="metric-card__value" :style="{ color: cluster.diskUsage > 80 ? '#F56C6C' : '#E6A23C' }">
                    {{ cluster.diskUsage.toFixed(1) }}%
                  </div>
                </el-card>
              </el-col>
              <el-col :span="6">
                <el-card shadow="hover" class="metric-card">
                  <div class="metric-card__label">节点数 / Pod 数</div>
                  <div class="metric-card__value" style="color: #303133">
                    {{ cluster.nodeCount }} / {{ cluster.podCount }}
                  </div>
                </el-card>
              </el-col>
            </el-row>

            <el-card shadow="hover">
              <div id="detail-metrics-chart" style="width: 100%; height: 280px"></div>
            </el-card>
          </el-tab-pane>

          <!-- Events -->
          <el-tab-pane label="事件日志" name="events">
            <el-timeline>
              <el-timeline-item
                v-for="(event, index) in mockEvents"
                :key="index"
                :timestamp="event.timestamp"
                placement="top"
                :color="event.type === 'Warning' ? '#F56C6C' : '#67C23A'"
              >
                <el-card shadow="hover" class="event-card">
                  <div class="event-card__header">
                    <el-tag :type="event.type === 'Warning' ? 'danger' : 'success'" size="small">
                      {{ event.type }}
                    </el-tag>
                    <span class="event-card__reason">{{ event.reason }}</span>
                  </div>
                  <div class="event-card__message">{{ event.message }}</div>
                </el-card>
              </el-timeline-item>
            </el-timeline>
          </el-tab-pane>
        </el-tabs>
      </el-card>
    </template>
  </div>
</template>

<style scoped>
.cluster-detail {
  padding: 20px;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  background: #fff;
  padding: 20px;
  border-radius: 4px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
}

.detail-header__left {
  display: flex;
  align-items: flex-start;
  gap: 8px;
}

.detail-header__title-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.detail-header__title {
  font-size: 20px;
  font-weight: 600;
  color: #303133;
  margin: 0;
}

.detail-header__meta {
  margin-top: 8px;
  font-size: 13px;
  color: #909399;
}

.labels-area {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.label-tag {
  font-size: 12px;
}

.resource-item {
  padding: 8px 0;
}

.resource-item__label {
  font-size: 13px;
  color: #909399;
  margin-bottom: 8px;
  display: block;
}

.metric-card :deep(.el-card__body) {
  text-align: center;
  padding: 20px;
}

.metric-card__label {
  font-size: 13px;
  color: #909399;
  margin-bottom: 8px;
}

.metric-card__value {
  font-size: 28px;
  font-weight: 700;
}

.event-card {
  margin-bottom: 0;
}

.event-card :deep(.el-card__body) {
  padding: 12px 16px;
}

.event-card__header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.event-card__reason {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.event-card__message {
  font-size: 13px;
  color: #606266;
  line-height: 1.5;
}
</style>
