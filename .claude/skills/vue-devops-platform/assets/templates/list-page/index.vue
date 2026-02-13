<script setup lang="ts">
import { reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useTable } from '@/composables/useTable'
import { usePermission } from '@/composables/usePermission'
import PageHeader from '@/components/common/PageHeader/index.vue'
import SearchForm from '@/components/common/SearchForm/index.vue'
import DataTable from '@/components/common/DataTable/index.vue'
import { getClusterList, deleteCluster } from '@/api/modules/cluster'
import type { ClusterInfo } from '@/types/business'

const router = useRouter()
const { hasPermission } = usePermission()

// 使用 useTable 组合式函数
const {
  loading,
  tableData,
  total,
  pagination,
  searchForm,
  handleSearch,
  handleReset,
  handleRefresh
} = useTable<ClusterInfo>({
  fetchApi: getClusterList
})

// 扩展搜索表单字段
Object.assign(searchForm, {
  name: '',
  status: '',
  dateRange: []
})

// 状态选项
const statusOptions = [
  { label: '运行中', value: 'running' },
  { label: '已停止', value: 'stopped' },
  { label: '错误', value: 'error' },
  { label: '等待中', value: 'pending' }
]

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

// 查看详情
const handleView = (row: ClusterInfo) => {
  router.push(`/cluster/detail/${row.id}`)
}

// 创建
const handleCreate = () => {
  router.push('/cluster/create')
}

// 编辑
const handleEdit = (row: ClusterInfo) => {
  router.push(`/cluster/edit/${row.id}`)
}

// 删除
const handleDelete = async (row: ClusterInfo) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除集群 "${row.name}" 吗？此操作不可恢复。`,
      '删除确认',
      {
        type: 'warning',
        confirmButtonText: '确定',
        cancelButtonText: '取消'
      }
    )

    await deleteCluster(row.id)
    ElMessage.success('删除成功')
    handleRefresh()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
    }
  }
}

// 批量删除
const selectedRows = reactive<ClusterInfo[]>([])
const handleSelectionChange = (selection: ClusterInfo[]) => {
  selectedRows.splice(0, selectedRows.length, ...selection)
}

const handleBatchDelete = async () => {
  if (selectedRows.length === 0) {
    ElMessage.warning('请选择要删除的数据')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要删除选中的 ${selectedRows.length} 个集群吗？`,
      '批量删除确认',
      {
        type: 'warning',
        confirmButtonText: '确定',
        cancelButtonText: '取消'
      }
    )

    // 批量删除逻辑
    await Promise.all(selectedRows.map(row => deleteCluster(row.id)))
    ElMessage.success('批量删除成功')
    handleRefresh()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('批量删除失败:', error)
    }
  }
}
</script>

<template>
  <div class="cluster-list">
    <PageHeader title="集群管理" :subtitle="`共 ${total} 个集群`">
      <template #extra>
        <el-button
          v-permission="['cluster:create']"
          type="primary"
          icon="Plus"
          @click="handleCreate"
        >
          创建集群
        </el-button>
        <el-button icon="Refresh" @click="handleRefresh">
          刷新
        </el-button>
      </template>
    </PageHeader>

    <SearchForm :loading="loading" @search="handleSearch" @reset="handleReset">
      <el-form-item label="集群名称">
        <el-input
          v-model="searchForm.name"
          placeholder="请输入集群名称"
          clearable
          style="width: 200px"
        />
      </el-form-item>

      <el-form-item label="状态">
        <el-select
          v-model="searchForm.status"
          placeholder="请选择状态"
          clearable
          style="width: 150px"
        >
          <el-option
            v-for="item in statusOptions"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
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
            style="width: 300px"
          />
        </el-form-item>
      </template>
    </SearchForm>

    <el-card>
      <div class="table-toolbar">
        <el-button
          v-permission="['cluster:delete']"
          type="danger"
          icon="Delete"
          :disabled="selectedRows.length === 0"
          @click="handleBatchDelete"
        >
          批量删除
        </el-button>
      </div>

      <DataTable
        :data="tableData"
        :total="total"
        :loading="loading"
        v-model:page="pagination.page"
        v-model:page-size="pagination.pageSize"
        @refresh="handleRefresh"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="name" label="集群名称" min-width="150" />
        <el-table-column prop="version" label="版本" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="nodeCount" label="节点数" width="100" />
        <el-table-column prop="podCount" label="Pod 数" width="100" />
        <el-table-column prop="namespace" label="命名空间" width="120" />
        <el-table-column prop="apiServer" label="API Server" min-width="200" show-overflow-tooltip />
        <el-table-column prop="createdAt" label="创建时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button
              link
              type="primary"
              icon="View"
              @click="handleView(row)"
            >
              查看
            </el-button>
            <el-button
              v-permission="['cluster:edit']"
              link
              type="primary"
              icon="Edit"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              v-permission="['cluster:delete']"
              link
              type="danger"
              icon="Delete"
              @click="handleDelete(row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </DataTable>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.cluster-list {
  padding: 20px;

  .table-toolbar {
    margin-bottom: 16px;
  }
}
</style>
