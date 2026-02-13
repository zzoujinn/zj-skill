<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { mockClusters } from '../../mock/data'

const loading = ref(false)
const timeRange = ref('1h')
const autoRefresh = ref(false)

const timeRangeOptions = [
  { label: '最近 1 小时', value: '1h' },
  { label: '最近 6 小时', value: '6h' },
  { label: '最近 24 小时', value: '24h' },
  { label: '最近 7 天', value: '7d' },
  { label: '最近 30 天', value: '30d' }
]

// Computed statistics from mock data
const runningClusters = mockClusters.filter(c => c.status === 'running')
const statistics = ref({
  totalClusters: mockClusters.length,
  runningClusters: runningClusters.length,
  totalNodes: mockClusters.reduce((sum, c) => sum + c.nodeCount, 0),
  totalPods: mockClusters.reduce((sum, c) => sum + c.podCount, 0),
  cpuUsage: 68.5,
  memoryUsage: 72.3,
  diskUsage: 45.8,
  networkTraffic: 1024
})

let cpuChart: echarts.ECharts | null = null
let memoryChart: echarts.ECharts | null = null
let podChart: echarts.ECharts | null = null
let clusterChart: echarts.ECharts | null = null
let refreshTimer: ReturnType<typeof setInterval> | null = null

const generateTimeLabels = () => {
  const labels: string[] = []
  for (let i = 19; i >= 0; i--) {
    labels.push(`${i}m ago`)
  }
  return labels
}

const generateRandomData = (count: number, min: number, max: number) => {
  return Array.from({ length: count }, () =>
    Math.floor(Math.random() * (max - min + 1)) + min
  )
}

const initCpuChart = () => {
  const dom = document.getElementById('cpu-chart')
  if (!dom) return
  cpuChart = echarts.init(dom)
  cpuChart.setOption({
    title: { text: 'CPU 使用率趋势', left: 'center', textStyle: { fontSize: 14, fontWeight: 'normal' } },
    tooltip: { trigger: 'axis', formatter: '{b}<br/>{a}: {c}%' },
    xAxis: { type: 'category', boundaryGap: false, data: generateTimeLabels() },
    yAxis: { type: 'value', max: 100, axisLabel: { formatter: '{value}%' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    series: [{
      name: 'CPU',
      type: 'line',
      smooth: true,
      data: generateRandomData(20, 50, 85),
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(64,158,255,0.5)' },
          { offset: 1, color: 'rgba(64,158,255,0.05)' }
        ])
      },
      lineStyle: { color: '#409EFF' },
      itemStyle: { color: '#409EFF' }
    }]
  })
}

const initMemoryChart = () => {
  const dom = document.getElementById('memory-chart')
  if (!dom) return
  memoryChart = echarts.init(dom)
  memoryChart.setOption({
    title: { text: '内存使用率趋势', left: 'center', textStyle: { fontSize: 14, fontWeight: 'normal' } },
    tooltip: { trigger: 'axis', formatter: '{b}<br/>{a}: {c}%' },
    xAxis: { type: 'category', boundaryGap: false, data: generateTimeLabels() },
    yAxis: { type: 'value', max: 100, axisLabel: { formatter: '{value}%' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    series: [{
      name: '内存',
      type: 'line',
      smooth: true,
      data: generateRandomData(20, 55, 90),
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(103,194,58,0.5)' },
          { offset: 1, color: 'rgba(103,194,58,0.05)' }
        ])
      },
      lineStyle: { color: '#67C23A' },
      itemStyle: { color: '#67C23A' }
    }]
  })
}

const initPodChart = () => {
  const dom = document.getElementById('pod-chart')
  if (!dom) return
  podChart = echarts.init(dom)
  podChart.setOption({
    title: { text: 'Pod 状态分布', left: 'center', textStyle: { fontSize: 14, fontWeight: 'normal' } },
    tooltip: { trigger: 'item', formatter: '{a}<br/>{b}: {c} ({d}%)' },
    legend: { orient: 'vertical', left: 'left', top: 'middle' },
    series: [{
      name: 'Pod 状态',
      type: 'pie',
      radius: ['40%', '70%'],
      avoidLabelOverlap: false,
      itemStyle: { borderRadius: 10, borderColor: '#fff', borderWidth: 2 },
      label: { show: false, position: 'center' },
      emphasis: { label: { show: true, fontSize: 18, fontWeight: 'bold' } },
      labelLine: { show: false },
      data: [
        { value: 275, name: 'Running', itemStyle: { color: '#67C23A' } },
        { value: 18, name: 'Pending', itemStyle: { color: '#E6A23C' } },
        { value: 8, name: 'Failed', itemStyle: { color: '#F56C6C' } },
        { value: 6, name: 'Succeeded', itemStyle: { color: '#409EFF' } }
      ]
    }]
  })
}

