# HarmonyOS "一次开发，多端部署" UI 设计教程

> 内容来源：华为开发者官方文档 https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ability-kit
> 整理时间：2026-06-13

---

## 一、概述

"一次开发，多端部署"（简称"一多"）是 HarmonyOS 面向多终端提供的核心能力，让开发者可以基于一套设计，高效构建多端可运行的应用。其本质不是追求"完全相同的界面"，而是**在尊重设备特性的基础上，最大化逻辑与资产的复用**。

### 核心目标

- 一套代码，适配手机、折叠屏、平板、PC、智慧屏、智能穿戴等多种设备
- 官方实测平均代码复用率达 **85% 以上**
- 避免后期加入新设备类型时对应用架构进行大幅调整

### 四层技术架构

| 层次 | 技术 | 作用 |
|------|------|------|
| 声明式UI + 组件自适应 | ArkTS + ArkUI | 统一组件，系统自动映射到最佳原生控件 |
| 媒体查询与断点系统 | BreakpointSystem | 根据屏幕宽度自动切换布局 |
| 设备能力抽象层 | Device Capability Abstraction | 将硬件差异封装为统一API |
| 分布式运行时协同 | Distributed Runtime | 跨设备迁移时UI自动适配目标设备 |

---

## 二、断点系统（Breakpoint System）

### 2.1 断点的设计原理

- **原则一**：两个宽度相近的窗口，页面布局相同，断点归一
- **原则二**：高度相对宽度较小的窗口（横向/类方形），页面布局进行差异化设计，增加断点

### 2.2 横向断点定义

以应用窗口宽度为判断条件：

| 断点名称 | 窗口宽度（vp） | 典型设备 |
|----------|---------------|---------|
| **xs** | (0, 320) | 智能穿戴 |
| **sm** | [320, 600) | 手机竖屏 |
| **md** | [600, 840) | 双折叠内屏、手机横屏 |
| **lg** | [840, 1440) | 平板横屏、智慧屏 |
| **xl** | [1440, +∞) | PC、MateBook |

### 2.3 纵向断点定义

以应用窗口高宽比为判断条件：

| 断点名称 | 高宽比 | 窗口类型 |
|----------|--------|---------|
| **sm** | (0, 0.8) | 横向窗口 |
| **md** | [0.8, 1.2) | 类方形窗口 |
| **lg** | [1.2, +∞) | 纵向窗口 |

### 2.4 主流设备断点映射

| 产品类型 | 常见型号 | 横向断点 | 纵向断点 |
|---------|---------|---------|---------|
| 手机竖屏 | Mate60/70, Pura70 | sm | lg |
| 双折叠内屏竖屏 | Mate X5/X6 | md | md |
| 三折叠G态横屏 | Mate XT | lg | sm |
| 平板横屏 | MatePad Pro | lg | sm |
| PC | MateBook Pro | xl | sm |
| 智慧屏 | Mate TV | lg | sm |

### 2.5 断点工具类实现

```typescript
// 官方推荐的工具类模式
export class WidthBreakpointType<T> {
  sm: T;
  md: T;
  lg: T;
  xl: T;

  constructor(sm: T, md: T, lg: T, xl: T) {
    this.sm = sm;
    this.md = md;
    this.lg = lg;
    this.xl = xl;
  }

  getValue(widthBp: WidthBreakpoint): T {
    if (widthBp === WidthBreakpoint.WIDTH_XS || widthBp === WidthBreakpoint.WIDTH_SM) {
      return this.sm;
    }
    if (widthBp === WidthBreakpoint.WIDTH_MD) {
      return this.md;
    }
    if (widthBp === WidthBreakpoint.WIDTH_LG) {
      return this.lg;
    }
    return this.xl;
  }
}
```

**使用示例**：

```typescript
// 不同断点下的字体大小
Text('Test')
  .fontSize(new WidthBreakpointType('14fp', '16fp', '18fp', '20fp')
    .getValue(this.currentWidthBreakpoint))

// 不同断点下的Grid列数
Grid() {
  // ...
}
.columnsTemplate(`repeat(${new WidthBreakpointType(2, 3, 4, 4)
  .getValue(this.mainWindowInfo.widthBp)}, 1fr)`)
```

### 2.6 通过断点刷新UI

**方式一：@Env 环境变量（API version 22+）**

```typescript
@Component
struct MyComponent {
  @Env('breakpoint') currentBreakpoint: string = 'sm';

  build() {
    if (this.currentBreakpoint === 'lg') {
      // 大屏布局
    } else {
      // 小屏布局
    }
  }
}
```

**方式二：主动监听窗口尺寸变化**

```typescript
// 1. 定义窗口信息类
@Observed
export class WindowInfo {
  public widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_XS;
  public heightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;
}

// 2. 在 EntryAbility 中初始化
onWindowStageCreate(windowStage: window.WindowStage): void {
  this.windowUtil = new WindowUtil(windowStage.getMainWindowSync());
  AppStorage.setOrCreate('windowUtil', this.windowUtil);

  windowStage.loadContent('pages/Index', (err) => {
    this.windowUtil!.setUIContext();
    this.windowUtil!.updateWindowInfo();
  });
}

// 3. 在组件中使用
@Component
export struct MyView {
  @StorageLink('windowUtil') windowUtil: WindowUtil | undefined = undefined;

  build() {
    // 根据 windowUtil.mainWindowInfo.widthBp 判断断点
  }
}
```

---

## 三、响应式布局

### 3.1 四种响应式布局能力

| 能力 | 简介 |
|------|------|
| **断点** | 将窗口宽度划分为不同范围，监听窗口尺寸变化，当断点改变时同步调整页面布局 |
| **媒体查询** | 支持监听窗口宽度、横竖屏、深浅色、设备类型等多种媒体特征 |
| **栅格** | 将区域划分为有规律的多列，通过调整不同断点下的栅格参数实现不同布局 |
| **响应式组件** | Tabs、Swiper、Grid、List、GridRow 等组件支持响应式属性 |

### 3.2 响应式布局样式

#### 分栏布局

小屏单栏，大屏双栏/三栏：

```typescript
if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
  // 大屏：双栏布局
  Row() {
    ListPanel().width('30%')
    DetailPanel().width('70%')
  }
} else {
  // 小屏：单栏流式
  Column() {
    ListPanel()
    DetailPanel()
  }
}
```

