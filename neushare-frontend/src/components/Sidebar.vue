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
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-subtle);
  overflow: hidden;
  flex-shrink: 0;
}

.sidebar-menu {
  border-right: none;
  background: transparent;
}

.sidebar-menu .el-menu-item {
  height: 50px;
  line-height: 50px;
  color: var(--text-secondary);
  transition: var(--transition-fast);
}

.sidebar-menu .el-menu-item:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.sidebar-menu .el-menu-item.is-active {
  background: rgba(200, 164, 78, 0.08);
  color: var(--accent);
  border-right: 2px solid var(--accent);
}
</style>
