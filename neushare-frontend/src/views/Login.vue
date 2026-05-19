<template>
  <div class="login-page">
    <div class="login-left">
      <div class="left-content">
        <div class="brand">
          <div class="brand-icon">
            <el-icon :size="22"><Reading /></el-icon>
          </div>
          <span class="brand-text">NeuShare</span>
        </div>
        <h1 class="left-title">校园资料<br>共享平台</h1>
        <p class="left-desc">发现、分享、交流——让学习更高效</p>
      </div>
    </div>
    <div class="login-right">
      <div class="login-container">
        <h2>欢迎回来</h2>
        <p class="login-subtitle">请输入您的账号信息</p>

        <el-form
          ref="loginFormRef"
          :model="loginForm"
          :rules="loginRules"
          class="login-form"
          @submit.prevent="handleLogin"
        >
          <el-form-item prop="username">
            <el-input
              v-model="loginForm.username"
              placeholder="请输入学号"
              size="large"
              prefix-icon="User"
            />
          </el-form-item>

          <el-form-item prop="password">
            <el-input
              v-model="loginForm.password"
              type="password"
              placeholder="请输入密码"
              size="large"
              prefix-icon="Lock"
              show-password
            />
          </el-form-item>

          <el-form-item>
            <el-checkbox v-model="rememberMe">记住我</el-checkbox>
          </el-form-item>

          <el-form-item>
            <el-button
              type="primary"
              size="large"
              :loading="loading"
              class="login-btn"
              @click="handleLogin"
            >
              登录
            </el-button>
          </el-form-item>
        </el-form>

        <div class="login-footer">
          <span>还没有账号？</span>
          <router-link to="/register">立即注册</router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/store/modules/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const loginFormRef = ref(null)
const loading = ref(false)
const rememberMe = ref(false)

const loginForm = reactive({
  username: '',
  password: ''
})

const loginRules = {
  username: [
    { required: true, message: '请输入学号', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少6位', trigger: 'blur' }
  ]
}

const handleLogin = async () => {
  const valid = await loginFormRef.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  try {
    await userStore.login(loginForm)
    ElMessage.success('登录成功')
    const redirect = route.query.redirect || '/'
    router.push(redirect)
  } catch (error) {
    console.error('Login failed:', error)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: calc(100vh - 64px);
  display: flex;
}

.login-left {
  flex: 1;
  background:
    radial-gradient(ellipse at 30% 50%, rgba(200, 164, 78, 0.06) 0%, transparent 60%),
    var(--bg-base);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px;
  border-right: 1px solid var(--border-subtle);
}

.left-content {
  max-width: 380px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 40px;
}

.brand-icon {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  background: linear-gradient(135deg, var(--accent), var(--accent-dim));
  display: flex;
  align-items: center;
  justify-content: center;
  color: #0d1117;
}

.brand-text {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
}

.left-title {
  font-size: 44px;
  font-weight: 800;
  color: var(--text-primary);
  margin-bottom: 16px;
  line-height: 1.15;
  letter-spacing: -0.04em;
}

.left-desc {
  font-size: 16px;
  color: var(--text-muted);
}

.login-right {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px;
  background: var(--bg-deep);
}

.login-container {
  width: 100%;
  max-width: 380px;
}

.login-container h2 {
  font-size: 26px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 6px;
  letter-spacing: -0.02em;
}

.login-subtitle {
  color: var(--text-muted);
  font-size: 15px;
  margin-bottom: 36px;
}

.login-btn {
  width: 100%;
  font-weight: 600;
}

.login-footer {
  text-align: center;
  margin-top: 28px;
  color: var(--text-muted);
  font-size: 14px;
}

.login-footer a {
  color: var(--accent);
  text-decoration: none;
  margin-left: 4px;
  font-weight: 500;
}

.login-footer a:hover {
  color: var(--accent-light);
}

@media (max-width: 768px) {
  .login-left {
    display: none;
  }
}
</style>