**SideBarContainer + Navigation 实现三分栏**：

```typescript
SideBarContainer(SideBarContainerType.Embed) {
  // 内容区
  Navigation() {
    // 二级内容
  }
}
.sideBarWidth(240)
.showSideBar(this.currentBreakpoint !== 'sm')
```

#### 重复布局

List/Grid/WaterFlow 组件根据断点调整列数：

```typescript
List() {
  ForEach(this.items, (item) => {
    ListItem() { /* ... */ }
  })
}
.lanes(new BreakpointType(1, 2, 3, 4).getValue(this.currentBreakpoint))
```

#### 挪移布局

Tabs 组件：小屏底部导航，大屏侧边导航：

```typescript
Tabs({ barPosition: this.isWide ? BarPosition.Start : BarPosition.End }) {
  TabContent() { HomeTab() }.tabBar('首页')
  TabContent() { CategoryTab() }.tabBar('分类')
  TabContent() { SearchTab() }.tabBar('搜索')
  TabContent() { ProfileTab() }.tabBar('我的')
}
.vertical(this.isWide)  // 大屏时侧边栏
```

#### 缩进布局

大屏时内容区限制最大宽度，居中显示：

```typescript
Column() {
  Scroll() {
    Column() {
      // 页面内容
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .constraintSize({ maxWidth: this.contentMaxWidth() })
  }
}
.alignItems(HorizontalAlign.Center)
.backgroundColor('#F1F3F5')  // 浅灰背景区分层次
```

---

## 四、响应式组件详解

### 4.1 组件与布局场景对应关系

| 响应式组件 | 布局场景 | 响应式布局方式 |
|-----------|---------|--------------|
| List | 重复列表 | 重复布局 |
| WaterFlow | 重复瀑布流 | 重复布局 |
| Swiper | 重复轮播视图 | 重复布局 |
| Grid | 重复网格 | 重复布局 |
| SideBarContainer | 侧边栏 | 分栏布局 |
| Navigation | 单/双栏 | 分栏布局 |
| Navigation+SideBarContainer | 三分栏 | 分栏布局 |
| Tabs | 底部/侧边导航 | 挪移布局 |
| GridRow/GridCol | 插图和文字组合 | 缩进布局 |

### 4.2 Swiper 响应式属性

```typescript
Swiper() {
  ForEach(this.banners, (item) => {
    // 轮播内容
  })
}
.displayCount(new BreakpointType(1, 2, 2, 2).getValue(this.currentBreakpoint))
.nextMargin(new BreakpointType(0, 12, 200, 260).getValue(this.currentBreakpoint))
.indicator(this.currentBreakpoint === 'sm')  // 仅小屏显示指示器
.autoPlay(true)
```

### 4.3 Grid 响应式属性

```typescript
Grid() {
  ForEach(this.items, (item) => {
    GridItem() { /* ... */ }
  })
}
.columnsTemplate(new BreakpointType('1fr', '1fr 1fr', '1fr 1fr 1fr', '1fr 1fr 1fr 1fr')
  .getValue(this.currentBreakpoint))
.rowsGap(8)
.columnsGap(8)
```

### 4.4 Tabs 响应式属性

```typescript
Tabs({
  barPosition: isWide ? BarPosition.Start : BarPosition.End,
  controller: this.tabsController
}) {
  // TabContent...
}
.vertical(isWide)  // 大屏侧边栏模式
.scrollable(false)
```

### 4.5 Navigation 响应式

```typescript
Navigation(this.pageInfos) {
  // 内容
}
.mode(this.currentBreakpoint === 'sm' ? NavigationMode.Stack : NavigationMode.Split)
.navDestination(this.buildDestination)
```

---

## 五、栅格布局（GridRow/GridCol）

### 5.1 栅格断点

| 断点 | 宽度范围 | 默认列数 | 默认gutter | 默认margin |
|------|---------|---------|-----------|-----------|
| xs | (0, 320) | 2 | 12vp | 12vp |
| sm | [320, 600) | 4 | 12vp | 24vp |
| md | [600, 840) | 8 | 16vp | 32vp |
| lg | [840, 1440) | 12 | 20vp | 48vp |
| xl | [1440, +∞) | 12 | 20vp | 48vp |

### 5.2 使用示例

```typescript
GridRow({ columns: { sm: 4, md: 8, lg: 12 }, gutter: 16 }) {
  GridCol({ span: { sm: 4, md: 4, lg: 6 } }) {
    // 左侧内容
  }
  GridCol({ span: { sm: 4, md: 4, lg: 6 } }) {
    // 右侧内容
  }
}
```

---

## 六、多设备体验设计原则

### 6.1 UX设计四原则

| 原则 | 含义 |
|------|------|
| **差异性** | 尊重不同设备的使用习惯和交互方式 |
| **一致性** | 保持跨设备的核心体验和品牌一致 |
| **灵活性** | 布局能自适应不同屏幕尺寸 |
| **兼容性** | 确保在所有目标设备上可用 |

### 6.2 基础要求

1. **不简单拉伸**：大屏不应只是小屏的放大版，应利用额外空间展示更多内容
2. **内容优先级**：小屏显示核心内容，大屏展示完整信息
3. **交互适配**：触摸屏支持点击，遥控器支持方向键聚焦，手表支持旋转表冠

### 6.3 增值体验

- 大屏设备可展示更多辅助信息（如侧边推荐栏）
- 支持键盘快捷键操作
- 利用多窗口能力提升效率

---

## 七、NeUshare 项目实践对照

### 7.1 已实现的"一多"能力

| 能力 | 实现方式 | 对应文件 |
|------|---------|---------|
| 5断点系统 | BreakpointSystem + BreakpointType\<T\> | common/utils/BreakpointSystem.ets |
| 响应式背景色 | BG_PAGE = '#F1F3F5' | common/theme/ColorTokens.ets |
| 内容最大宽度 | constraintSize({ maxWidth }) | 各页面组件 |
| Swiper响应式 | displayCount + nextMargin | BannerSwiper.ets |
| Grid响应式列数 | columnsTemplate 按断点变化 | SearchPage, CategoryPage 等 |
| Tabs挪移布局 | vertical(isWide) 侧边/底部切换 | Index.ets |
| 缩进布局 | alignItems(Center) + maxWidth | HomeTab, ProfileTab 等 |
| DetailPage分栏 | 大屏主内容+侧边推荐 | DetailPage.ets |

