export function formatTime(time) {
  if (!time) return ''
  const now = Date.now()
  const date = new Date(time)
  const diff = now - date.getTime()
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))

  if (days === 0) {
    const hours = Math.floor(diff / (1000 * 60 * 60))
    if (hours === 0) {
      const minutes = Math.floor(diff / (1000 * 60))
      return minutes <= 0 ? '刚刚' : `${minutes}分钟前`
    }
    return `${hours}小时前`
  } else if (days < 7) {
    return `${days}天前`
  }
  return date.toLocaleDateString()
}

export function getInitial(name) {
  return name?.charAt(0)?.toUpperCase() || '?'
}
