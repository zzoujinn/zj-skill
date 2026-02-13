<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import PageHeader from '@/components/common/PageHeader/index.vue'
import * as echarts from 'echarts'

// 时间范围选项
const timeRangeOptions = [
  { label: '最近 1 小时', value: '1h' },
  { label: '最近 6 小时', value: '6h' },
  { label: '最近 24 小时', value: '24h' },
  { label: '最近 7 天', value: '7d' },
  { label: '最近 30 天', value: '30d' }
]

const loading = ref(false)
const timeRange = ref('1h')
const autoRefresh = ref(true)
const refreshInterval = ref(30) // 秒

// 统计数据
const statistics = ref({
  totalClusters: 12,
  runningClusters: 10,
  totalNodes: 48,
  totalPods: 256,
  cpuUsage: 68.5,
  memoryUsage: 72.3,
  diskUsage: 45.8,
  networkTraffic: 1024
})

// 图表实例
let cpuChartInstance: echarts.ECharts | null = null
let memoryChartInstance: echarts.ECharts | null = null
let podChartInstance: echarts.ECharts | null = null
let clusterChartInstance: echarts.ECharts | null = null

// 定时器
let refreshTimer: number | null = null

// 初始化 CPU 使用率图表
const initCpuChart = () => {
  const chartDom = document.getElementById('cpu-chart')
  if (!chartDom) return

  cpuChartInstance = echarts.init(chartDom)

  const option = {
    title: {
      text: 'CPU 使用率趋势',
      left: 'center',
      textStyle: {
        fontSize: 14,
        fontWeight: 'normal'
      }
    },
    tooltip: {
      trigger: 'axis',
      formatter: '{b}<br/>{a}: {c}%'
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: generateTimeLabels()
    },
    yAxis: {
      type: 'value',
      max: 100,
      axisLabel: {
        formatter: '{value}%'
      }
    },
    series: [
      {
        name: 'CPU 使用率',
        type: 'line',
        smooth: true,
        data: generateRandomData(20, 50, 80),
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(64, 158, 255, 0.5)' },
            { offset: 1, color: 'rgba(64, 158, 255, 0.1)' }
          ])
        },
        lineStyle: {
          color: '#409EFF'
        },
        itemStyle: {
          color: '#409EFF'
        }
      }
    ],
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    }
  }

  cpuChartInstance.setOption(option)
}

// 初始化内存使用率图表
const initMemoryChart = () => {
  const chartDom = document.getElementById('memory-chart')
  if (!chartDom) return

  memoryChartInstance = echarts.init(chartDom)

  const option = {
    title: {
      text: '内存使用率趋势',
      left: 'center',
      textStyle: {
        fontSize: 14,
        fontWeight: 'normal'
      }
    },
    tooltip: {
      trigger: 'axis',
      formatter: '{b}<br/>{a}: {c}%'
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: generateTimeLabels()
    },
    yAxis: {
      type: 'value',
      max: 100,
      axisLabel: {
        formatter: '{value}%'
      }
    },
    series: [
      {
        name: '内存使用率',
        type: 'line',
        smooth: true,
        data: generateRandomData(20, 60, 85),
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(103, 194, 58, 0.5)' },
            { offset: 1, color: 'rgba(103, 194, 58, 0.1)' }
          ])
        },
        lineStyle: {
          color: '#67C23A'
        },
        itemStyle: {
          color: '#67C23A'
        }
      }
    ],
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    }
  }

  memoryChartInstance.setOption(option)
}

// 初始化 Pod 状态分布图表
const initPodChart = () => {
  const chartDom = document.getElementById('pod-chart')
  if (!chartDom) return

  podChartInstance = echarts.init(chartDom)

  const option = {
    title: {
      text: 'Pod 状态分布',
      left: 'center',
      textStyle: {
        fontSize: 14,
        fontWeight: 'normal'
      }
    },
    tooltip: {
      trigger: 'item',
      formatter: '{a}<br/>{b}: {c} ({d}%)'
    },
    legend: {
      orient: 'vertical',
      left: 'left',
      top: 'middle'
    },
    series: [
      {
        name: 'Pod 状态',
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false,
          position: 'center'
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 20,
            fontWeight: 'bold'
          }
        },
        labelLine: {
          show: false
        },
        data: [
          { value: 220, name: 'Running', itemStyle: { color: '#67C23A' } },
          { value: 20, name: 'Pending', itemStyle: { color: '#E6A23C' } },
          { value: 10, name: 'Failed', itemStyle: { color: '#F56C6C' } },
          { value: 6, name: 'Succeeded', itemStyle: { color: '#409EFF' } }
        ]
      }
    ]
  }

  podChartInstance.setOption(option)
}

