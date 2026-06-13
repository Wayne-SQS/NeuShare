# HarmonyOS 功能开发教程

> 内容来源：华为开发者官方文档 https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ability-kit
> 整理时间：2026-06-13

---

## 一、Ability Kit（程序框架服务）

### 1.1 概述

Ability Kit 提供应用程序开发和运行的应用模型。开发者可以基于应用模型，实现不同类型的应用组件，高效完成应用生命周期管理、组件间交互、进程线程管理等业务逻辑。

### 1.2 核心能力

| 能力 | 说明 |
|------|------|
| 应用进程创建/销毁 | 应用生命周期调度 |
| 应用组件运行入口 | UIAbility 生命周期调度、组件间交互 |
| 应用上下文环境 | 系统环境变化监听、组件生命周期监听 |
| 启动框架 | 应用启动优化 |
| 意图框架 | 统一意图识别与分发 |
| 应用流转 | 跨端迁移、多端协同 |
| 多包机制 | HAP/HAR/HSP 共享包 |
| 应用快捷方式 | 桌面快捷方式 |
| 访问控制 | 权限管理 |
| 密码自动填充 | 安全密码服务 |

### 1.3 四大亮点

**1. UI 与业务逻辑分离**

- 业务逻辑层 → UI：Ability 完成核心逻辑，通过绑定机制传递数据至 ArkUI，声明式自动渲染
- UI → 业务逻辑层：捕获用户交互输入，通过事件回调/状态绑定反向同步至 Ability

**2. 应用组件级跨端迁移和多端协同**

- 跨端迁移：系统在多设备间迁移数据/状态，ArkUI 利用声明式特点恢复界面
- 多端协同：应用组件具备 RPC 调用能力，天然支持跨设备交互

**3. 多设备和多窗口形态**

- 应用组件管理与窗口管理架构层面解耦
- 无屏设备可裁剪窗口
- 多设备使用同一套生命周期

**4. 平衡应用能力和系统管控成本**

- 后台进程有序治理，应用不能随意驻留后台
- 后台行为受严格管理，防止恶意应用

### 1.4 Module 类型

| Module 类型 | 说明 | 用途 |
|------------|------|------|
| HAP | 应用功能模块 | 实现应用的功能和特性 |
| HAR | 静态共享包 | 代码和资源共享（编译时合并） |
| HSP | 动态共享包 | 代码和资源共享（运行时加载，多 HAP 共用一份） |

### 1.5 应用间交互方式

| 方式 | 说明 | 适用场景 |
|------|------|---------|
| 显式 Want | 指定目标应用包名和 Ability 名 | 应用内跳转 |
| Deep Linking | 基于 URI 匹配本地已安装应用 | 应用间跳转（已安装） |
| App Linking | 基于域名验证的应用链接 | 社交分享跳转（支持未安装直达应用市场） |

---

## 二、通知系统（Notification Kit）

### 2.1 概述

Notification Kit 提供通知发布、取消、管理能力，支持普通文本、长文本、多行文本、图片等通知类型。

### 2.2 通知类型

| 类型 | 说明 | 适用场景 |
|------|------|---------|
| 普通文本 | 标题+内容 | 一般消息提醒 |
| 长文本 | 展开显示更多内容 | 文章摘要、详细通知 |
| 多行文本 | 多行列表内容 | 消息列表 |
| 图片 | 附带图片 | 图片消息、截图通知 |
| 进度条 | 下载/上传进度 | 文件传输 |
| 实时状态 | 持续显示 | 运动数据、导航 |

### 2.3 发布通知基本步骤

```typescript
import { notificationManager } from '@kit.NotificationKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';

// 1. 创建 WantAgent（点击通知后跳转目标页面）
let wantAgentInfo: wantAgent.WantAgentInfo = {
  wants: [{
    bundleName: 'com.neushare.app',
    abilityName: 'EntryAbility',
  }],
  actionType: wantAgent.OperationType.START_ABILITY,
  requestCode: 0,
  actionFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
};

let wantAgentObj: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);

// 2. 构建通知请求
let notificationRequest: notificationManager.NotificationRequest = {
  id: 1,
  content: {
    notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
    normal: {
      title: '审核通知',
      text: '您上传的资料已通过审核',
    }
  },
  wantAgent: wantAgentObj,  // 点击跳转
};

// 3. 发布通知
notificationManager.publish(notificationRequest);
```

