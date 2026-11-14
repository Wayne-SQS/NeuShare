<template>
  <div class="guide-page container container--narrow">
    <div class="guide-hero">
      <div class="guide-hero__badge">考研指南</div>
      <h1 class="guide-hero__title">东北大学考研全流程指南</h1>
      <p class="guide-hero__sub">从常识科普到复习规划，帮你少走弯路。配合 NeuShare 社区与资料库使用效果更佳。</p>
    </div>

    <div class="toc panel">
      <h3 class="panel-title">目录</h3>
      <ol class="toc-list">
        <li><a href="#overview">考研常识</a></li>
        <li><a href="#subjects">考试科目与分值</a></li>
        <li><a href="#timeline">全年时间线</a></li>
        <li><a href="#plan">复习规划建议</a></li>
        <li><a href="#neu">东北大学报考贴士</a></li>
        <li><a href="#resources">NeuShare 相关资料</a></li>
      </ol>
    </div>

    <section id="overview" class="panel guide-section">
      <h2 class="section-title">一、考研常识</h2>
      <p>全国硕士研究生统一招生考试（简称“考研”）是应届本科毕业生、往届生及同等学力考生攻读硕士学位的主要途径。初试一般在每年 12 月倒数第二个周末举行，复试由各招生单位在次年 3–4 月自行组织。</p>
      <ul class="bullet-list">
        <li><strong>学硕</strong>：偏重学术研究，初试一般考英语一、数学一（理工）。</li>
        <li><strong>专硕</strong>：偏重应用实践，考试科目因专业而异（如计算机专硕常考英语二、数学二或自命题）。</li>
        <li><strong>国家线</strong>：教育部划定的最低复试资格线，分为 A 区/B 区，东北大学属于 A 区自划线院校。</li>
      </ul>
    </section>

    <section id="subjects" class="panel guide-section">
      <h2 class="section-title">二、考试科目与分值</h2>
      <p>以计算机相关专业为例，典型科目构成（满分 500 分）：</p>
      <table class="guide-table">
        <thead><tr><th>科目</th><th>分值</th><th>说明</th></tr></thead>
        <tbody>
          <tr><td>政治</td><td>100</td><td>全国统考，含马原、毛中特、史纲、思修、时政</td></tr>
          <tr><td>英语（一/二）</td><td>100</td><td>学硕多考英语一，专硕多考英语二</td></tr>
          <tr><td>数学（一/二）</td><td>150</td><td>理工类核心，含高数、线代、概率论（数二不考概率论）</td></tr>
          <tr><td>专业课</td><td>150</td><td>统考 408 或院校自命题，东北大学计算机为自命题</td></tr>
        </tbody>
      </table>
    </section>

    <section id="timeline" class="panel guide-section">
      <h2 class="section-title">三、全年时间线</h2>
      <div class="timeline">
        <div class="t-item"><span class="t-dot"></span><div><strong>3–6 月 基础阶段</strong><p>确定目标院校与专业，过完数学/英语基础，开始专业课一轮。</p></div></div>
        <div class="t-item"><span class="t-dot"></span><div><strong>7–9 月 强化阶段</strong><p>暑假黄金期，强化数学与专业课，英语开始真题，政治启动。</p></div></div>
        <div class="t-item"><span class="t-dot"></span><div><strong>10 月 报名</strong><p>10 月初网上报名（研招网），11 月现场/网上确认。</p></div></div>
        <div class="t-item"><span class="t-dot"></span><div><strong>11–12 月 冲刺</strong><p>全科真题模拟，查漏补缺，政治背诵押题。</p></div></div>
        <div class="t-item"><span class="t-dot"></span><div><strong>12 月底 初试</strong><p>初试两天，上午政治/业务课一，下午英语/业务课二。</p></div></div>
        <div class="t-item"><span class="t-dot"></span><div><strong>次年 3–4 月 复试</strong><p>出分 → 国家线/校线 → 复试（笔试+面试）→ 调剂。</p></div></div>
      </div>
    </section>

    <section id="plan" class="panel guide-section">
      <h2 class="section-title">四、复习规划建议</h2>
      <ol class="num-list">
        <li><strong>数学</strong>：跟一位主流老师（如张宇/武忠祥）过完基础+强化，660/880/真题必刷，错题本反复回顾。</li>
        <li><strong>英语</strong>：单词全程不断，真题阅读精读至少两遍，作文整理自己的模板。</li>
        <li><strong>政治</strong>：不必过早，9 月启动即可，跟肖秀荣/腿姐，后期肖四肖八是关键。</li>
        <li><strong>专业课</strong>：先过参考书 + 目标院校历年真题，反复刷真题，整理知识框架。</li>
      </ol>
      <div class="tip-box">
        <el-icon><InfoFilled /></el-icon>
        <span>建议每周留半天复盘，每月一次全真模拟，避免“只学不练”。</span>
      </div>
    </section>

    <section id="neu" class="panel guide-section">
      <h2 class="section-title">五、东北大学报考贴士</h2>
      <ul class="bullet-list">
        <li>东北大学是 985/211/双一流高校，位于辽宁沈阳，计算机、控制、材料、冶金等为优势学科。</li>
        <li>属于 34 所<strong>自划线</strong>院校之一，校线通常高于国家线，需重点关注学院官网的复试细则。</li>
        <li>计算机相关专业初试专业课为自命题，务必以研究生院公布的考试大纲和参考书目为准，历年真题是核心资料。</li>
        <li>复试占比较高，需提前准备项目/竞赛经历、英语口语与专业基础问答。</li>
      </ul>
    </section>

    <section id="resources" class="panel guide-section">
      <h2 class="section-title">六、NeuShare 相关资料</h2>
      <p>在 NeuShare 搜索以下关键词，获取学长征召的笔记与真题资源；也可到社区发帖交流：</p>
      <div class="res-tags">
        <router-link to="/resource?keyword=408" class="res-tag">408 真题</router-link>
        <router-link to="/resource?keyword=考研数学" class="res-tag">考研数学</router-link>
        <router-link to="/resource?keyword=考研英语" class="res-tag">考研英语</router-link>
        <router-link to="/resource?keyword=政治" class="res-tag">考研政治</router-link>
        <router-link to="/community" class="res-tag res-tag--cta">去社区交流 →</router-link>
      </div>
    </section>
  </div>