// 初始化集群资源分布图表
const initClusterChart = () => {
  const chartDom = document.getElementById('cluster-chart')
  if (!chartDom) return

  clusterChartInstance = echarts.init(chartDom)

  const option = {
    title: {
      text: '集群资源分布',
      left: 'center',
      textStyle: {
        fontSize: 14,
        fontWeight: 'normal'
      }
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      }
    },
    legend: {
      data: ['CPU', '内存', '磁盘'],
      top: 30
    },
    xAxis: {
      type: 'category',
      data: ['集群1', '集群2', '集群3', '集群4', '集群5']
    },
    yAxis: {
      type: 'value',
      max: 100,
      axisLabel: {
        formatter: '{value}%'
      }
    },
    series: [
      {
        name: 'CPU',
        type: 'bar',
        data: [65, 72, 58, 80, 68],
        itemStyle: { color: '#409EFF' }
      },
      {
        name: '内存',
        type: 'bar',
        data: [70, 68, 75, 72, 65],
        itemStyle: { color: '#67C23A' }
      },
      {
        name: '磁盘',
        type: 'bar',
        data: [45, 52, 48, 55, 50],
        itemStyle: { color: '#E6A23C' }
      }
    ],
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    }
  }

  clusterChartInstance.setOption(option)
}

// 生成时间标签
const generateTimeLabels = () => {
  const labels = []
  for (let i = 19; i >= 0; i--) {
    labels.push(`${i}分钟前`)
  }
  return labels
}

// 生成随机数据
const generateRandomData = (count: number, min: number, max: number) => {
  const data = []
  for (let i = 0; i < count; i++) {
    data.push(Math.floor(Math.random() * (max - min + 1)) + min)
  }
  return data
}

// 初始化所有图表
const initCharts = () => {
  initCpuChart()
  initMemoryChart()
  initPodChart()
  initClusterChart()
}