### 2.4 通知角标（Badge）

```typescript
// 设置角标数字
notificationManager.setBadgeNumber(3);

// 通知请求中配置角标
let request: notificationManager.NotificationRequest = {
  id: 1,
  badgeNumber: 1,  // 此通知产生的角标数
  // ...
};
```

### 2.5 WantAgent 行为意图

通知携带 WantAgent 后，用户点击通知可执行以下动作：

| 动作类型 | 说明 |
|---------|------|
| `START_ABILITY` | 拉起指定 UIAbility |
| `START_ABILITIES` | 拉起多个 UIAbility |
| `START_SERVICE_EXTENSION` | 拉起 ServiceExtension |
| `SEND_COMMON_EVENT` | 发送公共事件 |

### 2.6 NeUshare 应用场景

| 场景 | 通知内容 | 点击行为 |
|------|---------|---------|
| 资料审核通过 | "您上传的《XX》已通过审核" | 跳转到资料详情页 |
| 资料审核驳回 | "您上传的《XX》被驳回：原因..." | 跳转到我的资料页 |
| 评论回复 | "XX 回复了你的评论" | 跳转到评论详情 |
| 新粉丝 | "XX 关注了你" | 跳转到个人主页 |
| 收藏/点赞 | "XX 收藏了你的资料" | 跳转到资料详情 |

---

## 三、推送服务（Push Kit）

### 3.1 概述

Push Kit 提供服务端向客户端推送消息的能力，支持通知消息和数据消息两种类型。

### 3.2 消息分类

| 类别 | 提醒方式 | 展示位置 | 推送数量 |
|------|---------|---------|---------|
| **服务与通讯** | 铃声/振动 | 通知中心+锁屏+横幅+角标 | 无限制 |
| **资讯营销** | 静默 | 通知中心+角标 | 2条/天 或 5条/天 |

### 3.3 通知消息样式

| 样式 | 说明 |
|------|------|
| 普通通知 | 标题+内容+图标 |
| 通知角标 | 应用图标上显示数字 |
| 通知大图标 | 通知左侧大图标 |
| 多行文本 | 展开显示多行内容 |
| 自定义铃声 | 为通知设置专属铃声 |

### 3.4 点击消息动作

| 动作 | 说明 |
|------|------|
| 进入应用首页 | 默认行为 |
| 进入应用内页 | 通过 WantAgent 指定目标页面 |
| 自定义数据传递 | 通过 parameters 传递额外数据 |

---

## 四、后台任务（Background Tasks Kit）

### 4.1 概述

应用退至后台后，系统会对后台进程进行管控。如果应用需要在后台长时间运行用户可感知的任务，需要申请长时任务。

### 4.2 长时任务类型

| 类型 | 配置项 | 场景举例 |
|------|--------|---------|
| DATA_TRANSFER | dataTransfer | 后台上传/下载数据 |
| AUDIO_PLAYBACK | audioPlayback | 音视频后台播放 |
| AUDIO_RECORDING | audioRecording | 录音、录屏退后台 |
| LOCATION | location | 定位、导航 |
| BLUETOOTH_INTERACTION | bluetoothInteraction | 蓝牙传输文件 |
| MULTI_DEVICE_CONNECTION | multiDeviceConnection | 分布式业务连接、投播 |
| VOIP | voip | 音视频通话退后台 |
| TASK_KEEPING | taskKeeping | 计算任务（仅PC/2in1） |
| MODE_AV_PLAYBACK_AND_RECORD | avPlaybackAndRecord | 多媒体综合（API 22+） |

### 4.3 申请长时任务步骤