### 7.2 可进一步优化的方向

| 方向 | 当前状态 | 建议改进 |
|------|---------|---------|
| 纵向断点 | 未使用 | 可加入纵向断点判断，适配方形屏/分屏 |
| Navigation分栏 | 未使用 NavigationMode.Split | 可用于大屏列表+详情双栏 |
| GridRow/GridCol | 未使用 | 可替代手动 maxWidth 约束 |
| 媒体查询深浅色 | 未适配 | 可增加暗色模式支持 |
| 设备能力抽象 | 部分硬编码 | 可使用 Resource 目录按设备类型提供差异化资源 |
| @Env断点变量 | 未使用（API 22+） | 可简化断点获取逻辑 |

---

## 八、关键代码模式速查

### 8.1 内容区最大宽度 + 居中（缩进布局）

```typescript
build() {
  Column() {
    // Header
    Row() { /* ... */ }
      .constraintSize({ maxWidth: this.contentMaxWidth() + 32 })

    Scroll() {
      Column() {
        // 页面内容
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .constraintSize({ maxWidth: this.contentMaxWidth() + 32 })
    }
    .layoutWeight(1)
  }
  .alignItems(HorizontalAlign.Center)
  .width('100%').height('100%')
  .backgroundColor(ColorTokens.BG_PAGE)
}

private contentMaxWidth(): number {
  return new BreakpointType<number>(
    { sm: 9999, md: 640, lg: 780, xl: 920 }
  ).getValue(this.currentBreakpoint) ?? 9999;
}
```

### 8.2 大屏双栏布局（分栏布局）

```typescript
if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
  Row() {
    Scroll() {
      Column() { /* 主内容 */ }
        .constraintSize({ maxWidth: 700 })
    }.layoutWeight(2)

    Scroll() {
      Column() { /* 侧边栏 */ }
    }
    .constraintSize({ maxWidth: 300 })
    .backgroundColor(ColorTokens.BG_PAGE)
  }
} else {
  // 小屏单栏
  Scroll() {
    Column() { /* 全部内容 */ }
  }
}
```

### 8.3 响应式属性赋值

```typescript
// 字体大小
.fontSize(new BreakpointType<number>(
  { sm: 14, md: 16, lg: 18, xl: 20 }
).getValue(this.currentBreakpoint) ?? 14)

// Grid列数
.columnsTemplate(new BreakpointType<string>(
  { sm: '1fr', md: '1fr 1fr', lg: '1fr 1fr 1fr', xl: '1fr 1fr 1fr 1fr' }
).getValue(this.currentBreakpoint) ?? '1fr')

// 条件渲染
if (this.currentBreakpoint === 'sm') {
  // 仅小屏显示的元素
}
```

---

## 九、窗口沉浸式（Immersive）

### 9.1 概述

沉浸式模式是指通过减少无关元素的干扰，使应用界面更加专注于内容呈现，以提升用户体验的设计模式。典型应用的全屏窗口，其UI元素包括**状态栏**、**应用界面**和**底部导航条**。

- **避让区**：状态栏和导航条在沉浸式布局下称为避让区
- **安全区**：避让区之外的区域称为安全区

沉浸式页面开发通常通过将应用页面延伸至状态栏和导航条，达到以下目的：

1. **视觉统一**：应用页面与避让区（状态栏、导航条）色调统一，避免界面割裂
2. **布局扩展**：充分利用屏幕可视区域，获得更大的布局空间
3. **沉浸体验**：在游戏、视频等场景中隐藏系统元素，提供无干扰的全屏体验

### 9.2 实现原理

沉浸式实现主要考虑两个因素：

1. **实现沉浸式效果**：使页面突破安全区或标题栏限制，延伸至目标区域
2. **避让处理**：避免页面内容与避让区的系统信息发生遮挡和冲突

### 9.3 三种实现方案

#### 方案一：组件设置背景沉浸（组件级，推荐）

组件与避让区边界重合时，设置组件的 `background()` 属性，将组件背景扩展至避让区，**页面布局仍在安全区内**。

```typescript
Column() {
  Text('内容区域')
}
.background(ColorTokens.PRIMARY)  // 背景色扩展至避让区
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])  // 扩展至状态栏
```

**优点**：不同组件可设置不同背景色并扩展至对应避让区，灵活度高。

#### 方案二：expandSafeArea 属性（组件级，推荐）

不改变布局情况下，将组件绘制内容（如背景色、背景图）扩展至安全区外。

```typescript
// 顶部背景延伸到状态栏
Column() {
  // 页面内容
}
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

// 底部背景延伸到导航条
Column() {
  // 页面内容
}
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

// 同时延伸顶部和底部
Column() {
  // 页面内容
}
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
```

**适用场景**：
- 背景图和视频场景：背景延伸到避让区，内容仍在安全区
- 滚动类场景：Scroll 容器背景延伸
- 底部页签场景：Tabs 组件延伸
- 图文场景：顶部图片延伸到状态栏

#### 方案三：窗口全屏布局（窗口级，全局）

通过 `setWindowLayoutFullScreen()` 设置窗口全屏布局，界面元素延伸到状态栏和导航条区域。

```typescript
// EntryAbility.ets
onWindowStageCreate(windowStage: window.WindowStage): void {
  windowStage.getMainWindow().then(win => {
    win.setWindowLayoutFullScreen(true);
  });

  windowStage.loadContent('pages/Index', (err) => {
    // 获取避让区高度，用于手动 padding
    const mainWindow = windowStage.getMainWindowSync();
    const avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const topRect = avoidArea.topRect;
    const bottomRect = avoidArea.bottomRect;
    AppStorage.setOrCreate('topAvoidHeight', topRect.height);
    AppStorage.setOrCreate('bottomAvoidHeight', bottomRect.height);
  });
}
```

**注意**：窗口全屏布局会影响所有页面，需要手动处理每个页面的避让。

### 9.4 常见沉浸式场景

#### 顶部背景延伸（最常用）

```typescript
build() {
  Column() {
    // 顶部标题栏，背景延伸到状态栏
    Row() {
      Text('我的').fontSize(20).fontWeight(FontWeight.Bold)
    }
    .width('100%').height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor(ColorTokens.PRIMARY)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

    // 内容区域
    Scroll() {
      Column() { /* ... */ }
    }
  }
}
```

#### 挖孔避让