const initClusterChart = () => {
  const dom = document.getElementById('cluster-chart')
  if (!dom) return
  clusterChart = echarts.init(dom)

  const topClusters = mockClusters
    .filter(c => c.status === 'running')
    .slice(0, 6)

  clusterChart.setOption({
    title: { text: '集群资源分布', left: 'center', textStyle: { fontSize: 14, fontWeight: 'normal' } },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    legend: { data: ['CPU', '内存', '磁盘'], top: 30 },
    xAxis: {
      type: 'category',
      data: topClusters.map(c => c.name.replace(/-cluster|-/, '\n')),
      axisLabel: { interval: 0, fontSize: 10 }
    },
    yAxis: { type: 'value', max: 100, axisLabel: { formatter: '{value}%' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    series: [
      { name: 'CPU', type: 'bar', data: topClusters.map(c => c.cpuUsage), itemStyle: { color: '#409EFF' } },
      { name: '内存', type: 'bar', data: topClusters.map(c => c.memoryUsage), itemStyle: { color: '#67C23A' } },
      { name: '磁盘', type: 'bar', data: topClusters.map(c => c.diskUsage), itemStyle: { color: '#E6A23C' } }
    ]
  })
}

const initCharts = () => {
  initCpuChart()
  initMemoryChart()
  initPodChart()
  initClusterChart()
}

const refreshData = async () => {
  loading.value = true
  try {
    await new Promise(resolve => setTimeout(resolve, 400))
    statistics.value = {
      ...statistics.value,
      cpuUsage: Math.random() * 30 + 50,
      memoryUsage: Math.random() * 25 + 60,
      diskUsage: Math.random() * 20 + 35,
      networkTraffic: Math.random() * 500 + 800
    }
    initCharts()
  } finally {
    loading.value = false
  }
}

const handleAutoRefreshChange = (val: boolean) => {
  if (val) {
    refreshTimer = setInterval(refreshData, 30000)
  } else if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
}

const handleResize = () => {
  cpuChart?.resize()
  memoryChart?.resize()
  podChart?.resize()
  clusterChart?.resize()
}

onMounted(() => {
  initCharts()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  if (refreshTimer) clearInterval(refreshTimer)
  window.removeEventListener('resize', handleResize)
  cpuChart?.dispose()
  memoryChart?.dispose()
  podChart?.dispose()
  clusterChart?.dispose()
})
</script>

<template>
  <div class="dashboard" v-loading="loading">
    <!-- Header -->
    <div class="page-header">
      <div class="page-header__left">
        <h2 class="page-header__title">监控面板</h2>
        <span class="page-header__subtitle">实时监控集群运行状态</span>
      </div>
      <div class="page-header__right">
        <el-select v-model="timeRange" style="width: 140px; margin-right: 8px" @change="refreshData">
          <el-option v-for="item in timeRangeOptions" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
        <el-switch v-model="autoRefresh" active-text="自动刷新" style="margin-right: 8px" @change="handleAutoRefreshChange" />
        <el-button :icon="'Refresh'" @click="refreshData">刷新</el-button>
      </div>
    </div>

    <!-- Statistics cards -->
    <el-row :gutter="16" class="section-row">
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-card__content">
            <div class="stat-card__icon" style="background-color: #ecf5ff">
              <el-icon :size="28" color="#409EFF"><Coin /></el-icon>
            </div>
            <div class="stat-card__info">
              <div class="stat-card__value">{{ statistics.totalClusters }}</div>
              <div class="stat-card__label">集群总数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-card__content">
            <div class="stat-card__icon" style="background-color: #f0f9eb">
              <el-icon :size="28" color="#67C23A"><CircleCheck /></el-icon>
            </div>
            <div class="stat-card__info">
              <div class="stat-card__value">{{ statistics.runningClusters }}</div>
              <div class="stat-card__label">运行中集群</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-card__content">
            <div class="stat-card__icon" style="background-color: #fdf6ec">
              <el-icon :size="28" color="#E6A23C"><Monitor /></el-icon>
            </div>
            <div class="stat-card__info">
              <div class="stat-card__value">{{ statistics.totalNodes }}</div>
              <div class="stat-card__label">节点总数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-card__content">
            <div class="stat-card__icon" style="background-color: #f4f4f5">
              <el-icon :size="28" color="#909399"><Box /></el-icon>
            </div>
            <div class="stat-card__info">
              <div class="stat-card__value">{{ statistics.totalPods }}</div>
              <div class="stat-card__label">Pod 总数</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Resource usage -->
    <el-row :gutter="16" class="section-row">
      <el-col :span="6">
        <el-card shadow="hover" class="usage-card">
          <el-progress
            type="dashboard"
            :percentage="Number(statistics.cpuUsage.toFixed(1))"
            :color="statistics.cpuUsage > 80 ? '#F56C6C' : '#409EFF'"
            :stroke-width="10"
          >
            <template #default="{ percentage }">
              <span class="usage-value">{{ percentage }}%</span>
              <span class="usage-label">CPU</span>
            </template>
          </el-progress>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="usage-card">
          <el-progress
            type="dashboard"
            :percentage="Number(statistics.memoryUsage.toFixed(1))"
            :color="statistics.memoryUsage > 80 ? '#F56C6C' : '#67C23A'"
            :stroke-width="10"
          >
            <template #default="{ percentage }">
              <span class="usage-value">{{ percentage }}%</span>
              <span class="usage-label">内存</span>
            </template>
          </el-progress>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="usage-card">
          <el-progress
            type="dashboard"
            :percentage="Number(statistics.diskUsage.toFixed(1))"
            :color="statistics.diskUsage > 80 ? '#F56C6C' : '#E6A23C'"
            :stroke-width="10"
          >
            <template #default="{ percentage }">
              <span class="usage-value">{{ percentage }}%</span>
              <span class="usage-label">磁盘</span>
            </template>
          </el-progress>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover" class="usage-card">
          <div class="network-stat">
            <el-icon :size="32" color="#409EFF"><Connection /></el-icon>
            <div class="network-stat__value">{{ statistics.networkTraffic.toFixed(0) }}</div>
            <div class="network-stat__unit">MB/s</div>
            <div class="network-stat__label">网络流量</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Charts -->
    <el-row :gutter="16" class="section-row">
      <el-col :span="12">
        <el-card shadow="hover">
          <div id="cpu-chart" style="width: 100%; height: 300px"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="hover">
          <div id="memory-chart" style="width: 100%; height: 300px"></div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="section-row">
      <el-col :span="12">
        <el-card shadow="hover">
          <div id="pod-chart" style="width: 100%; height: 300px"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="hover">
          <div id="cluster-chart" style="width: 100%; height: 300px"></div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped>
.dashboard {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header__title {
  font-size: 20px;
  font-weight: 600;
  color: #303133;
  margin: 0;
}

.page-header__subtitle {
  font-size: 13px;
  color: #909399;
  margin-left: 12px;
}

.page-header__right {
  display: flex;
  align-items: center;
}

.section-row {
  margin-bottom: 16px;
}

.stat-card :deep(.el-card__body) {
  padding: 20px;
}

.stat-card__content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-card__icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-card__value {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  line-height: 1.2;
}

.stat-card__label {
  font-size: 13px;
  color: #909399;
  margin-top: 4px;
}

.usage-card :deep(.el-card__body) {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 20px;
}

.usage-value {
  display: block;
  font-size: 22px;
  font-weight: 700;
  color: #303133;
}

.usage-label {
  display: block;
  font-size: 13px;
  color: #909399;
  margin-top: 2px;
}

.network-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 16px 0;
}

.network-stat__value {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
}

.network-stat__unit {
  font-size: 12px;
  color: #909399;
}

.network-stat__label {
  font-size: 13px;
  color: #909399;
  margin-top: 4px;
}
</style>