</template>

<script setup>
</script>

<style scoped>
.guide-page {
  padding-top: var(--section-gap-md);
  padding-bottom: var(--section-gap-md);
}

.guide-hero {
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  color: #fff;
  border-radius: var(--radius-lg);
  padding: var(--space-8);
  margin-bottom: var(--space-6);
  box-shadow: var(--shadow-accent);
}

.guide-hero__badge {
  display: inline-block;
  background: rgba(255, 255, 255, 0.2);
  padding: 2px 12px;
  border-radius: var(--radius-full);
  font-size: var(--text-xs);
  margin-bottom: var(--space-3);
}

.guide-hero__title {
  font-size: var(--heading-1);
  font-weight: var(--font-bold);
  color: #fff;
  margin-bottom: var(--space-2);
}

.guide-hero__sub {
  font-size: var(--text-sm);
  opacity: 0.92;
  line-height: var(--leading-relaxed);
  max-width: 560px;
}

.toc {
  margin-bottom: var(--space-6);
}

.toc-list {
  padding-left: var(--space-5);
  line-height: 2;
  font-size: var(--text-sm);
}

.toc-list a {
  color: var(--accent);
}

.guide-section {
  margin-bottom: var(--space-5);
}

.section-title {
  font-size: var(--heading-2);
  font-weight: var(--font-bold);
  color: var(--text-primary);
  margin-bottom: var(--space-4);
  scroll-margin-top: 80px;
}

.guide-section p {
  font-size: var(--text-base);
  color: var(--text-secondary);
  line-height: var(--leading-relaxed);
  margin-bottom: var(--space-3);
}

.bullet-list,
.num-list {
  padding-left: var(--space-5);
  line-height: var(--leading-relaxed);
  color: var(--text-secondary);
  font-size: var(--text-base);
}

.bullet-list li,
.num-list li {
  margin-bottom: var(--space-2);
}

.guide-table {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--text-sm);
  margin-top: var(--space-3);
}

.guide-table th,
.guide-table td {
  border: 1px solid var(--border-default);
  padding: var(--space-2) var(--space-3);
  text-align: left;
}

.guide-table th {
  background: var(--bg-deep);
  color: var(--text-primary);
  font-weight: var(--font-semibold);
}

.timeline {
  position: relative;
  padding-left: var(--space-4);
}

.t-item {
  display: flex;
  gap: var(--space-3);
  margin-bottom: var(--space-4);
}

.t-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--accent);
  margin-top: 6px;
  flex-shrink: 0;
  box-shadow: 0 0 0 4px var(--info-bg);
}

.t-item strong {
  color: var(--text-primary);
  display: block;
  margin-bottom: 2px;
}

.t-item p {
  margin: 0;
  font-size: var(--text-sm);
}

.tip-box {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  background: var(--warning-bg);
  border: 1px solid rgba(245, 158, 11, 0.25);
  color: #92400e;
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  margin-top: var(--space-3);
}

.res-tags {
  display: flex;
  gap: var(--space-2);
  flex-wrap: wrap;
  margin-top: var(--space-3);
}

.res-tag {
  padding: var(--space-2) var(--space-4);
  background: var(--bg-deep);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  text-decoration: none;
  transition: var(--transition-fast);
}

.res-tag:hover {
  border-color: var(--accent);
  color: var(--accent);
}

.res-tag--cta {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
  font-weight: var(--font-medium);
}

.res-tag--cta:hover {
  color: #fff;
  opacity: 0.92;
}
</style>