```typescript
// 检测挖孔区域
const cutoutInfo = display.getCutoutInfo();
// 使用 padding 避让挖孔
Row() {
  Text('标题')
}
.padding({ top: cutoutTopHeight })
```

#### 自由窗口标题栏沉浸（PC端）

```typescript
// PC端自由窗口模式下的标题栏沉浸
Column() {
  Row() {
    Text('←').onClick(() => router.back())
    Blank()
    Text('分享')
  }
  .height(48)
  .padding({ left: 16, right: 16 })
  .backgroundColor(ColorTokens.BG_CARD)
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
}
```

### 9.5 避让处理要点

1. **可交互元素**不应放在避让区（导航条底部区域可以响应点击，但其他UI元素不建议）
2. **关键信息**不应被状态栏遮挡
3. 使用 `expandSafeArea` 仅扩展绘制内容，布局仍在安全区
4. 使用 `ignoreLayoutSafeArea` 可同时扩展布局和绘制

---

## 十、沉浸光感（Immersive Material）

### 10.1 概述

HarmonyOS 6.1 新增**沉浸光感**视觉效果，结合系统原生材质渲染逻辑，赋予界面立体通透的高级质感，大幅增强交互视觉氛围。

### 10.2 HdsNavigation 沉浸光感

```typescript
import { hdsMaterial, HdsNavigation, HdsNavigationTitleMode, ScrollEffectType }
  from '@kit.UIDesignKit';

@Entry
@Component
struct Index {
  @State materialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.ADAPTIVE;
  @State materialType: hdsMaterial.MaterialType = hdsMaterial.MaterialType.IMMERSIVE;

  build() {
    HdsNavigation() {
      Scroll() {
        Column() {
          // 页面内容
        }
      }
    }
    .titleBar({
      content: {
        title: { mainTitle: 'NeUshare' },
        menu: {
          value: [{
            content: {
              icon: $r('sys.symbol.search_things'),
              label: 'search',
              action: () => { /* 搜索 */ }
            }
          }]
        }
      },
      style: {
        scrollEffectOpts: {
          // 沉浸式渐变模糊效果（推荐图文场景）
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR,
        },
        // 沉浸光感材质配置
        systemMaterialEffect: {
          materialType: this.materialType,
          materialLevel: this.materialLevel
        }
      }
    })
    .titleMode(HdsNavigationTitleMode.MINI)
    .ignoreLayoutSafeArea(
      [LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM]
    )
  }
}
```

### 10.3 HdsTabs 悬浮页签

HarmonyOS 6.1 新增**悬浮式页签**，允许页签栏脱离底部固定布局，悬浮在内容区域上方，形成"内容在下、页签在上"的分层视觉效果。

```typescript
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { HdsTabs, HdsTabsController } from '@kit.UIDesignKit';

@Entry
@Component
struct Index {
  private controller: HdsTabsController = new HdsTabsController();

  build() {
    Column() {
      HdsTabs({ controller: this.controller }) {
        TabContent() { HomeTab() }
          .tabBar(new BottomTabBarStyle($r('sys.media.ohos_ic_public_clock'), '首页'))

        TabContent() { CategoryTab() }
          .tabBar(new BottomTabBarStyle($r('sys.media.ohos_ic_public_folder'), '分类'))

        TabContent() { SearchTab() }
          .tabBar(new BottomTabBarStyle($r('sys.media.ohos_ic_public_search'), '搜索'))

        TabContent() { ProfileTab() }
          .tabBar(new BottomTabBarStyle($r('sys.media.ohos_ic_public_contacts'), '我的'))
      }
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .vertical(false)
      .barFloatingStyle({
        barWidth: { smallWidth: 200, mediumWidth: 300, largeWidth: 400 },
        barBottomMargin: 28,
        gradientMask: { maskColor: '#66F1F3F5', maskHeight: 92 },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      })
    }
  }
}
```

### 10.4 材质类型说明

| 材质类型 | 说明 |
|---------|------|
| `MaterialType.NONE` | 无材质效果 |
| `MaterialType.SMOOTH` | 平滑材质（设备不支持IMMERSIVE时推荐） |
| `MaterialType.IMMERSIVE` | 沉浸光感材质（支持EXQUISITE/GENTLE子效果） |

| 材质级别 | 说明 |
|---------|------|
| `MaterialLevel.ADAPTIVE` | 自适应（推荐） |
| `MaterialLevel.EXQUISITE` | 精致效果（需设备支持IMMERSIVE） |
| `MaterialLevel.GENTLE` | 柔和效果（需设备支持IMMERSIVE） |

### 10.5 兼容性检查

```typescript
aboutToAppear(): void {
  try {
    let materialTypes: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
    if (materialTypes.includes(hdsMaterial.MaterialType.IMMERSIVE)) {
      // 设备支持沉浸光感，使用 EXQUISITE 或 GENTLE
      this.materialType = hdsMaterial.MaterialType.IMMERSIVE;
    } else {
      // 设备不支持，使用 SMOOTH 避免卡顿
      this.materialType = hdsMaterial.MaterialType.SMOOTH;
    }
  } catch (err) {
    this.materialType = hdsMaterial.MaterialType.NONE;
  }
}
```

---

## 十一、深色模式适配

### 11.1 概述

深色模式（Dark Mode）是与浅色模式相对应的一种UI主题，在光线较暗的环境下减少对眼睛的刺激，还能降低应用功耗。

### 11.2 资源限定词方式

通过在 `resources/` 目录下创建 `dark` 限定词目录，系统会自动根据当前模式选择对应资源：

```
resources/
├── base/              # 默认（浅色模式）
│   ├── element/
│   │   └── color.json    # { "color": { "bg_page": "#F1F3F5" } }
│   └── media/
└── dark/              # 深色模式
    ├── element/
    │   └── color.json    # { "color": { "bg_page": "#1A1A1A" } }
    └── media/
```

### 11.3 代码中适配

```typescript
// 使用 $r 引用资源，系统自动切换
.backgroundColor($r('app.color.bg_page'))

// 监听深浅色变化
@StorageProp('colorMode') colorMode: number = 0;

// 手动设置深色模式
this.getUIContext().getHostContext()?.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
```

---

## 十二、视觉美化最佳实践

### 12.1 背景色层次

