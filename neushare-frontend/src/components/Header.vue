<template>
  <header class="header">
    <div class="header-container">
      <div class="logo" @click="router.push('/')">
        <div class="logo-mark">
          <el-icon :size="18"><Reading /></el-icon>
        </div>
        <span class="logo-text">NeuShare</span>
      </div>

      <nav class="nav-menu">
        <router-link to="/" class="nav-item">首页</router-link>
        <router-link to="/resource" class="nav-item">资源广场</router-link>
        <router-link to="/community" class="nav-item">社区</router-link>
        <router-link to="/postgrad-guide" class="nav-item">考研指南</router-link>
        <router-link v-if="userStore.isLoggedIn" to="/upload" class="nav-item">上传资料</router-link>
        <router-link v-if="userStore.isLoggedIn" to="/ai" class="nav-item">AI助手</router-link>
      </nav>

      <div class="header-right">
        <template v-if="userStore.isLoggedIn">
          <el-dropdown trigger="click" @command="handleCommand" popper-class="header-dropdown">
            <span class="user-info">
              <el-avatar :size="32" :src="userStore.userInfo?.avatarUrl" class="user-avatar">
                {{ getInitial(userStore.userInfo?.nickname || userStore.username) }}
              </el-avatar>
              <span class="username">{{ userStore.userInfo?.nickname || userStore.username }}</span>
              <el-icon class="arrow-icon"><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile"><el-icon><User /></el-icon>个人中心</el-dropdown-item>
                <el-dropdown-item command="resources"><el-icon><Document /></el-icon>我的资料</el-dropdown-item>
                <el-dropdown-item command="favorites"><el-icon><Star /></el-icon>我的收藏</el-dropdown-item>
                <el-dropdown-item v-if="userStore.isAdmin" command="admin" divided><el-icon><Setting /></el-icon>管理后台</el-dropdown-item>
                <el-dropdown-item command="logout" divided><el-icon><SwitchButton /></el-icon>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </template>
        <template v-else>
          <el-button class="btn-login" @click="router.push('/login')">登录</el-button>
          <el-button class="btn-register" type="primary" @click="router.push('/register')">注册</el-button>
        </template>

        <button class="menu-toggle" type="button" aria-label="打开菜单" @click="menuVisible = true">
          <el-icon :size="20"><Menu /></el-icon>
        </button>
      </div>
    </div>

    <el-drawer
      v-model="menuVisible"
      direction="rtl"
      size="280px"
      :with-header="false"
    >
      <div class="drawer-head">
        <div class="logo-mark">
          <el-icon :size="18"><Reading /></el-icon>
        </div>
        <span class="logo-text">NeuShare</span>
      </div>

      <nav class="drawer-nav">
        <router-link to="/" class="drawer-item">首页</router-link>
        <router-link to="/resource" class="drawer-item">资源广场</router-link>
        <router-link to="/community" class="drawer-item">社区</router-link>
        <router-link to="/postgrad-guide" class="drawer-item">考研指南</router-link>
        <router-link v-if="userStore.isLoggedIn" to="/upload" class="drawer-item">上传资料</router-link>
        <router-link v-if="userStore.isLoggedIn" to="/ai" class="drawer-item">AI助手</router-link>
        <template v-if="userStore.isLoggedIn">
          <router-link to="/profile/info" class="drawer-item">个人中心</router-link>
          <router-link to="/profile/resources" class="drawer-item">我的资料</router-link>
          <router-link to="/profile/favorites" class="drawer-item">我的收藏</router-link>
          <router-link v-if="userStore.isAdmin" to="/admin/dashboard" class="drawer-item">管理后台</router-link>
        </template>
      </nav>

      <div class="drawer-actions">
        <template v-if="userStore.isLoggedIn">
          <el-button class="drawer-btn" @click="handleCommand('logout')">退出登录</el-button>
        </template>
        <template v-else>
          <el-button class="drawer-btn" @click="go('/login')">登录</el-button>
          <el-button class="drawer-btn" type="primary" @click="go('/register')">注册</el-button>
        </template>
      </div>
    </el-drawer>
  </header>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/store/modules/user'
import { ElMessageBox } from 'element-plus'
import { getInitial } from '@/utils/format'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const menuVisible = ref(false)

watch(() => route.fullPath, () => {
  menuVisible.value = false
})

const go = (path) => {
  menuVisible.value = false
  router.push(path)
}

const handleCommand = (command) => {
  menuVisible.value = false
  switch (command) {
    case 'profile': router.push('/profile/info'); break
    case 'resources': router.push('/profile/resources'); break
    case 'favorites': router.push('/profile/favorites'); break
    case 'admin': router.push('/admin/dashboard'); break
    case 'logout':
      ElMessageBox.confirm('确定要退出登录吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => { userStore.logout() }).catch(() => {})
      break
  }
}
</script>

<style scoped>
.header {
  position: sticky;
  top: 0;
  z-index: var(--z-sticky);
  height: var(--header-height);
  background: var(--bg-overlay);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-bottom: 1px solid var(--border-default);
}

.header-container {
  max-width: var(--container-max);
  margin: 0 auto;
  padding: 0 var(--space-6);
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-6);
}

.logo {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  cursor: pointer;
  user-select: none;
  flex-shrink: 0;
}

.logo-mark {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-sm);
  background: var(--accent);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-inverse);
  flex-shrink: 0;
}

.logo-text {
  font-size: var(--text-lg);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

.nav-menu {
  display: flex;
  gap: var(--space-1);
  flex: 1;
}

.nav-item {
  color: var(--text-secondary);
  text-decoration: none;
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  padding: var(--space-2) var(--space-4);
  border-radius: var(--radius-sm);
  transition: var(--transition-fast);
  white-space: nowrap;
}

.nav-item:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.nav-item.router-link-active {
  color: var(--accent);
  background: var(--info-bg);
}

.header-right {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-shrink: 0;
}

.btn-login {
  background: transparent;
  border-color: var(--border-strong);
  color: var(--text-primary);
}

.btn-login:hover {
  border-color: var(--accent);
  color: var(--accent);
}

.user-info {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  cursor: pointer;
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-sm);
  transition: var(--transition-fast);
}

.user-info:hover {
  background: var(--bg-hover);
}

.user-avatar {
  background: var(--bg-deep);
  color: var(--accent);
  font-weight: var(--font-semibold);
  font-size: var(--text-sm);
}

.username {
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  color: var(--text-primary);
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.arrow-icon {
  color: var(--text-muted);
  font-size: var(--text-xs);
}

.menu-toggle {
  display: none;
  width: 36px;
  height: 36px;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--border-default);
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--text-primary);
  cursor: pointer;
}

.menu-toggle:hover {
  border-color: var(--border-strong);
  background: var(--bg-hover);
}

/* Drawer */
.drawer-head {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
}

.drawer-nav {
  display: flex;
  flex-direction: column;
  padding: var(--space-3) 0;
}

.drawer-item {
  padding: var(--space-3) var(--space-2);
  color: var(--text-secondary);
  font-size: var(--text-base);
  font-weight: var(--font-medium);
  border-radius: var(--radius-sm);
}

.drawer-item:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.drawer-item.router-link-active {
  color: var(--accent);
  background: var(--info-bg);
}

.drawer-actions {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  margin-top: var(--space-4);
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
}

.drawer-btn {
  width: 100%;
  margin-left: 0;
}

@media (max-width: 767px) {
  .header-container {
    padding: 0 var(--space-4);
  }

  .nav-menu {
    display: none;
  }

  .menu-toggle {
    display: flex;
  }

  .username {
    display: none;
  }
}
</style>
