<template>
  <div class="admin-layout">
    <div class="admin-container">
      <aside class="admin-sidebar">
        <div class="sidebar-header">
          <span class="sidebar-title">管理后台</span>
        </div>
        <el-menu
          :default-active="activeMenu"
          class="admin-menu"
          @select="handleSelect"
        >
          <el-menu-item index="/admin/dashboard" title="数据统计">
            <el-icon><DataAnalysis /></el-icon>
            <span>数据统计</span>
          </el-menu-item>
          <el-menu-item index="/admin/audit" title="资料审核">
            <el-icon><DocumentChecked /></el-icon>
            <span>资料审核</span>
          </el-menu-item>
          <el-menu-item index="/admin/users" title="用户管理">
            <el-icon><User /></el-icon>
            <span>用户管理</span>
          </el-menu-item>
          <el-menu-item index="/admin/banners" title="轮播配置">
            <el-icon><Picture /></el-icon>
            <span>轮播配置</span>
          </el-menu-item>
          <el-menu-item index="/admin/cards" title="卡片管理">
            <el-icon><Postcard /></el-icon>
            <span>卡片管理</span>
          </el-menu-item>
        </el-menu>
      </aside>
      <main class="admin-content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

const activeMenu = computed(() => route.path)

const handleSelect = (index) => {
  router.push(index)
}
</script>

<style scoped>
.admin-layout {
  min-height: calc(100vh - var(--header-height));
  background: var(--bg-deep);
}

.admin-container {
  display: flex;
  align-items: flex-start;
  max-width: var(--container-wide);
  margin: 0 auto;
  min-height: calc(100vh - var(--header-height));
}

.admin-sidebar {
  width: var(--sidebar-width);
  flex-shrink: 0;
  align-self: stretch;
  background: var(--bg-surface);
  border-right: 1px solid var(--border-default);
}

.sidebar-header {
  display: flex;
  align-items: center;
  height: 56px;
  padding: 0 var(--space-5);
  border-bottom: 1px solid var(--border-subtle);
}

.sidebar-title {
  font-size: var(--text-sm);
  font-weight: var(--font-semibold);
  color: var(--text-secondary);
  letter-spacing: 0.04em;
  white-space: nowrap;
}

.admin-menu {
  border-right: none;
  background: transparent;
  padding: var(--space-2) 0;
}

.admin-menu .el-menu-item {
  height: var(--control-height-lg);
  line-height: var(--control-height-lg);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  transition: var(--transition-fast);
}

.admin-menu .el-menu-item:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.admin-menu .el-menu-item.is-active {
  background: var(--info-bg);
  color: var(--accent);
  border-right: 2px solid var(--accent);
}

.admin-content {
  flex: 1;
  min-width: 0;
  padding: var(--space-6);
  overflow-x: auto;
}

@media (max-width: 991px) {
  .admin-sidebar {
    width: 64px;
  }

  .sidebar-header {
    justify-content: center;
    padding: 0;
  }

  .sidebar-title {
    display: none;
  }

  .admin-menu :deep(.el-menu-item) {
    justify-content: center;
    padding: 0 !important;
  }

  .admin-menu :deep(.el-menu-item span) {
    display: none;
  }

  .admin-menu .el-menu-item.is-active {
    border-right: none;
    border-left: 2px solid var(--accent);
  }
}

@media (max-width: 767px) {
  .admin-content {
    padding: var(--space-4);
  }
}
</style>