| 层级 | 推荐色值 | 用途 |
|------|---------|------|
| 页面背景 | `#F1F3F5` | 最底层，浅灰区分 |
| 卡片背景 | `#FFFFFF` | 内容容器 |
| 输入框背景 | `#F5F5F5` | 搜索框、输入框 |
| 分割线 | `#0A000000` | 极淡分割线 |

### 12.2 圆角规范

| 元素 | 推荐圆角 |
|------|---------|
| 大卡片 | 16-18vp |
| 中卡片 | 12-14vp |
| 小按钮/标签 | 8-10vp |
| 搜索框 | 20-22vp（全圆角） |
| 头像 | 50%（圆形） |

### 12.3 阴影规范

```typescript
// 轻阴影（卡片悬浮感）
.shadow({ radius: 6, color: '#08000000', offsetX: 0, offsetY: 1 })

// 中阴影（强调层级）
.shadow({ radius: 12, color: '#0E000000', offsetX: 0, offsetY: 3 })

// 重阴影（弹窗/浮层）
.shadow({ radius: 20, color: '#18000000', offsetX: 0, offsetY: 5 })
```

### 12.4 间距规范

| 场景 | 推荐间距 |
|------|---------|
| 页面水平内边距 | 16vp |
| 卡片之间 | 8-10vp |
| 卡片内部 | 14-18vp |
| 标题与内容 | 8-12vp |
| 区块之间 | 16-20vp |

### 12.5 字体规范

| 元素 | 推荐字号 |
|------|---------|
| 页面标题 | 20fp |
| 卡片标题 | 16-18fp |
| 正文 | 14fp |
| 辅助文字 | 12-13fp |
| 标签/徽章 | 10-11fp |

---

## 十三、转场动画

### 13.1 概述

转场动画是页面或组件切换时的过渡效果，是提升用户体验的关键手段。HarmonyOS 提供了丰富的转场能力：

| 类型 | 说明 | 典型场景 |
|------|------|---------|
| 出现/消失转场 | 组件插入/删除时的过渡效果 | 列表项增删、条件渲染切换 |
| 模态转场 | 新界面覆盖旧界面的动画 | 全屏查看大图、半模态分享框 |
| 共享元素转场（一镜到底） | 前后页面中相同元素的平滑过渡 | 列表缩略图→详情大图 |
| 导航转场 | 页面路由的进入/退出动画 | 一级菜单→二级页面 |
| 页面转场 | 自定义页面入场/退场动效 | 全屏页面切换 |

### 13.2 出现/消失转场（TransitionEffect）

`transition` 是基础组件转场接口，通过 `TransitionEffect` 对象组合定义效果：

| 转场效果 | 说明 |
|---------|------|
| `OPACITY` | 透明度渐变（0↔1） |
| `SLIDE` | 从左滑入/右滑出 |
| `translate` | 自定义平移方向 |
| `rotate` | 旋转过渡 |
| `scale` | 缩放过渡 |
| `move` | 从指定边缘滑入/出 |
| `asymmetric` | 出现和消失使用不同效果 |

**使用示例**：

```typescript
import { curves } from '@kit.ArkUI';

@Component
struct FadeList {
  @State items: string[] = ['A', 'B', 'C'];

  // 定义转场效果：淡入淡出 + 弹性缩放
  private itemTransition: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0.8, y: 0.8 })
        .animation({ curve: curves.springMotion(0.6, 0.8) }));

  build() {
    Column() {
      ForEach(this.items, (item: string) => {
        Text(item)
          .width('100%').height(60)
          .backgroundColor(ColorTokens.BG_CARD).borderRadius(12)
          .margin({ top: 8 })
          .transition(this.itemTransition)  // 绑定转场效果
      })
    }
  }
}
```

**非对称转场**（出现和消失效果不同）：

```typescript
TransitionEffect.asymmetric(
  TransitionEffect.OPACITY.combine(
    TransitionEffect.scale({ x: 0, y: 0 })
      .animation({ curve: curves.springMotion() })
  ),  // 出现效果：从0缩放到1
  TransitionEffect.OPACITY.combine(
    TransitionEffect.translate({ y: 100 })
      .animation({ duration: 200 })
  )   // 消失效果：向下滑出
)
```

### 13.3 模态转场

模态转场是新的界面覆盖在旧的界面上，旧界面不消失的转场方式。

| 接口 | 说明 | 使用场景 |
|------|------|---------|
| `bindContentCover` | 全屏模态 | 缩略图→查看大图 |
| `bindSheet` | 半模态 | 分享面板、评论面板 |
| `bindMenu` | 点击弹出菜单 | "+"号操作菜单 |
| `bindContextMenu` | 长按/右键弹出菜单 | 长按浮起效果 |
| `bindPopup` | 气泡弹窗 | 临时说明提示 |

**全屏模态（bindContentCover）示例**：

```typescript
@State isPresent: boolean = false;

Image(this.resource.cover)
  .width(80).height(80).borderRadius(8)
  .bindContentCover(this.isPresent, this.fullScreenBuilder(), {
    modalTransition: ModalTransition.NONE  // 禁用默认动画，使用自定义转场
  })
  .onClick(() => {
    animateTo({ duration: 300 }, () => { this.isPresent = true; });
  })

@Builder
fullScreenBuilder() {
  Column() {
    Image(this.resource.cover)
      .width('100%').objectFit(ImageFit.Contain)
  }
  .transition(TransitionEffect.translate({ y: 1000 })
    .animation({ curve: curves.springMotion(0.6, 0.8) }))
}
```

**半模态（bindSheet）示例**：

```typescript
@State isSheetShow: boolean = false;

Text('评论')
  .onClick(() => { this.isSheetShow = true; })
  .bindSheet(this.isSheetShow, this.commentSheet(), {
    height: '60%',
    showClose: true,
    dragBar: true,
    onDismiss: () => { this.isSheetShow = false; }
  })

@Builder
commentSheet() {
  Column() {
    TextInput({ placeholder: '写评论...' })
    // 评论列表...
  }
  .padding(16)
}
```

### 13.4 共享元素转场（一镜到底）

共享元素转场是一种界面切换时对相同或相似元素做的位置和大小匹配的过渡动画，视觉上如同"一镜到底"。

**搜索转场场景**（强烈推荐）：

```typescript
// 搜索页
Image(item.cover)
  .sharedTransition('cover_' + item.id, {
    duration: 300,
    curve: Curve.EaseInOut,
    delay: 0
  })
  .onClick(() => {
    router.pushUrl({ url: 'pages/DetailPage', params: { id: item.id } });
  })

// 详情页
Image(this.resource.cover)
  .sharedTransition('cover_' + this.resourceId, {
    duration: 300,
    curve: Curve.EaseInOut,
    delay: 0
  })
```