```typescript
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';

// 1. 创建 WantAgent
let wantAgentInfo: wantAgent.WantAgentInfo = {
  wants: [{ bundleName: 'com.neushare.app', abilityName: 'EntryAbility' }],
  actionType: wantAgent.OperationType.START_ABILITY,
  requestCode: 0,
};
let wantAgentObj: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);

// 2. 申请长时任务
backgroundTaskManager.startBackgroundRunning(
  context,
  backgroundTaskManager.BackgroundMode.DATA_TRANSFER,
  wantAgentObj
);

// 3. 任务完成后取消
backgroundTaskManager.stopBackgroundRunning(context);
```

### 4.4 约束与限制

- 申请长时任务后，通知栏会显示关联消息
- 用户删除通知栏消息时，系统自动停止长时任务
- 长时任务类型必须与实际行为一致，系统会做一致性校验
- 需在 `module.json5` 中声明对应权限

### 4.5 NeUshare 应用场景

| 场景 | 长时任务类型 | 说明 |
|------|------------|------|
| 资料文件下载 | DATA_TRANSFER | 大文件后台下载 |
| 资料文件上传 | DATA_TRANSFER | 大文件后台上传 |

---

## 五、数据持久化

### 5.1 三种持久化方式对比

| 方式 | 数据类型 | 适用场景 | 数据量 |
|------|---------|---------|--------|
| **用户首选项（Preferences）** | Key-Value | 个性化设置、轻量配置 | < 16KB |
| **关系型数据库（RDB）** | 关系型表结构 | 复杂关系数据 | 较大 |
| **分布式数据** | Key-Value / 关系型 | 多设备数据同步 | 中等 |

### 5.2 用户首选项（Preferences）

适用于保存用户的个性化设置（字体大小、夜间模式、登录状态等）。

```typescript
import { preferences } from '@kit.ArkData';

// 1. 获取 Preferences 实例
let pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: 'neushare_prefs' });

// 2. 写入数据
pref.putSync('isDarkMode', false);
pref.putSync('fontSize', 14);
pref.putSync('lastLoginTime', '2026-06-13');
pref.flushSync();  // 持久化到文件

// 3. 读取数据
let isDarkMode: boolean = pref.getSync('isDarkMode', false);
let fontSize: number = pref.getSync('fontSize', 14);

// 4. 删除数据
pref.deleteSync('lastLoginTime');
pref.flushSync();
```

**存储模式**：

| 模式 | 起始版本 | 特点 | 适用场景 |
|------|---------|------|---------|
| XML | 4.0 | 通用性强，跨平台 | 单进程、小数据量 |
| GSKV | 18 | 二进制存储，支持多进程并发读写 | 多进程并发场景 |

### 5.3 关系型数据库（RDB）

基于 SQLite，适用于复杂关系数据。

```typescript
import { relationalStore } from '@kit.ArkData';

// 1. 创建数据库
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'neushare.db',
  securityLevel: relationalStore.SecurityLevel.S1,
};
let store: relationalStore.Store = await relationalStore.getRdbStore(context, STORE_CONFIG);

// 2. 创建表
const SQL_CREATE_TABLE = `
  CREATE TABLE IF NOT EXISTS download_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    resource_id INTEGER NOT NULL,
    file_name TEXT,
    local_path TEXT,
    download_time TEXT,
    status INTEGER DEFAULT 0
  )
`;
await store.executeSql(SQL_CREATE_TABLE);

// 3. 插入数据
let valueBucket: relationalStore.ValuesBucket = {
  resource_id: 1,
  file_name: '高等数学笔记.pdf',
  local_path: '/data/download/math.pdf',
  download_time: '2026-06-13 10:00:00',
  status: 1,
};
await store.insert('download_record', valueBucket);

// 4. 查询数据
let predicates = new relationalStore.RdbPredicates('download_record');
predicates.equalTo('status', 1).orderByDesc('download_time');
let resultSet = await store.query(predicates);
```

### 5.4 NeUshare 应用场景

