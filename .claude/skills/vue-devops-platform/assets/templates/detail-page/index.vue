<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import PageHeader from '@/components/common/PageHeader/index.vue'
import { usePermission } from '@/composables/usePermission'
import { getClusterDetail, deleteCluster } from '@/api/modules/cluster'
import type { ClusterInfo } from '@/types/business'

const route = useRoute()
const router = useRouter()
const { hasPermission } = usePermission()

const loading = ref(false)
const clusterData = ref<ClusterInfo | null>(null)
const activeTab = ref('basic')

// 获取集群详情
const fetchData = async () => {
  loading.value = true
  try {
    const id = route.params.id as string
    clusterData.value = await getClusterDetail(id)
  } catch (error) {
    console.error('获取集群详情失败:', error)
    ElMessage.error('加载失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

// 返回列表
const handleBack = () => {
  router.push('/cluster/list')
}

// 编辑
const handleEdit = () => {
  router.push(`/cluster/edit/${clusterData.value?.id}`)
}

// 删除
const handleDelete = async () => {
  if (!clusterData.value) return

  try {
    await ElMessageBox.confirm(
      `确定要删除集群 "${clusterData.value.name}" 吗？此操作不可恢复。`,
      '删除确认',
      {
        type: 'warning',
        confirmButtonText: '确定',
        cancelButtonText: '取消'
      }
    )

    await deleteCluster(clusterData.value.id)
    ElMessage.success('删除成功')
    router.push('/cluster/list')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
    }
  }
}

// 获取状态标签类型
const getStatusType = (status: string) => {
  const typeMap: Record<string, any> = {
    running: 'success',
    stopped: 'info',
    error: 'danger',
    pending: 'warning'
  }
  return typeMap[status] || 'info'
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="cluster-detail" v-loading="loading">
    <PageHeader
      :title="clusterData?.name || '集群详情'"
      :subtitle="`ID: ${clusterData?.id || '-'}`"
      show-back
      @back="handleBack"
    >
      <template #extra>
        <el-button
          v-permission="['cluster:edit']"
          type="primary"
          icon="Edit"
          @click="handleEdit"
        >
          编辑
        </el-button>
        <el-button
          v-permission="['cluster:delete']"
          type="danger"
          icon="Delete"
          @click="handleDelete"
        >
          删除
        </el-button>
        <el-button icon="Refresh" @click="fetchData">
          刷新
        </el-button>
      </template>
    </PageHeader>

    <el-card v-if="clusterData">
      <!-- 基本信息卡片 -->
      <div class="info-header">
        <div class="info-header__left">
          <el-icon :size="48" color="#409EFF">
            <component is="Coin" />
          </el-icon>
          <div class="info-header__content">
            <h2>{{ clusterData.name }}</h2>
            <div class="info-header__meta">
              <el-tag :type="getStatusType(clusterData.status)">
                {{ clusterData.status }}
              </el-tag>
              <span class="meta-item">版本: {{ clusterData.version }}</span>
              <span class="meta-item">命名空间: {{ clusterData.namespace }}</span>
            </div>
          </div>
        </div>
      </div>

      <el-divider />

      <!-- 标签页 -->
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="basic">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="集群名称">
              {{ clusterData.name }}
            </el-descriptions-item>
            <el-descriptions-item label="集群 ID">
              {{ clusterData.id }}
            </el-descriptions-item>
            <el-descriptions-item label="版本">
              {{ clusterData.version }}
            </el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag :type="getStatusType(clusterData.status)">
                {{ clusterData.status }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="命名空间">
              {{ clusterData.namespace }}
            </el-descriptions-item>
            <el-descriptions-item label="API Server">
              {{ clusterData.apiServer }}
            </el-descriptions-item>
            <el-descriptions-item label="节点数">
              {{ clusterData.nodeCount }}
            </el-descriptions-item>
            <el-descriptions-item label="Pod 数">
              {{ clusterData.podCount }}
            </el-descriptions-item>
            <el-descriptions-item label="创建时间">
              {{ clusterData.createdAt }}
            </el-descriptions-item>
            <el-descriptions-item label="更新时间">
              {{ clusterData.updatedAt }}
            </el-descriptions-item>
          </el-descriptions>

          <!-- 标签 -->
          <div v-if="clusterData.labels" class="section">
            <h3>标签 (Labels)</h3>
            <el-tag
              v-for="(value, key) in clusterData.labels"
              :key="key"
              class="label-tag"
            >
              {{ key }}: {{ value }}
            </el-tag>
            <el-empty v-if="Object.keys(clusterData.labels).length === 0" description="暂无标签" />
          </div>

          <!-- 注解 -->
          <div v-if="clusterData.annotations" class="section">
            <h3>注解 (Annotations)</h3>
            <el-tag
              v-for="(value, key) in clusterData.annotations"
              :key="key"
              type="info"
              class="label-tag"
            >
              {{ key }}: {{ value }}
            </el-tag>
            <el-empty v-if="Object.keys(clusterData.annotations).length === 0" description="暂无注解" />
          </div>
        </el-tab-pane>

        <!-- 节点信息 -->
        <el-tab-pane label="节点信息" name="nodes">
          <el-table :data="[]" border stripe>
            <el-table-column prop="name" label="节点名称" />
            <el-table-column prop="status" label="状态" />
            <el-table-column prop="role" label="角色" />
            <el-table-column prop="cpu" label="CPU" />
            <el-table-column prop="memory" label="内存" />
            <el-table-column prop="podCount" label="Pod 数" />
          </el-table>
          <el-empty description="暂无节点数据" />
        </el-tab-pane>

        <!-- Pod 信息 -->
        <el-tab-pane label="Pod 信息" name="pods">
          <el-table :data="[]" border stripe>
            <el-table-column prop="name" label="Pod 名称" />
            <el-table-column prop="namespace" label="命名空间" />
            <el-table-column prop="status" label="状态" />
            <el-table-column prop="restarts" label="重启次数" />
            <el-table-column prop="age" label="运行时长" />
          </el-table>
          <el-empty description="暂无 Pod 数据" />
        </el-tab-pane>

        <!-- 监控指标 -->
        <el-tab-pane label="监控指标" name="metrics">
          <el-row :gutter="16">
            <el-col :span="6">
              <el-statistic title="CPU 使用率" :value="68.5" suffix="%" />
            </el-col>
            <el-col :span="6">
              <el-statistic title="内存使用率" :value="72.3" suffix="%" />
            </el-col>
            <el-col :span="6">
              <el-statistic title="磁盘使用率" :value="45.8" suffix="%" />
            </el-col>
            <el-col :span="6">
              <el-statistic title="网络流量" :value="1024" suffix="MB/s" />
            </el-col>
          </el-row>

          <div class="chart-container">
            <!-- 这里可以集成 ECharts 图表 -->
            <el-empty description="监控图表开发中" />
          </div>
        </el-tab-pane>

        <!-- 事件日志 -->
        <el-tab-pane label="事件日志" name="events">
          <el-timeline>
            <el-timeline-item
              v-for="(event, index) in []"
              :key="index"
              :timestamp="event.timestamp"
              placement="top"
            >
              <el-card>
                <h4>{{ event.type }}</h4>
                <p>{{ event.message }}</p>
              </el-card>
            </el-timeline-item>
          </el-timeline>
          <el-empty description="暂无事件日志" />
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.cluster-detail {
  padding: 20px;

  .info-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;

    &__left {
      display: flex;
      gap: 16px;
      align-items: center;
    }

    &__content {
      h2 {
        margin: 0 0 8px 0;
        font-size: 24px;
        font-weight: 600;
      }
    }

    &__meta {
      display: flex;
      gap: 16px;
      align-items: center;

      .meta-item {
        color: var(--el-text-color-secondary);
        font-size: 14px;
      }
    }
  }

  .section {
    margin-top: 24px;

    h3 {
      margin-bottom: 12px;
      font-size: 16px;
      font-weight: 600;
    }

    .label-tag {
      margin-right: 8px;
      margin-bottom: 8px;
    }
  }

  .chart-container {
    margin-top: 24px;
    min-height: 300px;
  }
}
</style>