### 13.5 页面间转场设计规范

根据 HarmonyOS 人因研究，不同场景推荐不同转场动效：

| 转场场景 | 推荐动效 | 说明 |
|---------|---------|------|
| 层级转场 | 左右位移遮罩 | 一级→二级页面，左右位移表达层级关系 |
| 搜索转场 | 共享元素（一镜到底） | 搜索结果→详情，元素连续过渡 |
| 新建转场 | 上下位移 | 创建新内容，从底部升起 |
| 编辑转场 | 淡入淡出 | 编辑模式切换，柔和过渡 |
| 通用转场 | 模态转场模板 | 临时展示内容，覆盖式出现 |

**动效时长规范**：

| 类型 | 推荐时长 |
|------|---------|
| 全屏页面转场 | 300-500ms |
| 组件出现/消失 | 200-350ms |
| 模态弹出 | 250-400ms |
| 微交互反馈 | 100-200ms |

---

## 十四、UX 体验标准（官方必审项）

### 14.1 基础体验（必须通过）

| 标准编号 | 标准项 | 要求 | 等级 |
|---------|--------|------|------|
| 2.1.1.1 | 系统返回 | 所有界面响应系统返回；全屏界面提供返回/关闭/取消按钮 | **必须** |
| 2.1.2.1 | 布局基础 | 不同屏幕尺寸上良好显示，无错位/截断/变形/模糊 | **必须** |
| 2.1.2.2 | 挖孔适配 | 重要信息和交互不被摄像头挖孔区遮挡 | **必须** |
| 2.1.3.1 | 手势冲突 | 自定义手势与系统手势无冲突 | **必须** |
| 2.1.3.2 | 手势时长 | 典型手势时长合理（长按≥500ms，双击间隔≤300ms） | **必须** |
| 2.1.3.3 | 点击热区 | **不得小于 40vp × 40vp** | **必须** |
| 2.1.4.1 | 色彩对比度 | 文字与背景对比度满足 WCAG AA 标准（≥4.5:1） | **必须** |
| 2.1.4.2 | 字体大小 | 正文最小 12fp，辅助文字最小 10fp | **必须** |

### 14.2 界面布局（推荐通过）

| 标准编号 | 标准项 | 说明 | 等级 |
|---------|--------|------|------|
| 2.1.2.3 | 元素排布对齐 | 元素左对齐/居中对齐，避免参差不齐 | 推荐 |
| 2.1.2.4 | 文本排版对齐 | 中西文混排时基线对齐 | 推荐 |
| 2.1.2.5 | 留白率达标 | 页面留白率 15%-30%，避免拥挤 | 推荐 |
| 2.1.2.8 | 深度层级合理 | 卡片/控件背景明度有层次区分 | 推荐 |
| 2.1.2.10 | 分组线索清晰 | 相关元素通过间距/分割线/背景色分组 | 推荐 |
| 2.1.2.12 | 元素排布规律性 | 同类元素间距、大小一致 | 推荐 |

### 14.3 动效标准

| 标准编号 | 标准项 | 说明 | 等级 |
|---------|--------|------|------|
| 2.1.5.1.1 | 层级转场 | 采用左右位移运动方式 | 强烈推荐 |
| 2.1.5.1.2 | 搜索转场 | 采用共享元素转场方式 | 强烈推荐 |
| 2.1.5.1.5 | 共享元素转场 | 转场前后持续存续的元素使用共享元素动画 | 强烈推荐 |
| 2.1.5.2.1 | 动效无缺失 | 存在转场动效过渡 | **必须** |
| 2.1.5.2.2 | 转场时长下限 | 全屏页面转场动效时长 ≥ 250ms | **必须** |
| 2.1.5.3.2 | 滑动跟手 | 界面滑动跟手，不卡顿 | **必须** |
| 2.1.5.3.4 | 离手减速 | 滑动离手后自然减速 | **必须** |

### 14.4 系统特性

| 标准编号 | 标准项 | 说明 | 等级 |
|---------|--------|------|------|
| 2.2.1 | 底部导航条适配 | 界面布局适配底部导航条 | **必须** |
| 2.2.4.1 | 悬浮窗适配 | 支持以悬浮窗模式运行 | **必须** |
| 2.2.4.2 | 分屏适配 | 支持上下分屏和左右分屏 | **必须** |
| 2.2.5 | 深色模式 | 需支持深色模式显示 | **必须** |
| 2.2.6 | 状态栏 | 需要对状态栏进行适配 | **必须** |

---

## 十五、交互事件归一

### 15.1 概述

HarmonyOS 提出**交互事件归一**，将不同设备的交互行为转化为同一个交互事件，保证控件在不同交互场景下的体验一致性。开发者只需调用所需接口，无需为每个输入设备单独适配。

### 15.2 各交互事件的多设备映射

| 交互事件 | 触屏 | 手写笔 | 鼠标 | 触控板 | 键盘 | 遥控器 |
|---------|------|--------|------|--------|------|--------|
| **悬浮** | N/A | 笔尖靠近 | 光标移入 | 光标移入 | Tab聚焦 | 方向键聚焦 |
| **点击** | 手指点击 | 笔尖点击 | 左键点击 | 单指点击 | Enter/Space | 确认键 |
| **双击** | 手指双击 | 笔尖双击 | 左键双击 | 双指点击 | — | — |
| **长按** | 手指长按 | 笔尖长按 | 右键点击 | 双指点击 | Shift+F10 | — |
| **上下文菜单** | 长按弹出 | 笔尖长按 | 右键点击 | 双指点击 | Shift+F10 | 菜单键 |
| **拖拽** | 长按拖动 | 笔尖长按拖动 | 左键按住拖动 | 三指拖动 | 方向键+Space | — |
| **滚动/平移** | 单指滑动 | — | 滚轮 | 双指滑动 | 方向键/PgUp/PgDn | 方向键 |
| **轻扫** | 快速滑动 | — | — | — | — | — |
| **缩放** | 双指捏合/展开 | — | Ctrl+滚轮 | 双指捏合/展开 | Ctrl+/- | — |
| **旋转** | 双指旋转 | — | — | 双指旋转 | — | — |

