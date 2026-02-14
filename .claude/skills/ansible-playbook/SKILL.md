---
name: ansible-playbook
description: Ansible 自动化编排工具。帮助编写 Playbook、Role、Inventory，实现批量运维任务自动化。当用户需要：(1) 编写 Ansible Playbook，(2) 设计 Ansible Role 结构，(3) 编写批量运维任务（部署、配置、巡检），(4) 管理 Inventory 和变量，(5) 审查现有 Playbook 的质量和安全性，(6) 编写 Ansible 模板（Jinja2）时使用。触发条件："ansible"、"playbook"、"ansible-playbook"、"批量运维"、"自动化部署"、"ansible role"、"inventory"。
---

# Ansible 自动化编排

## Playbook 编写流程

1. 明确自动化目标（部署/配置/巡检/备份）
2. 设计 Inventory（主机分组）
3. 编写 Playbook 或设计 Role
4. 测试（--check 模式、限定主机）
5. 执行并验证

## 项目结构规范

```
ansible-project/
├── inventory/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       ├── all.yml
│   │       └── webservers.yml
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/
│           └── all.yml
├── roles/
│   └── <role-name>/
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       ├── templates/
│       ├── files/
│       ├── vars/main.yml
│       └── defaults/main.yml
├── playbooks/
│   ├── deploy.yml
│   ├── setup.yml
│   └── maintenance.yml
├── ansible.cfg
└── requirements.yml
```

## Inventory 示例

```yaml
# inventory/production/hosts.yml
all:
  children:
    webservers:
      hosts:
        web01:
          ansible_host: 10.0.1.10
        web02:
          ansible_host: 10.0.1.11
    dbservers:
      hosts:
        db01:
          ansible_host: 10.0.2.10
          ansible_port: 22
    middleware:
      hosts:
        redis01:
          ansible_host: 10.0.3.10
  vars:
    ansible_user: deploy
    ansible_ssh_private_key_file: ~/.ssh/deploy_key
```

## Playbook 模板

### 应用部署

```yaml
---
- name: 部署应用
  hosts: webservers
  become: yes
  vars:
    app_name: myapp
    app_version: "{{ deploy_version | default('latest') }}"
    app_dir: /opt/{{ app_name }}

  pre_tasks:
    - name: 检查目标目录
      file:
        path: "{{ app_dir }}"
        state: directory
        owner: "{{ app_name }}"
        mode: "0755"

  tasks:
    - name: 停止服务
      systemd:
        name: "{{ app_name }}"
        state: stopped
      ignore_errors: yes

    - name: 拉取代码/制品
      get_url:
        url: "https://artifacts.example.com/{{ app_name }}/{{ app_version }}/{{ app_name }}.tar.gz"
        dest: "/tmp/{{ app_name }}.tar.gz"
        checksum: "sha256:{{ artifact_checksum }}"

    - name: 解压部署
      unarchive:
        src: "/tmp/{{ app_name }}.tar.gz"
        dest: "{{ app_dir }}"
        remote_src: yes

    - name: 渲染配置文件
      template:
        src: "{{ app_name }}.conf.j2"
        dest: "{{ app_dir }}/config/app.conf"
        owner: "{{ app_name }}"
        mode: "0640"
      notify: 重启服务

    - name: 启动服务
      systemd:
        name: "{{ app_name }}"
        state: started
        enabled: yes

    - name: 等待服务就绪
      uri:
        url: "http://localhost:{{ app_port }}/health"
        status_code: 200
      register: health_check
      until: health_check.status == 200
      retries: 30
      delay: 2

  handlers:
    - name: 重启服务
      systemd:
        name: "{{ app_name }}"
        state: restarted
```

### 系统初始化

