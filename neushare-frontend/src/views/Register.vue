<template>
  <div class="register-page">
    <div class="register-left">
      <div class="left-content">
        <div class="brand">
          <div class="brand-icon">
            <el-icon :size="22"><Reading /></el-icon>
          </div>
          <span class="brand-text">NeuShare</span>
        </div>
        <h1 class="left-title">加入我们</h1>
        <p class="left-desc">注册账号，开始分享你的学习资料</p>
      </div>
    </div>
    <div class="register-right">
      <div class="register-container">
        <h2>创建账号</h2>
        <p class="register-subtitle">填写以下信息完成注册</p>

        <el-form
          ref="registerFormRef"
          :model="registerForm"
          :rules="registerRules"
          class="register-form"
          @submit.prevent="handleRegister"
        >
          <el-form-item prop="username">
            <el-input
              v-model="registerForm.username"
              placeholder="请输入学号"
              size="large"
              prefix-icon="User"
            />
          </el-form-item>

          <el-form-item prop="nickname">
            <el-input
              v-model="registerForm.nickname"
              placeholder="请输入昵称"
              size="large"
              prefix-icon="UserFilled"
            />
          </el-form-item>

          <el-form-item prop="password">
            <el-input
              v-model="registerForm.password"
              type="password"
              placeholder="请输入密码"
              size="large"
              prefix-icon="Lock"
              show-password
            />
          </el-form-item>

          <el-form-item prop="confirmPassword">
            <el-input
              v-model="registerForm.confirmPassword"
              type="password"
              placeholder="请确认密码"
              size="large"
              prefix-icon="Lock"
              show-password
            />
          </el-form-item>

          <div class="form-row">
            <el-form-item prop="college" class="form-row-item">
              <el-select
                v-model="registerForm.college"
                placeholder="请选择学院"
                size="large"
                style="width: 100%"
              >
                <el-option v-for="c in colleges" :key="c" :label="c" :value="c" />
              </el-select>
            </el-form-item>

            <el-form-item prop="grade" class="form-row-item">
              <el-select
                v-model="registerForm.grade"
                placeholder="请选择年级"
                size="large"
                style="width: 100%"
              >
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
              class="register-btn"
              @click="handleRegister"
            >
              注册
            </el-button>
          </el-form-item>
        </el-form>

        <div class="register-footer">
          <span>已有账号？</span>
          <router-link to="/login">立即登录</router-link>
        </div>
      </div>
    </div>
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
.register-page {
  min-height: calc(100vh - 64px);
  display: flex;
}

.register-left {
  flex: 1;
  background:
    radial-gradient(ellipse at 70% 40%, rgba(200, 164, 78, 0.06) 0%, transparent 60%),
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
  color: #fff;
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

.register-right {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px;
  background: var(--bg-deep);
}

.register-container {
  width: 100%;
  max-width: 420px;
}

.register-container h2 {
  font-size: 26px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 6px;
  letter-spacing: -0.02em;
}

.register-subtitle {
  color: var(--text-muted);
  font-size: 15px;
  margin-bottom: 36px;
}

.form-row {
  display: flex;
  gap: 12px;
}

.form-row-item {
  flex: 1;
}

.register-btn {
  width: 100%;
  font-weight: 600;
}

.register-footer {
  text-align: center;
  margin-top: 28px;
  color: var(--text-muted);
  font-size: 14px;
}

.register-footer a {
  color: var(--accent);
  text-decoration: none;
  margin-left: 4px;
  font-weight: 500;
}

.register-footer a:hover {
  color: var(--accent-light);
}

@media (max-width: 768px) {
  .register-left {
    display: none;
  }
  .form-row {
    flex-direction: column;
    gap: 0;
  }
}
</style>