| 场景 | 持久化方式 | 存储内容 |
|------|-----------|---------|
| 用户设置 | Preferences | 深色模式、字体大小、搜索历史 |
| 登录状态 | Preferences | token、用户基本信息缓存 |
| 下载记录 | RDB | 下载文件列表、进度、状态 |
| 离线缓存 | RDB | 已缓存的资料详情、评论 |

---

## 六、文件上传下载

### 6.1 上传文件

```typescript
import { request } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

// 方式一：request.uploadFile（仅支持 cacheDir 下的文件）
let uploadConfig: request.UploadConfig = {
  url: 'https://api.neushare.com/api/resource/create',
  header: { 'Authorization': 'Bearer ' + token },
  method: 'POST',
  files: [{ filename: 'file', name: 'file', uri: 'internal://cache/test.pdf', type: 'pdf' }],
  data: [{ name: 'title', value: '高等数学笔记' }],
};
let uploadTask = await request.uploadFile(context, uploadConfig);

uploadTask.on('progress', (uploadedSize, totalSize) => {
  console.log(`上传进度: ${uploadedSize}/${totalSize}`);
});
uploadTask.on('complete', () => { console.log('上传完成'); });

// 方式二：request.agent（支持用户公共文件）
let agentConfig: request.AgentConfig = {
  action: request.Action.UPLOAD,
  url: 'https://api.neushare.com/api/resource/create',
  header: { 'Authorization': 'Bearer ' + token },
  files: [{
    filename: 'file',
    name: 'file',
    uri: 'file:///data/upload/test.pdf',
    type: 'pdf'
  }],
  data: [{ name: 'title', value: '高等数学笔记' }],
};
let agent = await request.agent.create(context, agentConfig);
```

### 6.2 下载文件

```typescript
import { request } from '@kit.BasicServicesKit';

// 下载到应用文件目录
let downloadConfig: request.DownloadConfig = {
  url: 'https://api.neushare.com/uploads/math_notes.pdf',
  header: { 'Authorization': 'Bearer ' + token },
  filePath: context.filesDir + '/math_notes.pdf',  // 保存路径
};
let downloadTask = await request.downloadFile(context, downloadConfig);

downloadTask.on('progress', (receivedSize, totalSize) => {
  console.log(`下载进度: ${receivedSize}/${totalSize}`);
});
downloadTask.on('complete', () => { console.log('下载完成'); });
```

### 6.3 下载通知栏跳转

从 API 22 开始，支持点击下载通知跳转到应用指定页面：

```typescript
let wantAgentInfo: wantAgent.WantAgentInfo = {
  wants: [{ bundleName: 'com.neushare.app', abilityName: 'EntryAbility' }],
  actionType: wantAgent.OperationType.START_ABILITY,
  requestCode: 0,
};
let wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo);

let notification: request.agent.Notification = {
  title: '资料下载',
  content: '正在下载《高等数学笔记》',
  wantAgent: wantAgentObj,  // 点击通知跳转
};
```

### 6.4 NeUshare 应用场景

| 场景 | 操作 | 说明 |
|------|------|------|
| 上传资料 | request.agent + FormData | 支持文件+表单数据同时上传 |
| 下载资料 | request.downloadFile | 下载到应用沙箱，带进度通知 |
| 头像上传 | request.uploadFile | 小文件上传 |

---

## 七、服务卡片（Form Kit）

### 7.1 概述

Form Kit 提供在桌面、锁屏等系统应用上嵌入显示应用信息的开发框架。将应用内用户关注的重要信息或常用操作抽取到服务卡片上，达到信息展示、服务直达的便捷体验。

### 7.2 卡片类型

| 类型 | 说明 | 更新方式 |
|------|------|---------|
| 静态卡片 | 纯展示，不交互 | 定时刷新 |
| 动态卡片 | 支持交互操作 | 实时更新 |

### 7.3 卡片使用场景

| 场景 | 卡片内容 | 交互 |
|------|---------|------|
| 热门资料推荐 | 最新/最热资料标题+缩略图 | 点击跳转详情 |
| 个人资料统计 | 上传数/收藏数/获赞数 | 点击跳转个人主页 |
| 待审核提醒 | 管理员：待审核数量 | 点击跳转审核页 |
| 搜索快捷入口 | 搜索框 | 点击跳转搜索页 |