### 15.3 开发要点

1. **使用系统组件**：系统组件已内置交互事件归一，无需额外适配
2. **自定义组件需手动适配**：使用 `onTouch`、`onClick`、`onKeyEvent` 等接口
3. **PC端注意**：鼠标悬浮态（hover）是PC端特有的交互反馈，需通过 `.hoverEffect()` 或 `.onHover()` 实现
4. **焦点管理**：PC端和智慧屏依赖焦点导航，需确保焦点路径合理

```typescript
// PC端鼠标悬浮效果
Row() {
  Text('查看详情')
}
.hoverEffect(HoverEffect.Highlight)
.onHover((isHover: boolean) => {
  // 自定义悬浮态样式
  this.isHovered = isHover;
})
```

---

## 十六、视觉风格规范

### 16.1 色彩系统

HarmonyOS 色彩系统基于 HSB 模式构建，核心原则：

- **主色饱和度**控制在 30%-60% 之间，避免高饱和色彩带来的视觉疲劳
- 所有颜色需通过**资源引用**（`$r`）实现，禁止硬编码，保障多场景适配
- 渐变色采用**统一渐变方向**（上浅下深），不宜使用斜向渐变
- 渐变两端色值保持适度变化，色值差异不宜过大

**9 种推荐色彩方向**：

| 色彩方向 | 语义 | 典型应用 |
|---------|------|---------|
| 蓝色 | 科技、专业、信任 | 工具、效率类应用 |
| 绿色 | 自然、健康、成长 | 生活、运动类应用 |
| 橙色 | 活力、社交、温暖 | 社区、美食类应用 |
| 紫色 | 创意、艺术、个性 | 创作、设计类应用 |
| 红色 | 热情、重要、警示 | 新闻、紧急类应用 |
| 青色 | 清新、沟通、信息 | 通讯、资讯类应用 |
| 粉色 | 浪漫、时尚、关怀 | 美妆、母婴类应用 |
| 金色 | 高端、品质、成就 | 金融、会员类应用 |
| 灰色 | 中性、沉稳、专业 | 商务、系统类应用 |

### 16.2 字体与网格系统

- **动态字阶**：根据设备类型自动调整基准字号
  - TV端：42px
  - 手机端：16px
  - 穿戴设备：24px
- **8dp 基线网格**：组件间距、内边距均取 8dp 的倍数（8/16/24dp）
- **图标网格**：基于 28px 基础网格，0.5px 微描边增强识别度

### 16.3 视觉风格三原则

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| **轻量化** | 通透的毛玻璃效果、克制的投影层次 | `.backdropBlur()` + 淡阴影 |
| **留白呼吸感** | 充足的间距和留白处理 | 8dp网格 + 统一padding |
| **生命力** | 微动效表达状态变化 | 弹性曲线 `springMotion()` |

### 16.4 毛玻璃效果

```typescript
// 标题栏毛玻璃效果
Row() {
  Text('NeUshare')
}
.width('100%').height(56)
.backgroundColor('#80FFFFFF')  // 半透明白色
.backdropBlur(20)              // 模糊效果
```

---

## 十七、应用图标设计规范

### 17.1 设计原则

| 原则 | 说明 |
|------|------|
| 简洁优雅 | 元素简洁，线条优雅，传递设计美学 |
| 极速达意 | 图形准确传达功能、服务和品牌 |
| 细腻质感 | 以光影塑造体积感与层次感 |

### 17.2 多设备图标适配

| 设备 | 图标特点 |
|------|---------|
| 手机/折叠屏/平板 | 简洁视觉语言，高辨识度前景图像，巧用主题色 |
| 电脑 | 扁平设计在物理环境中的投射，鼠标悬浮时生成动态阴影 |
| 智慧屏 | 强调细腻材质，柔和光影效果和鲜亮色彩 |

### 17.3 图标资源规格

| 设备类型 | 推荐尺寸 |
|---------|---------|
| 手机 | 192×192px |
| 平板 | 192×192px |
| PC | 64×64px（SVG矢量优先） |
| 智慧屏 | 192×192px |
| 穿戴 | 96×96px |

---

## 十八、DevEco Studio 模拟器与多设备调试

### 18.1 模拟器类型

DevEco Studio 提供三种模拟器供开发者运行和调试应用：

| 模拟器类型 | 说明 | 优势 | 劣势 |
|-----------|------|------|------|
| **本地模拟器（Local Emulator）** | 创建和运行在本地计算机上 | 无需登录授权，无网络延迟，流畅稳定 | 占用磁盘资源，Windows 仅支持 x86 架构 |
| **远程模拟器（Remote Emulator）** | 运行在华为云端 | 无需本地资源，支持 Tablet 等更多设备 | 需要网络，有延迟 |
| **超级终端模拟器（Super Device）** | 模拟多设备协同 | 调试跨设备流转 | 仅限 Remote Emulator |

### 18.2 支持的设备类型

| 模拟器类型 | 支持设备 |
|-----------|---------|
| 本地模拟器 | Phone、Tablet、2in1、Foldable、TV、Wearable |
| 远程模拟器 | Phone、Tablet、TV、Wearable |
| 超级终端 | Phone+Phone、Phone+Tablet、Phone+TV |

### 18.3 创建本地模拟器

1. 点击菜单栏 **Tools > Device Manager**
2. 在 **Local Emulator** 页签，点击 **New Emulator**
3. 选择设备模板（Phone / Tablet / 2in1 / Foldable / TV / Wearable）
4. 下载对应系统镜像（首次使用需下载）
5. 配置参数：
   - **Name**：模拟器名称
   - **Screen Profile**：选择预置机型或自定义
   - **Memory**：内存（推荐 4GB+）
   - **Storage**：存储空间
6. 点击 **Finish** 创建

### 18.4 自定义屏幕配置（关键！）

从 DevEco Studio 6.0.0 开始，Phone/Tablet/2in1/Foldable 模拟器支持自定义屏幕参数：

- **Screen size**：屏幕对角线长度（inch）
- **Resolution**：宽度×高度（px）
- **DPI**：像素密度

**常用设备屏幕配置参考**：

