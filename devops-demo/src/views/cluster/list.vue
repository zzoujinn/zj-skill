<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { mockClusters } from '../../mock/data'
import type { ClusterInfo } from '../../types/business'

const router = useRouter()

// Search form
const searchForm = ref({
  name: '',
  status: '' as string
})

// Pagination
const currentPage = ref(1)
const pageSize = ref(10)

// Table data with search filtering
const filteredData = computed(() => {
  let data = [...mockClusters]
  if (searchForm.value.name) {
    data = data.filter(item =>
      item.name.toLowerCase().includes(searchForm.value.name.toLowerCase())
    )
  }
  if (searchForm.value.status) {
    data = data.filter(item => item.status === searchForm.value.status)
  }
  return data
})

const total = computed(() => filteredData.value.length)

const tableData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredData.value.slice(start, start + pageSize.value)
})

const loading = ref(false)

// Status options
const statusOptions = [
  { label: '运行中', value: 'running' },
  { label: '已停止', value: 'stopped' },
  { label: '错误', value: 'error' },
  { label: '等待中', value: 'pending' }
]

const getStatusType = (status: string): '' | 'success' | 'info' | 'warning' | 'danger' => {
  const map: Record<string, '' | 'success' | 'info' | 'warning' | 'danger'> = {
    running: 'success',
    stopped: 'info',
    error: 'danger',
    pending: 'warning'
  }
  return map[status] || 'info'
}

const getStatusLabel = (status: string) => {
  const map: Record<string, string> = {
    running: '运行中',
    stopped: '已停止',
    error: '错误',
    pending: '等待中'
  }
  return map[status] || status
}

// Selection
const selectedRows = ref<ClusterInfo[]>([])
const handleSelectionChange = (selection: ClusterInfo[]) => {
  selectedRows.value = selection
}

// Actions
const handleSearch = () => {
  currentPage.value = 1
  loading.value = true
  setTimeout(() => { loading.value = false }, 300)
}

const handleReset = () => {
  searchForm.value = { name: '', status: '' }
  currentPage.value = 1
}

const handleRefresh = () => {
  loading.value = true
  setTimeout(() => {
    loading.value = false
    ElMessage.success('数据已刷新')
  }, 300)
}

const handleView = (row: ClusterInfo) => {
  router.push(`/cluster/detail/${row.id}`)
}

const handleDelete = async (row: ClusterInfo) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除集群 "${row.name}" 吗？此操作不可恢复。`,
      '删除确认',
      { type: 'warning', confirmButtonText: '确定', cancelButtonText: '取消' }
    )
    ElMessage.success('删除成功（模拟）')
  } catch {
    // cancelled
  }
}

const handleBatchDelete = async () => {
  if (selectedRows.value.length === 0) {
    ElMessage.warning('请选择要删除的数据')
    return
  }
  try {
    await ElMessageBox.confirm(
      `确定要删除选中的 ${selectedRows.value.length} 个集群吗？`,
      '批量删除确认',
      { type: 'warning', confirmButtonText: '确定', cancelButtonText: '取消' }
    )
    ElMessage.success('批量删除成功（模拟）')
  } catch {
    // cancelled
  }
}

const handleCreate = () => {
  ElMessage.info('创建集群功能（模拟）')
}
</script>

<template>
  <div class="cluster-list">
    <!-- Header -->
    <div class="page-header">
      <div class="page-header__left">
        <h2 class="page-header__title">集群管理</h2>
        <span class="page-header__subtitle">共 {{ total }} 个集群</span>
      </div>
      <div class="page-header__right">
        <el-button type="primary" :icon="'Plus'" @click="handleCreate">创建集群</el-button>
        <el-button :icon="'Refresh'" @click="handleRefresh">刷新</el-button>
      </div>
    </div>

    <!-- Search form -->
    <el-card shadow="never" class="search-card">
      <el-form :model="searchForm" inline>
        <el-form-item label="集群名称">
          <el-input
            v-model="searchForm.name"
            placeholder="请输入集群名称"
            clearable
            style="width: 200px"
            @keyup.enter="handleSearch"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="searchForm.status" placeholder="请选择状态" clearable style="width: 140px">
            <el-option v-for="item in statusOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="'Search'" @click="handleSearch">搜索</el-button>
          <el-button :icon="'RefreshLeft'" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- Table -->
    <el-card shadow="never">
      <div class="table-toolbar">
        <el-button
          type="danger"
          :icon="'Delete'"
          :disabled="selectedRows.length === 0"
          @click="handleBatchDelete"
        >
          批量删除
        </el-button>
        <span class="table-toolbar__info" v-if="selectedRows.length > 0">
          已选择 {{ selectedRows.length }} 项
        </span>
      </div>

      <el-table
        :data="tableData"
        v-loading="loading"
        stripe
        border
        style="width: 100%"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="50" />
        <el-table-column prop="name" label="集群名称" min-width="180">
          <template #default="{ row }">
            <el-link type="primary" @click="handleView(row)">{{ row.name }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="version" label="版本" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)" size="small">
              {{ getStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="nodeCount" label="节点数" width="80" align="center" />
        <el-table-column prop="podCount" label="Pod 数" width="80" align="center" />
        <el-table-column prop="namespace" label="命名空间" width="120" />
        <el-table-column prop="apiServer" label="API Server" min-width="200" show-overflow-tooltip />
        <el-table-column prop="createdAt" label="创建时间" width="170" />
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="handleView(row)">
              <el-icon><View /></el-icon> 查看
            </el-button>
            <el-button link type="danger" size="small" @click="handleDelete(row)">
              <el-icon><Delete /></el-icon> 删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- Pagination -->
      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[5, 10, 20, 50]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          background
        />
      </div>
    </el-card>
  </div>
</template>

<style scoped>
.cluster-list {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
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
  gap: 8px;
}

.search-card {
  margin-bottom: 16px;
}

.search-card :deep(.el-card__body) {
  padding-bottom: 2px;
}

.table-toolbar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.table-toolbar__info {
  font-size: 13px;
  color: #909399;
}

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
