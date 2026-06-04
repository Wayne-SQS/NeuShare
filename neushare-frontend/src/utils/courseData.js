export const colleges = [
  { id: 1, name: '软件学院' },
  { id: 2, name: '计算机学院' },
  { id: 3, name: '信息学院' },
  { id: 4, name: '数学学院' }
]

export const grades = [
  { id: 1, name: '大一' },
  { id: 2, name: '大二' },
  { id: 3, name: '大三' },
  { id: 4, name: '大四' }
]

export const semesters = [
  { id: 1, name: '上学期' },
  { id: 2, name: '下学期' }
]

// categoryId 对应数据库 category 表：
// 1-高等数学 2-线性代数 3-程序设计基础(C语言) 4-面向对象程序设计(JAVA)
// 5-数据结构与算法 6-计算机组成原理 7-操作系统 8-计算机网络
// 9-数据库原理 10-软件工程 11-Python程序设计 12-Web开发技术

export const coursesByGrade = {
  '1-1': [
    { id: 1, name: '高等数学', categoryId: 1 },
    { id: 2, name: '线性代数', categoryId: 2 },
    { id: 3, name: '程序设计基础', categoryId: 3 },
    { id: 4, name: '大学英语', categoryId: null },
    { id: 5, name: '思想道德与法治', categoryId: null }
  ],
  '1-2': [
    { id: 6, name: '面向对象程序设计（JAVA）', categoryId: 4 },
    { id: 7, name: '高等数学（下）', categoryId: 1 },
    { id: 8, name: '大学物理', categoryId: null },
    { id: 9, name: '中国近现代史纲要', categoryId: null }
  ],
  '2-1': [
    { id: 10, name: '数据结构与算法', categoryId: 5 },
    { id: 11, name: '计算机组成原理', categoryId: 6 },
    { id: 12, name: '概率论与数理统计', categoryId: 1 },
    { id: 13, name: 'Python编程与数据分析', categoryId: 11 }
  ],
  '2-2': [
    { id: 14, name: '操作系统', categoryId: 7 },
    { id: 15, name: '计算机网络', categoryId: 8 },
    { id: 16, name: '数据库原理', categoryId: 9 },
    { id: 17, name: '离散数学', categoryId: 2 }
  ],
  '3-1': [
    { id: 18, name: '软件工程', categoryId: 10 },
    { id: 19, name: '编译原理', categoryId: 5 },
    { id: 20, name: '人工智能导论', categoryId: 11 }
  ],
  '3-2': [
    { id: 21, name: 'Web开发技术', categoryId: 12 },
    { id: 22, name: '机器学习', categoryId: 11 },
    { id: 23, name: '信息安全', categoryId: 8 }
  ],
  '4-1': [
    { id: 24, name: '毕业设计', categoryId: 10 },
    { id: 25, name: '软件项目管理', categoryId: 10 }
  ],
  '4-2': [
    { id: 26, name: '毕业实习', categoryId: null },
    { id: 27, name: '毕业论文', categoryId: null }
  ]
}

export function getCoursesByGradeSemester(gradeId, semesterId) {
  const key = `${gradeId}-${semesterId}`
  return coursesByGrade[key] || []
}

export function getAllCourses() {
  const allCourses = []
  Object.values(coursesByGrade).forEach(courses => {
    allCourses.push(...courses)
  })
  return allCourses
}
