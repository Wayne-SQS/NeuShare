<template>
  <div class="admin-layout">
    <div class="admin-container">
      <aside class="admin-sidebar">
        <div class="sidebar-header">
          <div class="sidebar-logo">NeuShare</div>
          <div class="sidebar-sub">WORKSPACE <i>/</i> 管理后台</div>
        </div>
        <el-menu :default-active="activeMenu" class="admin-menu" @select="handleSelect">
          <el-menu-item index="/admin/dashboard">
            <el-icon><DataAnalysis /></el-icon><span>数据统计</span>
          </el-menu-item>
          <el-menu-item index="/admin/audit">
            <el-icon><DocumentChecked /></el-icon><span>资料审核</span>
          </el-menu-item>
          <el-menu-item index="/admin/users">
            <el-icon><User /></el-icon><span>用户管理</span>
          </el-menu-item>
          <el-menu-item index="/admin/banners">
            <el-icon><Picture /></el-icon><span>轮播配置</span>
          </el-menu-item>
          <el-menu-item index="/admin/cards">
            <el-icon><Postcard /></el-icon><span>卡片管理</span>
          </el-menu-item>
        </el-menu>
        <div class="sidebar-footer">
          <strong>{{ userStore.username || '管理员' }} · 管理员</strong>
          <span>v3.0 · 2026.11</span>
        </div>
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
import { useUserStore } from '@/store/modules/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const activeMenu = computed(() => route.path)
const handleSelect = (index) => { router.push(index) }
</script>

<style scoped>
.admin-layout {
  min-height: calc(100vh - 64px);
  background: var(--bg-deep);
}

.admin-container { display: flex; min-height: 100%; }

.admin-sidebar {
  width: 216px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  background: var(--bg-base);
  border-right: 1px solid var(--border-default);
}

.sidebar-header { padding: 26px 22px 22px; border-bottom: 1px solid var(--border-subtle); }
.sidebar-logo { font-size: 20px; font-weight: 700; letter-spacing: -0.03em; color: var(--text-primary); }
.sidebar-sub {
  margin-top: 6px; font-family: var(--font-mono); font-size: 10px;
  letter-spacing: 0.08em; color: var(--text-muted); text-transform: uppercase;
}
.sidebar-sub i { font-style: normal; opacity: 0.6; margin: 0 3px; }

.admin-menu { border-right: none; background: transparent; padding: 14px 10px; flex: 1; }
.admin-menu :deep(.el-menu-item) {
  height: 44px; line-height: 44px; margin-bottom: 4px;
  border-radius: var(--radius-sm); color: var(--text-secondary);
  transition: var(--transition-fast);
}
.admin-menu :deep(.el-menu-item:hover) { background: var(--bg-hover); color: var(--text-primary); }
.admin-menu :deep(.el-menu-item.is-active) {
  background: var(--bg-hover); color: var(--text-primary); font-weight: 600;
  border-left: 2px solid var(--text-primary);
}

.sidebar-footer {
  display: flex; flex-direction: column; gap: 3px;
  padding: 18px 22px 22px; border-top: 1px solid var(--border-subtle);
}
.sidebar-footer strong { font-size: 12px; color: var(--text-secondary); }
.sidebar-footer span { font-family: var(--font-mono); font-size: 11px; color: var(--text-muted); }

.admin-content { flex: 1; padding: 26px 28px; overflow: auto; min-width: 0; }

@media (max-width: 800px) {
  .admin-sidebar { width: 64px; }
  .sidebar-header { padding: 20px 10px; }
  .sidebar-logo { font-size: 13px; }
  .sidebar-sub, .sidebar-footer { display: none; }
  .admin-menu { padding: 12px 6px; }
  .admin-menu :deep(.el-menu-item span) { display: none; }
  .admin-content { padding: 18px; }
}
</style>
