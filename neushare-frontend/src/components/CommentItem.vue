<template>
  <div class="comment-item" v-if="!comment.deleted">
    <div class="comment-main">
      <el-avatar :size="28" :src="comment.avatarUrl">{{ initials }}</el-avatar>
      <div class="comment-body">
        <div class="comment-head">
          <span class="comment-name">{{ comment.nickname || '匿名' }}</span>
          <span class="comment-time">{{ formatTime(comment.createTime) }}</span>
          <el-button v-if="userStore.isLoggedIn" link type="primary" size="small" @click="$emit('reply', comment)">
            回复
          </el-button>
        </div>
        <div class="comment-content">{{ comment.content }}</div>
      </div>
    </div>
    <div v-if="comment.children && comment.children.length" class="comment-children">
      <CommentItem
        v-for="child in comment.children"
        :key="child.id"
        :comment="child"
        @reply="(c) => $emit('reply', c)"
      />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { formatTime, getInitial } from '@/utils/format'
import { useUserStore } from '@/store/modules/user'

defineOptions({ name: 'CommentItem' })

const props = defineProps({
  comment: { type: Object, required: true }
})
defineEmits(['reply'])

const userStore = useUserStore()
const initials = computed(() => getInitial(props.comment.nickname || '匿'))
</script>

<style scoped>
.comment-item {
  padding: var(--space-3) 0;
  border-bottom: 1px solid var(--border-subtle);
}

.comment-main {
  display: flex;
  gap: var(--space-3);
}

.comment-body {
  flex: 1;
  min-width: 0;
}

.comment-head {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: 2px;
}

.comment-name {
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  color: var(--text-primary);
}

.comment-time {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.comment-content {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  line-height: var(--leading-normal);
  white-space: pre-wrap;
  word-break: break-word;
}

.comment-children {
  margin-left: var(--space-8);
  margin-top: var(--space-2);
  padding-left: var(--space-3);
  border-left: 2px solid var(--border-subtle);
}
</style>
