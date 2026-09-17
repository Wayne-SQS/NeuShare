-- ============================================================
-- V6：存量资源 course_name 回填
--
-- 背景：V5 给 resource 表加了 course_name / teacher / school_year / term
--       四个结构化字段，但历史数据这些字段全是 NULL —— 结构化筛选
--       在设计上可用，实际却筛不出东西。迁移脚本只改表结构是不够的，
--       必须同时把老数据补上，否则这次优化对用户等于没发生。
--
-- 策略：用课程名词典按 title 关键词匹配回填。做不到 100% 准确，
--       所以脚本只补「置信度高」的部分，剩下的留人工。
--
-- 安全性：
--   1. 只更新 course_name 为空的行，已填过的不覆盖
--   2. 匹配不上时 ELSE 回写原值，不会产生脏数据
--   3. 可重复执行（幂等）
-- ============================================================

USE neushare;

-- 回填前先看一眼规模
SELECT COUNT(*) AS total,
       SUM(CASE WHEN course_name IS NULL OR course_name = '' THEN 1 ELSE 0 END) AS missing
FROM resource;

-- ---------------- 主回填 ----------------
UPDATE resource
SET course_name = (
    CASE
        -- 顺序有意义：更具体的写法放前面，避免被短词先命中
        WHEN title LIKE '%数据结构%' OR title LIKE '%数据结构与算法%' THEN '数据结构与算法'
        WHEN title LIKE '%面向对象%' OR title LIKE '%面向对象程序设计%' OR title LIKE '%JAVA%' OR title LIKE '%Java%' THEN '面向对象程序设计（JAVA）'
        WHEN title LIKE '%高等数学%' OR title LIKE '%高数%' THEN '高等数学'
        WHEN title LIKE '%线性代数%' OR title LIKE '%线代%' THEN '线性代数'
        WHEN title LIKE '%概率论%' OR title LIKE '%数理统计%' THEN '概率论与数理统计'
        WHEN title LIKE '%离散数学%' THEN '离散数学'
        WHEN title LIKE '%计算机组成原理%' OR title LIKE '%计组%' OR title LIKE '%组成原理%' THEN '计算机组成原理'
        WHEN title LIKE '%操作系统%' THEN '操作系统'
        WHEN title LIKE '%计算机网络%' OR title LIKE '%计网%' THEN '计算机网络'
        WHEN title LIKE '%编译原理%' THEN '编译原理'
        WHEN title LIKE '%数据库原理%' OR title LIKE '%数据库系统%' THEN '数据库原理'
        WHEN title LIKE '%软件工程%' OR title LIKE '%软工%' THEN '软件工程'
        WHEN title LIKE '%软件项目管理%' OR title LIKE '%项目管理%' THEN '软件项目管理'
        WHEN title LIKE '%算法设计%' OR title LIKE '%算法分析%' THEN '数据结构与算法'
        WHEN title LIKE '%程序设计基础%' OR title LIKE '%C语言%' OR title LIKE '%C 语言%' THEN '程序设计基础'
        WHEN title LIKE '%Python%' OR title LIKE '%python%' OR title LIKE '%数据分析%' THEN 'Python编程与数据分析'
        WHEN title LIKE '%Web开发%' OR title LIKE '%Web 开发%' OR title LIKE '%前端%' THEN 'Web开发技术'
        WHEN title LIKE '%机器学习%' THEN '机器学习'
        WHEN title LIKE '%人工智能%' OR title LIKE '%AI导论%' THEN '人工智能导论'
        WHEN title LIKE '%信息安全%' OR title LIKE '%网络安全%' THEN '信息安全'
        WHEN title LIKE '%大学英语%' OR title LIKE '%英语四级%' OR title LIKE '%四级%' OR title LIKE '%六级%' THEN '大学英语'
        WHEN title LIKE '%大学物理%' THEN '大学物理'
        WHEN title LIKE '%毕业设计%' THEN '毕业设计'
        WHEN title LIKE '%毕业实习%' THEN '毕业实习'
        WHEN title LIKE '%毕业论文%' THEN '毕业论文'
        ELSE course_name
    END
),
update_time = update_time
WHERE course_name IS NULL OR course_name = '';

-- ---------------- 人工补录模板 ----------------
-- 上面匹配不到的，按 id 手工补。执行前先跑下面这条看看漏网之鱼：
--
-- SELECT id, title FROM resource
-- WHERE course_name IS NULL OR course_name = ''
-- ORDER BY id;
--
-- UPDATE resource SET course_name = '课程名', teacher = '教师名',
--        school_year = '2024-2025', term = 'autumn', update_time = update_time
-- WHERE id IN (1, 2, 3);

-- 分类兜底（可选）：如果 category 表的名称本身就是课程名，可以用它补最后一轮。
-- 先把 category 表打出来确认口径一致再放开注释，别盲跑。
--
-- SELECT id, name FROM category ORDER BY id;
--
-- UPDATE resource r
-- JOIN category c ON r.category_id = c.id
-- SET r.course_name = c.name, r.update_time = r.update_time
-- WHERE (r.course_name IS NULL OR r.course_name = '')
--   AND c.name NOT IN ('其他', '通用');

-- ---------------- 验收 ----------------
-- 回填后还剩多少没填
SELECT COUNT(*) AS still_missing
FROM resource
WHERE course_name IS NULL OR course_name = '';

-- 各课程资料分布，顺带检查有没有回填错的
SELECT course_name, COUNT(*) AS cnt
FROM resource
WHERE course_name IS NOT NULL AND course_name != ''
GROUP BY course_name
ORDER BY cnt DESC;
