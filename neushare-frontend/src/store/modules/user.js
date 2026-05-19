import { defineStore } from 'pinia'
import { login as loginApi, getUserInfo } from '@/api/auth'
import router from '@/router'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    userInfo: JSON.parse(localStorage.getItem('user') || 'null')
  }),

  getters: {
    isLoggedIn: (state) => !!state.token,
    isAdmin: (state) => state.userInfo?.role === 'admin',
    username: (state) => state.userInfo?.username || '',
    userId: (state) => state.userInfo?.id || null
  },

  actions: {
    async login(loginForm) {
      const res = await loginApi(loginForm.username, loginForm.password)
      this.token = res.data.token
      this.userInfo = res.data.user
      localStorage.setItem('token', res.data.token)
      localStorage.setItem('user', JSON.stringify(res.data.user))
      return res
    },

    logout() {
      this.token = ''
      this.userInfo = null
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      router.push('/login')
    },

    async fetchUserInfo() {
      try {
        const res = await getUserInfo()
        this.userInfo = res.data
        localStorage.setItem('user', JSON.stringify(res.data))
        return res
      } catch (error) {
        this.token = ''
        this.userInfo = null
        localStorage.removeItem('token')
        localStorage.removeItem('user')
        throw error
      }
    },

    setUserInfo(userInfo) {
      this.userInfo = userInfo
      localStorage.setItem('user', JSON.stringify(userInfo))
    }
  }
})
