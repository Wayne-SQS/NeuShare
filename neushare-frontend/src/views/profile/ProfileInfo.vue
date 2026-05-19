<template>
  <div class="profile-info-page">
    <div class="info-card">
      <div class="card-header">
        <span>个人资料</span>
      </div>

      <el-form
        ref="formRef"
        :model="profileForm"
        :rules="profileRules"
        label-width="100px"
        class="profile-form"
      >
        <el-form-item label="头像">
          <div class="avatar-upload">
            <el-avatar :size="80" :src="profileForm.avatarUrl">
              {{ getInitial(profileForm.nickname) }}
            </el-avatar>
          </div>
        </el-form-item>

        <el-form-item label="学号">
          <el-input :value="profileForm.username" disabled />
        </el-form-item>

        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="profileForm.nickname" placeholder="请输入昵称" />
        </el-form-item>

        <el-form-item label="学院" prop="college">
          <el-select v-model="profileForm.college" placeholder="请选择学院" style="width: 100%">
            <el-option v-for="c in colleges" :key="c" :label="c" :value="c" />
          </el-select>
        </el-form-item>

        <el-form-item label="年级" prop="grade">
          <el-select v-model="profileForm.grade" placeholder="请选择年级" style="width: 100%">
            <el-option label="大一" :value="1" />
            <el-option label="大二" :value="2" />
            <el-option label="大三" :value="3" />
            <el-option label="大四" :value="4" />
          </el-select>
        </el-form-item>

        <el-form-item label="角色">
          <el-tag>{{ getRoleText(profileForm.role) }}</el-tag>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" :loading="saving" @click="handleSave">
            保存修改
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="info-card password-card">
      <div class="card-header">
        <span>修改密码</span>
      </div>

      <el-form
        ref="passwordFormRef"
        :model="passwordForm"
        :rules="passwordRules"
        label-width="100px"
        class="profile-form"
      >
        <el-form-item label="原密码" prop="oldPassword">
          <el-input
            v-model="passwordForm.oldPassword"
            type="password"
            placeholder="请输入原密码"
            show-password
          />
        </el-form-item>

        <el-form-item label="新密码" prop="newPassword">
          <el-input
            v-model="passwordForm.newPassword"
            type="password"
            placeholder="请输入新密码"
            show-password
          />
        </el-form-item>

        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input
            v-model="passwordForm.confirmPassword"
            type="password"
            placeholder="请确认新密码"
            show-password
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" :loading="changingPassword" @click="handleChangePassword">
            修改密码
          </el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/store/modules/user'
import { updateUserInfo, updatePassword } from '@/api/auth'
import { getInitial } from '@/utils/format'
import { ROLE_MAP } from '@/utils/constants'

const userStore = useUserStore()
const formRef = ref(null)
const passwordFormRef = ref(null)
const saving = ref(false)
const changingPassword = ref(false)

const colleges = ['软件学院', '计算机学院', '信息学院', '数学学院']

const profileForm = reactive({
  username: '',
  nickname: '',
  avatarUrl: '',
  college: '',
  grade: null,
  role: ''
})

const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const profileRules = {
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 20, message: '昵称长度为2-20个字符', trigger: 'blur' }
  ],
  college: [
    { required: true, message: '请选择学院', trigger: 'change' }
  ],
  grade: [
    { required: true, message: '请选择年级', trigger: 'change' }
  ]
}

const validateConfirmPassword = (rule, value, callback) => {
  if (value !== passwordForm.newPassword) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const passwordRules = {
  oldPassword: [
    { required: true, message: '请输入原密码', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' }
  ]
}

const getRoleText = (role) => ROLE_MAP[role] || role

const initForm = () => {
  const user = userStore.userInfo
  if (user) {
    profileForm.username = user.username || ''
    profileForm.nickname = user.nickname || ''
    profileForm.avatarUrl = user.avatarUrl || ''
    profileForm.college = user.college || ''
    profileForm.grade = user.grade || null
    profileForm.role = user.role || ''
  }
}

const handleSave = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  saving.value = true
  try {
    await updateUserInfo({
      nickname: profileForm.nickname,
      avatarUrl: profileForm.avatarUrl,
      college: profileForm.college,
      grade: profileForm.grade
    })
    userStore.setUserInfo({
      ...userStore.userInfo,
      nickname: profileForm.nickname,
      avatarUrl: profileForm.avatarUrl,
      college: profileForm.college,
      grade: profileForm.grade
    })
    ElMessage.success('保存成功')
  } catch (error) {
    console.error('Failed to save:', error)
  } finally {
    saving.value = false
  }
}

const handleChangePassword = async () => {
  const valid = await passwordFormRef.value.validate().catch(() => false)
  if (!valid) return

  changingPassword.value = true
  try {
    await updatePassword(passwordForm.oldPassword, passwordForm.newPassword)
    ElMessage.success('密码修改成功')
    passwordFormRef.value.resetFields()
  } catch (error) {
    console.error('Failed to change password:', error)
  } finally {
    changingPassword.value = false
  }
}

onMounted(() => {
  initForm()
})
</script>

<style scoped>
.info-card {
  background: var(--bg-surface);
  padding: 28px 32px;
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-subtle);
}

.card-header {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 24px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border-subtle);
}

.profile-form {
  max-width: 500px;
  padding: 0;
}

.avatar-upload {
  display: flex;
  align-items: center;
  gap: 16px;
}

.password-card {
  margin-top: 20px;
}
</style>
