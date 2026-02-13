<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import PageHeader from '@/components/common/PageHeader/index.vue'
import { useForm } from '@/composables/useForm'
import {
  getClusterDetail,
  createCluster,
  updateCluster
} from '@/api/modules/cluster'
import type { ClusterCreateParams, ClusterUpdateParams } from '@/types/business'

const route = useRoute()
const router = useRouter()

// 判断是否为编辑模式
const isEdit = ref(false)
const clusterId = ref('')

// 表单规则
const rules: FormRules = {
  name: [
    { required: true, message: '请输入集群名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' },
    {
      pattern: /^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/,
      message: '只能包含小写字母、数字和连字符，且必须以字母或数字开头和结尾',
      trigger: 'blur'
    }
  ],
  version: [
    { required: true, message: '请选择 Kubernetes 版本', trigger: 'change' }
  ],
  namespace: [
    { required: true, message: '请输入命名空间', trigger: 'blur' }
  ],
  apiServer: [
    { required: true, message: '请输入 API Server 地址', trigger: 'blur' },
    {
      pattern: /^https?:\/\/.+/,
      message: '请输入有效的 URL 地址',
      trigger: 'blur'
    }
  ]
}

// 使用 useForm 组合式函数
const {
  formRef,
  formData,
  loading,
  handleSubmit
} = useForm<ClusterCreateParams | ClusterUpdateParams>({
  initialValues: {
    name: '',
    version: '',
    namespace: 'default',
    apiServer: '',
    labels: {},
    annotations: {}
  },
  rules,
  createApi: createCluster,
  updateApi: (id: string, data: any) => updateCluster(id, data),
  onSuccess: () => {
    router.push('/cluster/list')
  }
})

// Kubernetes 版本选项
const versionOptions = [
  { label: 'v1.28.0', value: '1.28.0' },
  { label: 'v1.29.0', value: '1.29.0' },
  { label: 'v1.30.0', value: '1.30.0' }
]

// 标签管理
const labelKey = ref('')
const labelValue = ref('')

const addLabel = () => {
  if (!labelKey.value || !labelValue.value) {
    ElMessage.warning('请输入标签键和值')
    return
  }

  if (!formData.labels) {
    formData.labels = {}
  }

  formData.labels[labelKey.value] = labelValue.value
  labelKey.value = ''
  labelValue.value = ''
}

const removeLabel = (key: string) => {
  if (formData.labels) {
    delete formData.labels[key]
  }
}

// 注解管理
const annotationKey = ref('')
const annotationValue = ref('')

const addAnnotation = () => {
  if (!annotationKey.value || !annotationValue.value) {
    ElMessage.warning('请输入注解键和值')
    return
  }

  if (!formData.annotations) {
    formData.annotations = {}
  }

  formData.annotations[annotationKey.value] = annotationValue.value
  annotationKey.value = ''
  annotationValue.value = ''
}

const removeAnnotation = (key: string) => {
  if (formData.annotations) {
    delete formData.annotations[key]
  }
}

// 返回列表
const handleBack = () => {
  router.push('/cluster/list')
}

// 重置表单
const handleReset = () => {
  formRef.value?.resetFields()
  formData.labels = {}
  formData.annotations = {}
}

// 初始化数据（编辑模式）
const initData = async () => {
  const id = route.params.id as string
  if (id) {
    isEdit.value = true
    clusterId.value = id

    try {
      const data = await getClusterDetail(id)
      Object.assign(formData, {
        name: data.name,
        version: data.version,
        namespace: data.namespace,
        apiServer: data.apiServer,
        labels: data.labels || {},
        annotations: data.annotations || {}
      })
    } catch (error) {
      console.error('获取集群详情失败:', error)
      ElMessage.error('加载失败，请稍后重试')
    }
  }
}

onMounted(() => {
  initData()
})
</script>