### 7.4 卡片与主应用数据共享

**方案一：用户首选项共享**

```typescript
// 主应用写入
let pref = preferences.getPreferencesSync(context, { name: 'widget_data' });
pref.putSync('hotResourceTitle', '高等数学笔记');
pref.putSync('hotResourceCount', '128次收藏');
pref.flushSync();

// 卡片读取
let pref = preferences.getPreferencesSync(context, { name: 'widget_data' });
let title = pref.getSync('hotResourceTitle', '') as string;
```

**方案二：关系型数据库共享**

适用于卡片与主应用之间共享复杂数据。

### 7.5 卡片生命周期

```typescript
import { formProvider } from '@kit.AbilityKit';

// 更新卡片数据
formProvider.updateForm(formId, formBindingData.createFormBindingData({
  title: '高等数学笔记',
  count: '128次收藏',
}));
```

---

## 八、分享服务（Share Kit）

### 8.1 概述

Share Kit 提供系统标准分享面板，支持将内容分享到其他应用、复制、打印等。

### 8.2 基本用法

```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

// 1. 构造分享数据
let sharedData = new systemShare.SharedData();
let record: systemShare.SharedRecord = {
  utd: utd.UniformDataType.HYPERLINK,  // 分享链接
  content: 'https://neushare.com/resource/1',
  title: '高等数学笔记 - NeUshare',
  description: '东北大学学习资料分享平台',
  thumbnailUri: 'https://neushare.com/cover/math.jpg',
};
sharedData.addRecord(record);

// 2. 拉起分享面板
let controller = new systemShare.ShareController(sharedData);
controller.show(context, {
  previewMode: systemShare.SharePreviewMode.DEFAULT,
  selectionMode: systemShare.SelectionMode.SINGLE,
});
```

### 8.3 分享数据类型

| UTD 类型 | 说明 | 适用场景 |
|---------|------|---------|
| HYPERLINK | 链接 | 分享资料链接 |
| TEXT | 纯文本 | 分享文字内容 |
| IMAGE | 图片 | 分享截图 |
| FILE | 文件 | 分享PDF等文件 |

### 8.4 碰一碰分享

HarmonyOS 5+ 支持两台手机碰一碰分享内容：

1. 注册碰一碰事件
2. 设置分享预览（卡片样式）
3. 发送分享数据（App Linking / Deep Linking）

### 8.5 NeUshare 应用场景

| 场景 | 分享内容 | 方式 |
|------|---------|------|
| 分享资料 | 资料链接+标题+缩略图 | Share Kit 面板 |
| 分享个人主页 | 个人主页链接 | Share Kit 面板 |
| 碰一碰分享 | 资料卡片 | 碰一碰 |

---

## 九、应用间跳转

### 9.1 三种跳转方式对比

| 方式 | 目标应用状态 | 是否需要配置 | 用户体验 |
|------|------------|------------|---------|
| **Deep Linking** | 必须已安装 | module.json5 配置 skills | 本地匹配，未安装提示"暂无可用打开方式" |
| **App Linking** | 未安装可跳应用市场 | AGC 配置域名验证 | 一键直达，未安装自动引导安装 |
| **显式 Want** | 必须已知包名 | 无 | 应用内跳转 |

### 9.2 Deep Linking 实现

**目标应用配置**（module.json5）：

```json
{
  "module": {
    "abilities": [{
      "skills": [{
        "actions": ["ohos.want.action.viewData"],
        "uris": [{
          "scheme": "neushare",
          "host": "resource",
          "path": "/detail"
        }]
      }]
    }]
  }
}
```

**拉起方调用**：

```typescript
import { common } from '@kit.AbilityKit';

// 方式一：openLink
context.openLink('neushare://resource/detail?id=1');

// 方式二：startAbility
let want: Want = {
  action: 'ohos.want.action.viewData',
  uri: 'neushare://resource/detail?id=1',
};
context.startAbility(want);
```