// 刷新数据
const refreshData = async () => {
  loading.value = true
  try {
    // 模拟 API 调用
    await new Promise(resolve => setTimeout(resolve, 500))

    // 更新统计数据
    statistics.value = {
      totalClusters: 12,
      runningClusters: 10,
      totalNodes: 48,
      totalPods: 256,
      cpuUsage: Math.random() * 30 + 50,
      memoryUsage: Math.random() * 30 + 60,
      diskUsage: Math.random() * 20 + 40,
      networkTraffic: Math.random() * 500 + 800
    }

    // 更新图表
    initCharts()

    ElMessage.success('数据已刷新')
  } catch (error) {
    console.error('刷新数据失败:', error)
    ElMessage.error('刷新失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

// 时间范围变化
const handleTimeRangeChange = () => {
  refreshData()
}

// 自动刷新切换
const handleAutoRefreshChange = () => {
  if (autoRefresh.value) {
    startAutoRefresh()
  } else {
    stopAutoRefresh()
  }
}

// 开始自动刷新
const startAutoRefresh = () => {
  stopAutoRefresh()
  refreshTimer = window.setInterval(() => {
    refreshData()
  }, refreshInterval.value * 1000)
}

// 停止自动刷新
const stopAutoRefresh = () => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
}

// 窗口大小变化时重新渲染图表
const handleResize = () => {
  cpuChartInstance?.resize()
  memoryChartInstance?.resize()
  podChartInstance?.resize()
  clusterChartInstance?.resize()
}

onMounted(() => {
  initCharts()
  if (autoRefresh.value) {
    startAutoRefresh()
  }
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  stopAutoRefresh()
  window.removeEventListener('resize', handleResize)
  cpuChartInstance?.dispose()
  memoryChartInstance?.dispose()
  podChartInstance?.dispose()
  clusterChartInstance?.dispose()
})
</script>

<template>
  <div class="monitor-dashboard" v-loading="loading">
    <PageHeader title="监控面板" subtitle="实时监控集群运行状态">
      <template #extra>
        <el-select
          v-model="timeRange"
          placeholder="选择时间范围"
          style="width: 150px; margin-right: 8px"
          @change="handleTimeRangeChange"
        >
          <el-option
            v-for="item in timeRangeOptions"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select>

        <el-switch
          v-model="autoRefresh"
          active-text="自动刷新"
          style="margin-right: 8px"
          @change="handleAutoRefreshChange"
        />

        <el-button icon="Refresh" @click="refreshData">
          刷新
        </el-button>
      </template>
    </PageHeader>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="statistics-row">
      <el-col :span="6">
        <el-card shadow="hover" class="statistic-card">
          <el-statistic title="集群总数" :value="statistics.totalClusters">
            <template #prefix>
              <el-icon color="#409EFF" :size="24">
                <component is="Coin" />
              </el-icon>
            </template>
          </el-statistic>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover" class="statistic-card">
          <el-statistic title="运行中集群" :value="statistics.runningClusters">
            <template #prefix>
              <el-icon color="#67C23A" :size="24">
                <component is="CircleCheck" />
              </el-icon>
            </template>
          </el-statistic>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover" class="statistic-card">
          <el-statistic title="节点总数" :value="statistics.totalNodes">
            <template #prefix>
              <el-icon color="#E6A23C" :size="24">
                <component is="Monitor" />
              </el-icon>
            </template>
          </el-statistic>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover" class="statistic-card">
          <el-statistic title="Pod 总数" :value="statistics.totalPods">
            <template #prefix>
              <el-icon color="#909399" :size="24">
                <component is="Box" />
              </el-icon>
            </template>
          </el-statistic>
        </el-card>
      </el-col>
    </el-row>

    <!-- 资源使用率卡片 -->
    <el-row :gutter="16" class="usage-row">
      <el-col :span="6">
        <el-card shadow="hover">
          <el-progress
            type="dashboard"
            :percentage="statistics.cpuUsage"
            :color="statistics.cpuUsage > 80 ? '#F56C6C' : '#409EFF'"
          >
            <template #default="{ percentage }">
              <span class="percentage-value">{{ percentage }}%</span>
              <span class="percentage-label">CPU</span>
            </template>
          </el-progress>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover">
          <el-progress
            type="dashboard"
            :percentage="statistics.memoryUsage"
            :color="statistics.memoryUsage > 80 ? '#F56C6C' : '#67C23A'"
          >
            <template #default="{ percentage }">
              <span class="percentage-value">{{ percentage }}%</span>
              <span class="percentage-label">内存</span>
            </template>
          </el-progress>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover">
          <el-progress
            type="dashboard"
            :percentage="statistics.diskUsage"
            :color="statistics.diskUsage > 80 ? '#F56C6C' : '#E6A23C'"
          >
            <template #default="{ percentage }">
              <span class="percentage-value">{{ percentage }}%</span>
              <span class="percentage-label">磁盘</span>
            </template>
          </el-progress>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover">
          <el-statistic
            title="网络流量"
            :value="statistics.networkTraffic"
            suffix="MB/s"
          >
            <template #prefix>
              <el-icon color="#409EFF" :size="24">
                <component is="Connection" />
              </el-icon>
            </template>
          </el-statistic>
        </el-card>
      </el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-row :gutter="16" class="chart-row">
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

    <el-row :gutter="16" class="chart-row">
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

<style scoped lang="scss">
.monitor-dashboard {
  padding: 20px;

  .statistics-row,
  .usage-row,
  .chart-row {
    margin-bottom: 16px;
  }

  .statistic-card {
    :deep(.el-statistic) {
      .el-statistic__head {
        font-size: 14px;
        color: var(--el-text-color-secondary);
        margin-bottom: 8px;
      }

      .el-statistic__content {
        display: flex;
        align-items: center;
        gap: 8px;
      }

      .el-statistic__number {
        font-size: 28px;
        font-weight: 600;
      }
    }
  }

  .percentage-value {
    display: block;
    font-size: 24px;
    font-weight: 600;
    margin-bottom: 4px;
  }

  .percentage-label {
    display: block;
    font-size: 14px;
    color: var(--el-text-color-secondary);
  }
}
</style>
