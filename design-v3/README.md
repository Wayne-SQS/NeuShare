# NeuShare Web 界面改版 · 设计交付 v3.0

2026-11-15。把鸿蒙端已经确立的品牌语言移植到 Web 端：**亮色「靛蓝毛玻璃」/ 深色「极简黑白 · 零彩色」**。
本目录是设计资产存档，双击 `index.html` 可离线预览全部画板（不依赖网络）。

## 画板

| 文件 | 内容 |
|---|---|
| `00-设计系统.png` | 色板、字阶、圆角、按钮与胶囊、亮暗对照 |
| `01-首页.png` | 玻璃导航、非对称 Hero、学期胶囊、热门资料、共建 CTA |
| `02-资源广场.png` | 筛选工具栏、分类侧栏、3×2 卡片网格、分页 |
| `03-资料详情.png` | 内容卡、文件信息条、上传者侧栏、评论区 |
| `04-管理后台-深色.png` | 零彩色 KPI、柱状图与环形图、待审核列表 |

均为 1440 桌面稿的 2x 导出。可编辑矢量稿在 Ardot：`https://ardot.tencent.com/file/747589935320212`（fileId `747589935320212`）。

## 文件与代码落点

| 文件 | 用途 |
|---|---|
| `theme-v3.css` | Web 主题层。**仓库里实际生效的是 `neushare-frontend/src/styles/theme-v3.css`**，两份内容保持同步；在 `src/main.js` 里排在 `global.css` 之后 import，删掉那行即可回退 |
| `tokens.css` | Ardot 变量集原始导出（`--NeuShare-Tokens-*`，Light / Dark 双模式） |
| `tokens.json` | W3C DTCG 格式，带 modes，供后续 token 管线使用 |
| `index.html` | 离线预览页 |

主题切换的实现在 `neushare-frontend/src/utils/theme.js`：给 `<html>` 写 `data-theme="light" | "dark"`，偏好存 `localStorage` 的 `ns-theme`，并派发 `ns-theme-change` 事件让 ECharts 重绘（canvas 读不到 CSS 变量）。

## 设计纪律

- 主色 `#4A6BFF` 只用于主按钮、链接、激活态与图表主线；辅色（青 `#00C2CB` / 粉 `#FF8FB1` / 黄 `#FFD93D` / 绿 `#6BCB77`）只用于分类胶囊与小面积标记
- 毛玻璃只给导航和浮动卡，主内容卡不模糊
- 深色模式严禁彩色，层级只靠白色强度、字重、边框、图标与小圆点区分
- 字体 Noto Sans SC（中文）+ Geist Mono（数字）

## 已知边界

- 只有 1440 桌面画板，没有平板 / 移动稿，也没有 hover / focus / disabled / error / 空态 / 加载态规范
- `tokens.json` 目前只有 8 个 token，而主题层有 50+ 变量；canvas 色板 `canvas #F4F7FF/#F5F7FF`、`surface #FFFFF8/#FFFFFF`、深色分隔线 `#2A2A2F/#29292E` 在画板 / CSS / token 文件之间仍有细微差异，尚未收敛为单一真源
- 画板里的资料数、浏览数、评论数均为排版示例，不是业务数据；前端页面一律显示接口返回的真实值