**目标应用解析参数**：

```typescript
// EntryAbility.ets
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  let uri = want.uri;  // neushare://resource/detail?id=1
  let resourceId = want.parameters?.id;  // 1
}
```

### 9.3 App Linking 实现

App Linking 基于 HTTPS 链接，通过 AGC（AppGallery Connect）验证域名归属，实现更安全的跳转。

**三种跳转场景**：

| 场景 | 行为 |
|------|------|
| 目标应用已安装 | 直接拉起目标应用对应页面 |
| 未安装 + 配置直达应用市场 | 跳转应用市场安装，安装后延迟链接直达 |
| 未安装 + 有 Web 页面 | 浏览器打开 Web 页面，引导安装 |

### 9.4 NeUshare 应用场景

| 场景 | 跳转方式 | URI 格式 |
|------|---------|---------|
| 分享资料链接 | App Linking | `https://neushare.com/resource/detail?id=1` |
| 社交分享直达 | App Linking | 同上，未安装引导安装 |
| 应用内跳转 | Deep Linking | `neushare://resource/detail?id=1` |

---

## 十、应用跨端流转

### 10.1 概述

HarmonyOS 支持应用在多设备间自由流转，包括**跨端迁移**和**多端协同**两种模式。

### 10.2 跨端迁移

将当前设备上的应用状态完整迁移到目标设备，当前设备应用退出。

**典型场景**：手机上查看资料详情 → 迁移到平板大屏继续阅读

```typescript
// 1. 在 UIAbility 中实现迁移回调
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  // 保存迁移数据
  wantParam['resourceId'] = this.resourceId;
  wantParam['scrollPosition'] = this.scrollPosition;
  return AbilityConstant.OnContinueResult.AGREE;
}

// 2. 目标设备恢复数据
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
    this.resourceId = want.parameters?.resourceId;
    this.scrollPosition = want.parameters?.scrollPosition;
  }
}
```

### 10.3 多端协同

两个设备上的应用组件同时运行，通过 RPC 通信协同工作。

**典型场景**：手机作为遥控器，智慧屏显示资料详情

### 10.4 流转体验设计

| 设计要点 | 说明 |
|---------|------|
| 流转入口 | 在界面提供明确的流转按钮 |
| 状态恢复 | 迁移后完整恢复用户操作状态 |
| 流转提示 | 迁移过程中显示加载/过渡动画 |
| 失败处理 | 流转失败时给出明确提示，不丢失数据 |

---

## 十一、网络管理（Network Kit）

### 11.1 HTTP 请求

```typescript
import { http } from '@kit.NetworkKit';

// GET 请求
let response = await http.request('https://api.neushare.com/api/resource/list', {
  method: http.RequestMethod.GET,
  header: { 'Authorization': 'Bearer ' + token },
  extraData: { pageNum: 1, pageSize: 10 },
});

// POST 请求（JSON body）
let response = await http.request('https://api.neushare.com/api/auth/login', {
  method: http.RequestMethod.POST,
  header: { 'Content-Type': 'application/json' },
  extraData: { username: 'test', password: '123456' },
});
```

### 11.2 网络状态监听

```typescript
import { connection } from '@kit.NetworkKit';

// 监听网络变化
connection.on('netChange', (netHandle: connection.NetHandle) => {
  let netCapabilities = connection.getNetCapabilitiesSync(netHandle);
  if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
    console.log('已连接 WiFi');
  }
});
```

### 11.3 网络配置（API 22+）

```typescript
// 自定义请求方法
let httpResponse = await http.request(url, {
  customMethod: 'PATCH',
});

// 最大重定向次数
let httpResponse = await http.request(url, {
  maxRedirects: 3,
});
```

---

## 十二、访问控制与安全

### 12.1 权限申请

```typescript
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

// 申请权限
async function requestPermission(context: common.UIAbilityContext, permission: Permissions): Promise<boolean> {
  let atManager = abilityAccessCtrl.createAtManager();
  try {
    let result = await atManager.requestPermissionsFromUser(context, [permission]);
    return result.authResults[0] === 0;
  } catch (err) {
    return false;
  }
}

// 使用
let granted = await requestPermission(context, 'ohos.permission.INTERNET');
```

