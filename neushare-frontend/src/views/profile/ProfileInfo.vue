<template>
  <div class="profile-info-page">
    <section class="panel">
      <div class="panel-head">
        <h3 class="panel-title">个人资料</h3>
        <p class="panel-subtitle">更新后立即生效，昵称将展示在资料与评论中</p>
      </div>

      <el-form
        ref="formRef"
        :model="profileForm"
        :rules="profileRules"
        label-position="top"
        class="profile-form"
      >
        <el-form-item label="头像">
          <div class="avatar-upload">
            <el-avatar :size="72" :src="profileForm.avatarUrl">
              {{ getInitial(profileForm.nickname) }}
            </el-avatar>
            <span class="avatar-hint">暂不支持在线更换头像</span>
          </div>
        </el-form-item>

        <el-form-item label="学号">
          <el-input :value="profileForm.username" disabled />
        </el-form-item>

        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="profileForm.nickname" placeholder="请输入昵称" />
        </el-form-item>

        <div class="form-row">
          <el-form-item label="学院" prop="college" class="form-row__item">
            <el-select v-model="profileForm.college" placeholder="请选择学院">
              <el-option v-for="c in colleges" :key="c" :label="c" :value="c" />
            </el-select>
          </el-form-item>

          <el-form-item label="年级" prop="grade" class="form-row__item">
            <el-select v-model="profileForm.grade" placeholder="请选择年级">
              <el-option label="大一" :value="1" />
              <el-option label="大二" :value="2" />
              <el-option label="大三" :value="3" />
              <el-option label="大四" :value="4" />
            </el-select>
          </el-form-item>
        </div>

        <el-form-item label="角色">
          <el-tag effect="plain">{{ getRoleText(profileForm.role) }}</el-tag>
        </el-form-item>

        <div class="form-actions">
          <el-button type="primary" :loading="saving" @click="handleSave">
            保存修改
          </el-button>
        </div>
      </el-form>
    </section>

    <section class="panel password-panel">
      <div class="panel-head">
        <h3 class="panel-title">修改密码</h3>
        <p class="panel-subtitle">修改后需要使用新密码重新登录</p>
      </div>

      <el-form
        ref="passwordFormRef"
        :model="passwordForm"
        :rules="passwordRules"
        label-position="top"
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

        <div class="form-actions">
          <el-button type="primary" :loading="changingPassword" @click="handleChangePassword">
            修改密码
          </el-button>
        </div>
      </el-form>
    </section>
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
.panel-head {
  margin-bottom: var(--space-5);
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
}

.panel-subtitle {
  margin-top: var(--space-1);
  font-size: var(--text-xs);
  color: var(--text-secondary);
}

.profile-form {
  max-width: 520px;
}

.profile-form :deep(.el-form-item) {
  margin-bottom: var(--space-5);
}

.avatar-upload {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.avatar-hint {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.form-row {
  display: flex;
  gap: var(--space-4);
}

.form-row__item {
  flex: 1;
  min-width: 0;
}

.form-row__item :deep(.el-select) {
  width: 100%;
}

.form-actions {
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
}

.password-panel {
  margin-top: var(--space-4);
}

@media (max-width: 767px) {
  .profile-form {
    max-width: none;
  }

  .form-row {
    flex-direction: column;
    gap: 0;
  }

  .form-actions .el-button {
    width: 100%;
  }
}
</style>
