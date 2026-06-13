import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/store/modules/user'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { title: '登录', guest: true }
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/Register.vue'),
    meta: { title: '注册', guest: true }
  },
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue'),
    meta: { title: '首页' }
  },
  {
    path: '/resource',
    name: 'ResourceList',
    component: () => import('@/views/ResourceList.vue'),
    meta: { title: '资源广场' }
  },
  {
    path: '/resource/:id',
    name: 'ResourceDetail',
    component: () => import('@/views/ResourceDetail.vue'),
    meta: { title: '资料详情' }
  },
  {
    path: '/upload',
    name: 'Upload',
    component: () => import('@/views/Upload.vue'),
    meta: { title: '上传资料', requiresAuth: true }
  },
  {
    path: '/upload/:id',
    name: 'EditUpload',
    component: () => import('@/views/Upload.vue'),
    meta: { title: '编辑资料', requiresAuth: true }
  },
  {
    path: '/profile',
    component: () => import('@/views/profile/Layout.vue'),
    meta: { requiresAuth: true },
    redirect: '/profile/info',
    children: [
      {
        path: 'resources',
        name: 'MyResources',
        component: () => import('@/views/profile/MyResources.vue'),
        meta: { title: '我的资料' }
      },
      {
        path: 'favorites',
        name: 'MyFavorites',
        component: () => import('@/views/profile/MyFavorites.vue'),
        meta: { title: '我的收藏' }
      },
      {
        path: 'info',
        name: 'ProfileInfo',
        component: () => import('@/views/profile/ProfileInfo.vue'),
        meta: { title: '个人资料' }
      }
    ]
  },
  {
    path: '/admin',
    component: () => import('@/views/admin/Layout.vue'),
    meta: { requiresAuth: true, requiresAdmin: true },
    redirect: '/admin/dashboard',
    children: [
      {
        path: 'audit',
        name: 'Audit',
        component: () => import('@/views/admin/Audit.vue'),
        meta: { title: '资料审核' }
      },
      {
        path: 'users',
        name: 'UserManage',
        component: () => import('@/views/admin/UserManage.vue'),
        meta: { title: '用户管理' }
      },
      {
        path: 'banners',
        name: 'BannerManage',
        component: () => import('@/views/admin/BannerManage.vue'),
        meta: { title: '轮播配置' }
      },
      {
        path: 'cards',
        name: 'FormCardManage',
        component: () => import('@/views/admin/FormCardManage.vue'),
        meta: { title: '卡片管理' }
      },
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/admin/Dashboard.vue'),
        meta: { title: '数据统计' }
      }
    ]
  },
  {
    path: '/user/:id',
    name: 'UserProfile',
    component: () => import('@/views/UserProfile.vue'),
    meta: { title: '用户主页' }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/NotFound.vue'),
    meta: { title: '页面不存在' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    }
    return { top: 0 }
  }
})

router.beforeEach((to, from, next) => {
  document.title = to.meta.title ? `${to.meta.title} - NeuShare` : 'NeuShare'

  const userStore = useUserStore()
  const isLoggedIn = userStore.isLoggedIn
  const isAdmin = userStore.isAdmin

  if (to.meta.requiresAuth && !isLoggedIn) {
    next({ path: '/login', query: { redirect: to.fullPath } })
  } else if (to.meta.requiresAdmin && !isAdmin) {
    next('/')
  } else if (to.meta.guest && isLoggedIn) {
    next('/')
  } else {
    next()
  }
})

export default router