<template>
  <div class="cluster-form">
    <PageHeader
      :title="isEdit ? '编辑集群' : '创建集群'"
      show-back
      @back="handleBack"
    />

    <el-card>
      <el-form
        ref="formRef"
        :model="formData"
        :rules="rules"
        label-width="120px"
        label-position="right"
      >
        <!-- 基本信息 -->
        <el-divider content-position="left">基本信息</el-divider>

        <el-form-item label="集群名称" prop="name">
          <el-input
            v-model="formData.name"
            placeholder="请输入集群名称"
            :disabled="isEdit"
            clearable
          >
            <template #append>
              <el-tooltip content="集群名称创建后不可修改" placement="top">
                <el-icon><QuestionFilled /></el-icon>
              </el-tooltip>
            </template>
          </el-input>
        </el-form-item>

        <el-form-item label="Kubernetes 版本" prop="version">
          <el-select
            v-model="formData.version"
            placeholder="请选择版本"
            style="width: 100%"
          >
            <el-option
              v-for="item in versionOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="命名空间" prop="namespace">
          <el-input
            v-model="formData.namespace"
            placeholder="请输入命名空间"
            clearable
          />
        </el-form-item>

        <el-form-item label="API Server" prop="apiServer">
          <el-input
            v-model="formData.apiServer"
            placeholder="https://api.example.com:6443"
            clearable
          />
        </el-form-item>

        <!-- 标签配置 -->
        <el-divider content-position="left">标签 (Labels)</el-divider>

        <el-form-item label="添加标签">
          <div class="key-value-input">
            <el-input
              v-model="labelKey"
              placeholder="键 (key)"
              style="width: 200px"
            />
            <span class="separator">:</span>
            <el-input
              v-model="labelValue"
              placeholder="值 (value)"
              style="width: 200px"
            />
            <el-button type="primary" icon="Plus" @click="addLabel">
              添加
            </el-button>
          </div>
        </el-form-item>

        <el-form-item label="已添加标签" v-if="formData.labels && Object.keys(formData.labels).length > 0">
          <div class="tag-list">
            <el-tag
              v-for="(value, key) in formData.labels"
              :key="key"
              closable
              @close="removeLabel(key)"
            >
              {{ key }}: {{ value }}
            </el-tag>
          </div>
        </el-form-item>

        <!-- 注解配置 -->
        <el-divider content-position="left">注解 (Annotations)</el-divider>

        <el-form-item label="添加注解">
          <div class="key-value-input">
            <el-input
              v-model="annotationKey"
              placeholder="键 (key)"
              style="width: 200px"
            />
            <span class="separator">:</span>
            <el-input
              v-model="annotationValue"
              placeholder="值 (value)"
              style="width: 200px"
            />
            <el-button type="primary" icon="Plus" @click="addAnnotation">
              添加
            </el-button>
          </div>
        </el-form-item>

        <el-form-item label="已添加注解" v-if="formData.annotations && Object.keys(formData.annotations).length > 0">
          <div class="tag-list">
            <el-tag
              v-for="(value, key) in formData.annotations"
              :key="key"
              type="info"
              closable
              @close="removeAnnotation(key)"
            >
              {{ key }}: {{ value }}
            </el-tag>
          </div>
        </el-form-item>

        <!-- 操作按钮 -->
        <el-form-item>
          <el-button
            type="primary"
            :loading="loading"
            @click="handleSubmit"
          >
            {{ isEdit ? '保存' : '创建' }}
          </el-button>
          <el-button @click="handleReset">
            重置
          </el-button>
          <el-button @click="handleBack">
            取消
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.cluster-form {
  padding: 20px;

  .key-value-input {
    display: flex;
    align-items: center;
    gap: 8px;

    .separator {
      font-weight: bold;
      color: var(--el-text-color-secondary);
    }
  }

  .tag-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  :deep(.el-divider__text) {
    font-size: 16px;
    font-weight: 600;
  }
}
</style>
