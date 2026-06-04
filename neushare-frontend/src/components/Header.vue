<template>
  <header class="header">
    <div class="header-bg"></div>
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
        <router-link v-if="userStore.isLoggedIn" to="/upload" class="nav-item">上传资料</router-link>
      </nav>

      <div class="header-right">
        <template v-if="userStore.isLoggedIn">
          <el-dropdown trigger="click" @command="handleCommand" popper-class="header-dropdown">
            <span class="user-info">
              <el-avatar :size="34" :src="userStore.userInfo?.avatarUrl" class="user-avatar">
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
          <el-button class="btn-register" @click="router.push('/register')">注册</el-button>
        </template>
      </div>
    </div>
  </header>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useUserStore } from '@/store/modules/user'
import { ElMessageBox } from 'element-plus'
import { getInitial } from '@/utils/format'

const router = useRouter()
const userStore = useUserStore()

const handleCommand = (command) => {
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
  z-index: 100;
  height: 64px;
  border-bottom: 1px solid var(--border-subtle);
}

.header-bg {
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.78);
  backdrop-filter: blur(16px) saturate(180%);
  -webkit-backdrop-filter: blur(16px) saturate(180%);
}

.header-container {
  position: relative;
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 28px;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  user-select: none;
}

.logo-mark {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-xs);
  background: linear-gradient(135deg, var(--accent), var(--accent-dim));
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}

.logo-text {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.03em;
}

.nav-menu {
  display: flex;
  gap: 2px;
}

.nav-item {
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  padding: 8px 16px;
  border-radius: var(--radius-sm);
  transition: var(--transition-fast);
}

.nav-item:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.nav-item.router-link-active {
  color: var(--accent);
}

.header-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-login {
  background: transparent;
  border: 1px solid var(--border-strong);
  color: var(--text-primary);
  font-weight: 500;
}

.btn-login:hover {
  border-color: var(--accent);
  color: var(--accent-light);
}

.btn-register {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
  font-weight: 600;
}

.btn-register:hover {
  background: var(--accent-light);
  border-color: var(--accent-light);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 10px 4px 4px;
  border-radius: var(--radius-sm);
  transition: var(--transition-fast);
}

.user-info:hover {
  background: var(--bg-hover);
}

.user-avatar {
  background: var(--bg-elevated);
  color: var(--accent);
  font-weight: 600;
  font-size: 13px;
}

.username {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
}

.arrow-icon {
  color: var(--text-muted);
  font-size: 12px;
}
</style>
