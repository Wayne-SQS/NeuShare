<template>
  <div class="admin-layout">
    <div class="admin-container">
      <aside class="admin-sidebar">
        <div class="sidebar-header">
          <h3>管理后台</h3>
        </div>
        <el-menu
          :default-active="activeMenu"
          class="admin-menu"
          @select="handleSelect"
        >
          <el-menu-item index="/admin/dashboard">
            <el-icon><DataAnalysis /></el-icon>
            <span>数据统计</span>
          </el-menu-item>
          <el-menu-item index="/admin/audit">
            <el-icon><DocumentChecked /></el-icon>
            <span>资料审核</span>
          </el-menu-item>
          <el-menu-item index="/admin/users">
            <el-icon><User /></el-icon>
            <span>用户管理</span>
          </el-menu-item>
          <el-menu-item index="/admin/banners">
            <el-icon><Picture /></el-icon>
            <span>轮播配置</span>
          </el-menu-item>
          <el-menu-item index="/admin/cards">
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
  min-height: calc(100vh - 60px);
  background: var(--bg-base);
}

.admin-container {
  display: flex;
  min-height: 100%;
}

.admin-sidebar {
  width: 220px;
  background: var(--bg-surface);
  border-right: 1px solid var(--border-subtle);
  flex-shrink: 0;
}

.sidebar-header {
  padding: 24px 20px 18px;
  border-bottom: 1px solid var(--border-subtle);
}

.sidebar-header h3 {
  font-size: 17px;
  font-weight: 700;
  color: var(--text-primary);
  margin: 0;
  letter-spacing: -0.02em;
}

.admin-menu {
  border-right: none;
  background: transparent;
}

.admin-menu .el-menu-item {
  height: 50px;
  line-height: 50px;
  color: var(--text-secondary);
  transition: var(--transition-fast);
}

.admin-menu .el-menu-item:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.admin-menu .el-menu-item.is-active {
  background: rgba(200, 164, 78, 0.08);
  color: var(--accent);
  border-right: 2px solid var(--accent);
}

.admin-content {
  flex: 1;
  padding: 24px;
  overflow: auto;
}
</style>