```yaml
---
- name: 系统初始化
  hosts: all
  become: yes

  tasks:
    - name: 设置主机名
      hostname:
        name: "{{ inventory_hostname }}"

    - name: 配置 YUM 源
      copy:
        src: CentOS-Base.repo
        dest: /etc/yum.repos.d/CentOS-Base.repo
      when: ansible_os_family == "RedHat"

    - name: 安装基础软件包
      package:
        name:
          - vim
          - wget
          - curl
          - net-tools
          - lsof
          - htop
          - tree
          - jq
        state: present

    - name: 配置时区
      timezone:
        name: Asia/Shanghai

    - name: 配置 NTP
      template:
        src: chrony.conf.j2
        dest: /etc/chrony.conf
      notify: 重启 chrony

    - name: 优化内核参数
      sysctl:
        name: "{{ item.key }}"
        value: "{{ item.value }}"
        sysctl_set: yes
        reload: yes
      loop:
        - { key: "net.ipv4.tcp_max_syn_backlog", value: "65535" }
        - { key: "net.core.somaxconn", value: "65535" }
        - { key: "net.ipv4.ip_local_port_range", value: "1024 65535" }
        - { key: "fs.file-max", value: "655350" }
        - { key: "vm.swappiness", value: "10" }

    - name: 配置文件描述符限制
      pam_limits:
        domain: "*"
        limit_type: "{{ item.type }}"
        limit_item: nofile
        value: "655350"
      loop:
        - { type: "soft" }
        - { type: "hard" }

    - name: 禁用 SELinux
      selinux:
        state: disabled
      when: ansible_os_family == "RedHat"

    - name: 禁用不需要的服务
      systemd:
        name: "{{ item }}"
        state: stopped
        enabled: no
      loop:
        - firewalld
        - postfix
      ignore_errors: yes

  handlers:
    - name: 重启 chrony
      systemd:
        name: chronyd
        state: restarted
        enabled: yes
```

### 系统巡检

```yaml
---
- name: 系统巡检
  hosts: all
  become: yes
  gather_facts: yes

  tasks:
    - name: 收集磁盘使用率
      shell: df -h | grep -vE "tmpfs|devtmpfs"
      register: disk_usage
      changed_when: false

    - name: 检查磁盘使用率超过 80% 的分区
      shell: df -h | awk 'NR>1 && int($5)>80 {print $0}'
      register: disk_warning
      changed_when: false

    - name: 收集内存使用情况
      shell: free -h
      register: mem_usage
      changed_when: false

    - name: 检查系统负载
      debug:
        msg: "负载: {{ ansible_loadavg }} (CPU核数: {{ ansible_processor_vcpus }})"

    - name: 检查关键服务状态
      systemd:
        name: "{{ item }}"
      register: service_status
      loop: "{{ critical_services | default(['sshd', 'chronyd']) }}"
      ignore_errors: yes

    - name: 检查最近登录失败
      shell: lastb | head -10
      register: login_failures
      changed_when: false
      ignore_errors: yes

    - name: 生成巡检报告
      template:
        src: inspection_report.j2
        dest: "/tmp/inspection_{{ inventory_hostname }}_{{ ansible_date_time.date }}.txt"
      delegate_to: localhost
```

## 最佳实践

1. **幂等性**：任务可重复执行，结果一致
2. **变量管理**：敏感变量用 ansible-vault 加密，默认值放 defaults/
3. **错误处理**：合理使用 ignore_errors、failed_when、block/rescue
4. **测试先行**：先用 `--check --diff` 预览变更
5. **限定范围**：用 `--limit` 限定目标主机，避免误操作
6. **标签管理**：给任务打 tags，支持部分执行
7. **日志记录**：配置 ansible.cfg 中的 log_path

## 常用命令

```bash
# 语法检查
ansible-playbook playbook.yml --syntax-check
# 预览变更（不实际执行）
ansible-playbook playbook.yml --check --diff
# 限定主机执行
ansible-playbook playbook.yml --limit web01
# 指定标签执行
ansible-playbook playbook.yml --tags "config,restart"
# 加密变量文件
ansible-vault encrypt vars/secrets.yml
# 临时命令
ansible all -m ping
ansible webservers -m shell -a "uptime"
```
