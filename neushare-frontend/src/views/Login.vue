<template>
  <div class="auth-page">
    <aside class="auth-aside">
      <div class="auth-aside__inner">
        <div class="auth-brand">
          <div class="auth-brand__mark">
            <el-icon :size="18"><Reading /></el-icon>
          </div>
          <span class="auth-brand__text">NeuShare</span>
        </div>
        <h1 class="auth-title">校园资料<br>共享平台</h1>
        <p class="auth-desc">发现、分享、交流，让每一次复习都有据可依。</p>
        <ul class="auth-points">
          <li>覆盖各年级各学期课程资料</li>
          <li>分类检索，快速定位所需内容</li>
          <li>评论、收藏，与同学一起完善笔记</li>
        </ul>
      </div>
    </aside>

    <main class="auth-main">
      <div class="auth-card">
        <h2 class="auth-card__title">欢迎回来</h2>
        <p class="auth-card__subtitle">请输入您的账号信息</p>

        <el-form
          ref="loginFormRef"
          :model="loginForm"
          :rules="loginRules"
          class="auth-form"
          label-position="top"
          @submit.prevent="handleLogin"
        >
          <el-form-item prop="username">
            <el-input
              v-model="loginForm.username"
              placeholder="请输入学号"
              prefix-icon="User"
            />
          </el-form-item>

          <el-form-item prop="password">
            <el-input
              v-model="loginForm.password"
              type="password"
              placeholder="请输入密码"
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
              class="auth-submit"
              @click="handleLogin"
            >
              登录
            </el-button>
          </el-form-item>
        </el-form>

        <div class="auth-footer">
          <span>还没有账号？</span>
          <router-link to="/register">立即注册</router-link>
        </div>
      </div>
    </main>
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
.auth-page {
  min-height: calc(100vh - var(--header-height));
  display: flex;
  background: var(--bg-base);
}

.auth-aside {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-10) var(--space-8);
  background: var(--bg-deep);
  border-right: 1px solid var(--border-default);
}

.auth-aside__inner {
  max-width: 380px;
}

.auth-brand {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-8);
}

.auth-brand__mark {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-sm);
  background: var(--accent);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-inverse);
}

.auth-brand__text {
  font-size: var(--text-lg);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

.auth-title {
  font-size: var(--text-display);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  margin-bottom: var(--space-4);
  line-height: 1.2;
  letter-spacing: -0.03em;
}

.auth-desc {
  font-size: var(--text-base);
  color: var(--text-secondary);
  line-height: var(--leading-relaxed);
  margin-bottom: var(--space-7);
}

.auth-points {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.auth-points li {
  position: relative;
  padding-left: var(--space-5);
  font-size: var(--text-sm);
  color: var(--text-secondary);
}

.auth-points li::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  width: 6px;
  height: 6px;
  margin-top: -3px;
  border-radius: 50%;
  background: var(--border-strong);
}

.auth-main {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-10) var(--space-8);
  background: var(--bg-base);
}

.auth-card {
  width: 100%;
  max-width: 380px;
}

.auth-card__title {
  font-size: var(--heading-2);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin-bottom: var(--space-1);
}

.auth-card__subtitle {
  color: var(--text-secondary);
  font-size: var(--text-sm);
  margin-bottom: var(--space-7);
}

.auth-form {
  display: flex;
  flex-direction: column;
}

.auth-form :deep(.el-form-item) {
  margin-bottom: var(--space-5);
}

.auth-submit {
  width: 100%;
  font-weight: var(--font-semibold);
}

.auth-footer {
  text-align: center;
  margin-top: var(--space-5);
  color: var(--text-secondary);
  font-size: var(--text-sm);
}

.auth-footer a {
  color: var(--accent);
  margin-left: var(--space-1);
  font-weight: var(--font-medium);
}

.auth-footer a:hover {
  color: var(--accent-dim);
}

@media (max-width: 900px) {
  .auth-aside {
    padding: var(--space-8) var(--space-6);
  }

  .auth-title {
    font-size: var(--text-3xl);
  }
}

@media (max-width: 767px) {
  .auth-page {
    min-height: calc(100vh - var(--header-height));
  }

  .auth-aside {
    display: none;
  }

  .auth-main {
    padding: var(--space-8) var(--space-4);
    align-items: flex-start;
  }
}
</style>