| 设备类型 | 分辨率 | DPI | 屏幕尺寸 |
|---------|--------|-----|---------|
| 手机（Mate 70） | 1080×2412 | 480 | 6.7" |
| 折叠屏（Mate X6 内屏） | 2048×2224 | 400 | 7.9" |
| 平板（MatePad Pro） | 2560×1600 | 280 | 12.6" |
| **2in1 电脑** | **2560×1600** | **240** | **12.6"** |
| PC（MateBook） | 1920×1080 | 160 | 14" |
| PC 大屏 | 2560×1440 | 160 | 16" |
| TV | 3840×2160 | 320 | 55" |

> **NeUshare 项目建议**：创建一个 2in1 或 Tablet 类型的模拟器，分辨率设为 2560×1600 或 1920×1080，DPI 设为 160，即可模拟 PC 端全屏显示效果，验证大屏布局是否正确。

### 18.5 模拟 PC 端效果的操作步骤

1. **创建 2in1 模拟器**：Tools > Device Manager > New Emulator > 选择 2in1 设备
2. **自定义分辨率**：点击 Customize，设置为 1920×1080 或 2560×1440，DPI 160
3. **启动模拟器**，运行 NeUshare 应用
4. **验证断点**：此时窗口宽度 > 1440vp，应触发 `xl` 断点，Tabs 切换为侧边栏模式
5. **拖拽窗口边缘**调整大小，观察断点切换效果

### 18.6 模拟器扩展能力

模拟器还支持以下扩展能力（点击模拟器菜单栏的扩展按钮）：

| 能力 | 说明 |
|------|------|
| 电池 | 模拟不同电量、充电状态 |
| GPS 定位 | 手动设置经纬度、导入 GPX 轨迹 |
| 虚拟传感器 | 计步、环境光、心率 |
| 网络 | 模拟不同网络类型和速度 |
| 摄像头 | 模拟摄像头输入 |
| 多屏 | 添加扩展屏幕，模拟多窗口 |

### 18.7 系统要求

| 平台 | 最低要求 |
|------|---------|
| Windows | Win10/11 64位，内存 16GB+，硬盘 100GB+ |
| macOS | 11/12/13/14/15，内存 8GB+，硬盘 100GB+ |

**注意事项**：
- Windows 仅支持 x86_64 模拟器，不支持 ARM 模拟器
- ARM 模拟器仅在 macOS M 系列芯片上支持
- 不支持在虚拟机内运行本地模拟器
- CPU 虚拟化（Intel VT-x / AMD-V）必须开启

### 18.8 预览器（Previewer）快速调试

除了模拟器，DevEco Studio 还提供 **Previewer** 预览器，可以实时查看代码修改效果：

- 点击右侧 **Previewer** 面板即可实时预览
- 支持通过 **Profile Manager** 切换不同屏幕尺寸预览
- 预览器响应速度比模拟器快，适合 UI 微调
- 但预览器不支持部分系统 API（如路由跳转），完整测试仍需模拟器

---

## 十九、NeUshare 项目可落地的视觉优化清单

基于以上教程内容，以下是 NeUshare 项目可以立即落地的优化项：

### 高优先级（影响大、改动小）

| 优化项 | 对应章节 | 预期效果 |
|--------|---------|---------|
| 卡片出现/消失添加 `transition` 淡入淡出 | 十三 | 列表增删不再生硬 |
| 点击热区 ≥ 40vp | 十四 | 所有按钮和可点击元素手感提升 |
| 色彩对比度检查 | 十四 | 文字可读性提升 |
| PC端添加 hover 效果 | 十五 | 鼠标悬浮反馈 |

### 中优先级（体验提升明显）

| 优化项 | 对应章节 | 预期效果 |
|--------|---------|---------|
| 详情页共享元素转场 | 十三 | 列表→详情的"一镜到底"效果 |
| 半模态评论面板 | 十三 | 评论交互更自然 |
| 标题栏沉浸式 | 九 | 状态栏与页面视觉统一 |
| 深色模式适配 | 十一 | 暗光环境体验提升 |

### 低优先级（锦上添花）

| 优化项 | 对应章节 | 预期效果 |
|--------|---------|---------|
| HdsNavigation 沉浸光感 | 十 | 高级质感（需API 12+） |
| 悬浮页签 | 十 | 底部导航毛玻璃效果 |
| 毛玻璃标题栏 | 十六 | 滚动时标题栏半透明模糊 |
| 8dp网格对齐 | 十六 | 布局更规律 |

---

## 参考链接

- [一次开发，多端部署概览](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-overview)
- [响应式布局](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-responsive-layout)
- [组件布局场景](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-component-layout)
- [屏幕类型布局场景](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-screen-layout)
- [多设备体验设计](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-design-principles)
- [多设备界面开发](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-page)
- [窗口沉浸式](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-immersive)
- [开发应用沉浸式效果](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-develop-apply-immersive-effects)
- [安全区域 expandSafeArea](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-expand-safe-area)
- [沉浸光感材质](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-component-material)
- [模态转场](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-modal-transition)
- [出现/消失转场](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-enter-exit-transition)
- [页面间转场最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-page-transition)
- [组件内转场 transition API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-transition-animation-component)
- [通用应用 UX 体验标准](https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-general-0000001760708152)
- [元服务 UX 体验标准](https://developer.huawei.com/consumer/cn/doc/design-guides/ux-standard-overview-0000002019655177)
- [交互事件归一](https://developer.huawei.com/consumer/cn/doc/design-guides/hmi-interaction-events-0000001795531217)
- [应用图标设计](https://developer.huawei.com/consumer/cn/doc/design-guides/application-icon-0000001953444009)
- [创建模拟器](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-emulator-create)
- [自定义屏幕配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-emulator-customize-screen-configuration)
- [模拟器扩展能力](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-emulator-more-features)
- [使用模拟器运行应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-run-emulator)
- [鸿蒙界面设计技术解析与实战案例](https://developer.huawei.com/consumer/cn/blog/topic/03210849486697273)
- [ArkUI沉浸式和深色模式 Codelab](https://developer.huawei.com/consumer/cn/codelabsPortal/carddetails/tutorials_NEXT-ImmersiveAndDarkModeFit)
- [悬浮页签+沉浸光感教程](https://developer.huawei.com/consumer/cn/blog/topic/03212754921821215)
- [Ability Kit 简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/abilitykit-overview)
- [官方示例代码 ResponsiveLayout](https://gitcode.com/HarmonyOS_Samples/ResponsiveLayout)
- [官方示例代码 沉浸式+深色模式](https://gitcode.com/HarmonyOS_Codelabs/immersive-and-dark-mode-fit)
