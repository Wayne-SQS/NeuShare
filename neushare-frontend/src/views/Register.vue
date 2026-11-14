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
        <h1 class="auth-title">加入我们</h1>
        <p class="auth-desc">注册账号，开始整理和分享你的学习资料。</p>
        <ul class="auth-points">
          <li>上传课程笔记、真题与课件</li>
          <li>收藏需要的资料，随时回看</li>
          <li>关注同学，获取同专业资料更新</li>
        </ul>
      </div>
    </aside>

    <main class="auth-main">
      <div class="auth-card">
        <h2 class="auth-card__title">创建账号</h2>
        <p class="auth-card__subtitle">填写以下信息完成注册</p>

        <el-form
          ref="registerFormRef"
          :model="registerForm"
          :rules="registerRules"
          class="auth-form"
          label-position="top"
          @submit.prevent="handleRegister"
        >
          <el-form-item prop="username">
            <el-input
              v-model="registerForm.username"
              placeholder="请输入学号"
              prefix-icon="User"
            />
          </el-form-item>

          <el-form-item prop="nickname">
            <el-input
              v-model="registerForm.nickname"
              placeholder="请输入昵称"
              prefix-icon="UserFilled"
            />
          </el-form-item>

          <el-form-item prop="password">
            <el-input
              v-model="registerForm.password"
              type="password"
              placeholder="请输入密码"
              prefix-icon="Lock"
              show-password
            />
          </el-form-item>

          <el-form-item prop="confirmPassword">
            <el-input
              v-model="registerForm.confirmPassword"
              type="password"
              placeholder="请确认密码"
              prefix-icon="Lock"
              show-password
            />
          </el-form-item>

          <div class="auth-row">
            <el-form-item prop="college" class="auth-row__item">
              <el-select v-model="registerForm.college" placeholder="请选择学院">
                <el-option v-for="c in colleges" :key="c" :label="c" :value="c" />
              </el-select>
            </el-form-item>

            <el-form-item prop="grade" class="auth-row__item">
              <el-select v-model="registerForm.grade" placeholder="请选择年级">
                <el-option label="大一" :value="1" />
                <el-option label="大二" :value="2" />
                <el-option label="大三" :value="3" />
                <el-option label="大四" :value="4" />
              </el-select>
            </el-form-item>
          </div>

          <el-form-item>
            <el-button
              type="primary"
              size="large"
              :loading="loading"
              class="auth-submit"
              @click="handleRegister"
            >
              注册
            </el-button>
          </el-form-item>
        </el-form>

        <div class="auth-footer">
          <span>已有账号？</span>
          <router-link to="/login">立即登录</router-link>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { register } from '@/api/auth'

const router = useRouter()

const colleges = ['软件学院', '计算机学院', '信息学院', '数学学院']

const registerFormRef = ref(null)
const loading = ref(false)

const registerForm = reactive({
  username: '',
  nickname: '',
  password: '',
  confirmPassword: '',
  college: '',
  grade: null
})

const validateConfirmPassword = (rule, value, callback) => {
  if (value !== registerForm.password) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const registerRules = {
  username: [
    { required: true, message: '请输入学号', trigger: 'blur' }
  ],
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认密码', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' }
  ],
  college: [
    { required: true, message: '请选择学院', trigger: 'change' }
  ],
  grade: [
    { required: true, message: '请选择年级', trigger: 'change' }
  ]
}

const handleRegister = async () => {
  const valid = await registerFormRef.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  try {
    await register({
      username: registerForm.username,
      nickname: registerForm.nickname,
      password: registerForm.password,
      college: registerForm.college,
      grade: registerForm.grade
    })
    ElMessage.success('注册成功，请登录')
    router.push('/login')
  } catch (error) {
    console.error('Register failed:', error)
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
  max-width: 420px;
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
  margin-bottom: var(--space-6);
}

.auth-form {
  display: flex;
  flex-direction: column;
}

.auth-form :deep(.el-form-item) {
  margin-bottom: var(--space-4);
}

.auth-row {
  display: flex;
  gap: var(--space-3);
}

.auth-row__item {
  flex: 1;
  min-width: 0;
}

.auth-row__item :deep(.el-select) {
  width: 100%;
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

  .auth-row {
    flex-direction: column;
    gap: 0;
  }
}
</style>
