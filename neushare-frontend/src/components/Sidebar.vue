<template>
  <aside class="sidebar">
    <el-menu
      :default-active="activeMenu"
      class="sidebar-menu"
      @select="handleSelect"
    >
      <el-menu-item index="/profile/info">
        <el-icon><User /></el-icon>
        <span>个人资料</span>
      </el-menu-item>
      <el-menu-item index="/profile/resources">
        <el-icon><Document /></el-icon>
        <span>我的资料</span>
      </el-menu-item>
      <el-menu-item index="/profile/favorites">
        <el-icon><Star /></el-icon>
        <span>我的收藏</span>
      </el-menu-item>
    </el-menu>
  </aside>
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
.sidebar {
  width: 200px;
  background: var(--bg-surface);
  border-radius: var(--radius);
  border: 1px solid var(--border-default);
  overflow: hidden;
  flex-shrink: 0;
  align-self: flex-start;
}

.sidebar-menu {
  border-right: none;
  background: transparent;
  padding: var(--space-2) 0;
}

.sidebar-menu .el-menu-item {
  height: var(--control-height-lg);
  line-height: var(--control-height-lg);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  transition: var(--transition-fast);
}

.sidebar-menu .el-menu-item:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.sidebar-menu .el-menu-item.is-active {
  background: var(--info-bg);
  color: var(--accent);
  border-right: 2px solid var(--accent);
}

@media (max-width: 767px) {
  .sidebar {
    width: 100%;
  }

  .sidebar-menu {
    display: flex;
    padding: 0;
  }

  .sidebar-menu .el-menu-item {
    flex: 1;
    justify-content: center;
    height: var(--control-height-lg);
    line-height: var(--control-height-lg);
    border-right: none;
    border-bottom: 2px solid transparent;
    padding: 0 var(--space-2) !important;
  }

  .sidebar-menu .el-menu-item.is-active {
    border-right: none;
    border-bottom-color: var(--accent);
  }
}
</style>
