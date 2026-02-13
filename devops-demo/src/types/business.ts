export interface ClusterInfo {
  id: string
  name: string
  version: string
  status: 'running' | 'stopped' | 'error' | 'pending'
  nodeCount: number
  podCount: number
  namespace: string
  apiServer: string
  createdAt: string
  cpuUsage: number
  memoryUsage: number
  diskUsage: number
  labels: Record<string, string>
  description: string
}

export interface NodeInfo {
  name: string
  status: string
  role: string
  ip: string
  os: string
  kubeletVersion: string
  cpu: string
  memory: string
}

export interface PodInfo {
  name: string
  namespace: string
  status: string
  restarts: number
  age: string
  node: string
  ip: string
}

export interface EventInfo {
  type: 'Normal' | 'Warning'
  reason: string
  message: string
  timestamp: string
}