### 12.2 NeUshare 所需权限

| 权限 | 说明 | 等级 |
|------|------|------|
| `ohos.permission.INTERNET` | 网络访问 | normal |
| `ohos.permission.GET_NETWORK_INFO` | 获取网络信息 | normal |
| `ohos.permission.NOTIFICATION_CONTROLLER` | 通知管理 | system_core |

---

## 十三、NeUshare 功能完善对照表

### 已实现

| 功能 | 实现方式 | 对应文件 |
|------|---------|---------|
| HTTP 请求 | HttpClient 封装 | common/network/HttpClient.ets |
| 登录/注册 | AuthApi | entry/src/main/ets/api/AuthApi.ets |
| 资源 CRUD | ResourceApi | entry/src/main/ets/api/ResourceApi.ets |
| 评论 | CommentApi | entry/src/main/ets/api/CommentApi.ets |
| 收藏 | FavoriteApi | entry/src/main/ets/api/FavoriteApi.ets |
| 点赞 | ResourceApi.like | entry/src/main/ets/api/ResourceApi.ets |
| 关注 | FollowApi | entry/src/main/ets/api/FollowApi.ets |
| 通知 | NotificationApi | entry/src/main/ets/api/NotificationApi.ets |
| 轮播图 | BannerApi | entry/src/main/ets/api/BannerApi.ets |
| 分类 | CategoryApi | entry/src/main/ets/api/CategoryApi.ets |
| 管理后台 | AdminApi | entry/src/main/ets/api/AdminApi.ets |

### 待实现（按优先级）

| 功能 | 对应章节 | 优先级 | 说明 |
|------|---------|--------|------|
| 系统通知推送 | 二、三 | **高** | 审核结果、评论回复等推送系统通知 |
| 文件下载进度通知 | 六 | **高** | 下载资料时显示进度通知 |
| 用户首选项存储 | 五 | **高** | 搜索历史、深色模式偏好、字体大小 |
| 离线缓存（RDB） | 五 | 中 | 缓存已查看的资料详情 |
| 分享面板 | 八 | 中 | 分享资料链接到其他应用 |
| Deep Linking | 九 | 中 | 支持通过链接直接打开资料详情 |
| 服务卡片 | 七 | 中 | 桌面卡片展示热门资料 |
| 后台下载 | 四 | 中 | 大文件后台下载 |
| 跨端迁移 | 十 | 低 | 手机→平板阅读迁移 |
| App Linking | 九 | 低 | 社交分享一键直达 |
| 碰一碰分享 | 八 | 低 | 两台手机碰一碰分享资料 |

---

## 参考链接

- [Ability Kit 简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/abilitykit-overview)
- [应用模型](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-models)
- [Notification Kit](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/notification-kit)
- [为通知添加行为意图](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/notification-with-wantagent)
- [Push Kit 推送服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-kit-guide)
- [发送通知消息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-send-alert)
- [Background Tasks Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/background-task-kit)
- [长时任务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/continuous-task)
- [数据持久化-用户首选项](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-preferences)
- [数据持久化-关系型数据库](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-rdb-store)
- [应用文件上传下载](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-file-upload-download)
- [Form Kit 卡片开发](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/formkit-overview)
- [卡片与主应用数据共享](https://developer.huawei.com/consumer/cn/doc/architecture-guides/common-v1_26-ts_620-0000002535288512)
- [Share Kit 分享服务](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/share-kit-guide)
- [社交分享跳转](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-social-share)
- [碰一碰分享](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/knock-share)
- [Deep Linking 应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/deep-linking-startup)
- [App Linking 应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startup)
- [应用跨端流转](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-hopping)
- [Network Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/network-kit)
- [访问控制](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/access-token-overview)
- [HarmonyOS 应用开发基础解决方案白皮书](https://developer.huawei.com/consumer/cn/doc/guidebook/solution2-0000002601573491)
