# M0 契约黄金基准：结果与缺陷清单

> 生成方式：Java 参考实现（8081）× Python 实现（8082）双实例交错回放，逐字段比对。
> 两个实例各自连一套**从同一份 dump 恢复**的数据库，保证响应可比。
> 复现命令见文末。

## 1. 方法与规模

| 项 | 值 |
|---|---|
| Java 端点（源码注解扫描） | 84 |
| 用例数 | 147（84 端点全覆盖 + 63 个负例/边界/写链路） |
| 只读用例（可随时重放） | 89 |
| 写操作用例（需可丢弃库） | 58 |
| 比对字段 | 状态码、媒体类型、`Content-Disposition`、`Location`、完整 JSON 树 |

归一化只做三件事，且**保留字段形态**（不会把差异抹平）：

- `token` → `<token>`
- 时间戳 → `<timestamp:isoT>` 或 `<timestamp:space>`（样式本身参与比对）
- 上传文件名 UUID → `<uuid>`
- 逗号拼接的校验消息按集合比较（Java 侧顺序不稳定，见第 4 节）

## 2. 工具自证（这一步决定结论可不可信）

| 回放目标 | 结果 |
|---|---|
| Java 自己（黄金基准的出处） | **89 / 89 通过** |
| Python 实现 | **37 通过 / 52 失败** |

同一套用例量 Java 自己 100% 通过，说明失败项不是"工具噪声"，是真实契约差异。

## 3. 缺陷清单（8 类根因，52 个只读用例失败）

### F1 · 时间格式不一致 · P0 · 影响 37 个用例、约 600 处字段

```
GET /api/banner/list
  Java  : "createTime": "2026-11-14T13:01:48"     ← ISO-8601，带 T
  Python: "createTime": "2026-11-14 13:01:48"     ← 空格分隔
```

`spring.jackson.date-format` 对 `LocalDateTime`（JSR-310）不生效，Java 实际走 ISO 序列化。
Python 侧按"配置里写的格式"实现，反而与真实输出不一致。
影响所有含 `createTime` / `updateTime` / `favoriteTime` 的响应；客户端 `new Date(str)` 对空格格式在部分 WebView/ArkTS 环境不可靠。

**修复**：Python 序列化统一输出 `yyyy-MM-ddTHH:mm:ss`（与 Java 同秒级精度）。

### F2 · 分页参数未规范化 · P0 · 影响 6 个用例

| 请求 | Java（参考） | Python |
|---|---|---|
| `pageNum=0` | `code=200`，`current=1`，正常数据 | `code=500 系统异常，请稍后重试` |
| `pageNum=-3` | 同上（夹到 1） | `code=500 系统异常` |
| `pageSize=-1` | `code=200`，`pages=0`，返回 10 条 | `code=500 系统异常` |
| `pageSize=0` | `code=500 系统异常`（Java 自身缺陷） | `code=200`，`records=[]`，`total=114` |
| `pageSize=100000` | `size=100`、`records=100`、`pages=2` | `size=100000`、`records=114`、`pages=1` |

Java 的上限来自 `PaginationInnerInterceptor.setMaxLimit(100L)`（`MybatisPlusConfig`），Python 无任何上限。
负 `pageNum` 在 Python 会生成负 OFFSET → SQL 报错 → 500，**客户端可控输入直接 500**。

**修复**：统一分页依赖，`pageNum = max(1, pageNum)`，`pageSize = clamp(pageSize, 1, 100)`；
`pageSize=0` 保留为已知例外（Java 自身 500），Python 输出 `400 参数格式错误：pageSize` 或复刻 500，二选一并记录。

### F3 · 非信封响应逃逸 · P0 · 影响 2 个用例

```
GET /api/favorite/add        （GET 打在 POST 路由上）
  Java  : HTTP 200  {"code":500,"message":"系统异常，请稍后重试","data":null}
  Python: HTTP 405  {"detail":"Method Not Allowed"}

GET /api/nope/nope
  Java  : HTTP 401  {"code":401,"message":"未登录或登录已过期","data":null}
  Python: HTTP 404  {"detail":"Not Found"}
```

前端/鸿蒙的响应拦截器读 `res.data.code` 与 `message`；`detail` 键不存在 ⇒ `code` 为 `undefined`，
既不走业务分支也不走登录跳转，属于"静默坏掉"。

**修复**：注册 Starlette `HTTPException` 处理器（404/405），未知 `/api/**` 按 Java 规则返回 401 信封。

### F4 · 参数错误文案与 Java 不一致 · P0 · 影响 7 个用例

| 请求 | Java | Python |
|---|---|---|
| `GET /api/resource/search`（无 keyword） | `缺少必填参数：keyword` | `query.keyword: Field required` |
| `GET /api/resource/detail/abc` | `参数格式错误：id` | `path.id: Input should be a valid integer, unable to parse string as an integer` |
| `PUT /api/admin/user/status?id=3`（无 status） | `缺少必填参数：status` | `query.status: Field required` |
| `PUT /api/auth/password`（缺 newPassword） | `缺少必填参数：newPassword` | `query.newPassword: Field required` |
| `POST /api/auth/login {}` | `密码不能为空, 用户名不能为空`（顺序不稳定） | `用户名不能为空`（只报第一条） |

前端把 `message` 直接 toast，这些英文串会原样暴露给用户。

**修复**：`RequestValidationError` 处理器把 `loc` 映射成参数名，按 Java 的两种文案输出；
多字段校验错误全部收集后拼接（顺序固定为字段声明序）。

### F5 · 404 业务码不一致 · P1 · 影响 3 个用例

```
GET /api/resource/detail/999999
  Java  : {"code":500,"message":"资源不存在","data":null}
  Python: {"code":404,"message":"资源不存在","data":null}
```

HTTP 状态都是 200，文案相同，只有 `code` 不同。同现象见于 `/api/post/detail/*`、`/api/resource/download/*`。
根因：Java `BusinessException` 默认 500；Python 主动用了 404。

**决策点**：切流要求零改动 ⇒ 先对齐 Java（500），迁移完成后再评估是否统一改 404。

### F6 · `comment.user` 缺 `children` 字段 · P1 · 影响 1 个用例（10 处）

```
GET /api/comment/user
  Java  : records[0].children = null
  Python: 该键不存在
```

`/api/comment/my` 已正确输出 `children: null`，仅 `comment.user` 遗漏。
客户端 `v-for="c in item.children"` 遇 `undefined` 不会崩，但字段集合与契约不符。

### F7 · `favorite.list` 的 `fileExists` 类型不同 · P1 · 影响 1 个用例（8 处）

```
GET /api/favorite/list
  Java  : records[0].fileExists = null   （收藏列表未回填）
  Python: records[0].fileExists = true   （回填了）
```

Python 的行为更合理，但"更合理"不等于"契约一致"。建议对齐 Java（null），并记录为待改进项。

### F8 · 统计接口并列名次顺序不稳定 · P2 · 影响 1 个用例

`categoryDistribution` / `sourceDistribution` 在 `count` 相同时、`topResources` 在热度分相同时，
Java 的顺序来自 `HashMap` 迭代（`sorted` 只按 count 降序，稳定排序 ⇒ 并列顺序取决于哈希桶）。
实测并列：分类 `count=6` 四个（线性代数/面向对象/操作系统/计算机网络）、来源 `count=8` 两个、
热度分 `4500` 三条、`2800` 两条。

这不是 Python 的错，**Java 自身就不可复现**。处理办法：Python 采用稳定次序
（`count DESC, id ASC`），在测试中把该用例标记为"顺序不敏感"。

## 4. Java 侧两处不确定性（不计入 Python 缺陷）

1. **校验消息拼接顺序**：`POST /api/auth/login {}` 两次分别返回
   `密码不能为空, 用户名不能为空` 与 `用户名不能为空, 密码不能为空` —— Hibernate Validator 的违例集合无序。
   比对时按集合处理（保留内容校验，忽略顺序）。
2. **并列名次顺序**：见 F8。

这两条本身就是"契约不稳定"的证据，也说明**光读源码推不出真实契约**——必须实跑比对。

## 5. 复现方式

```bash
# 1) 准备两套同源数据库 + 起两个实例（Java 8081 / Python 8082）
#    见 D:\temp_20261114_01\golden\cycle.ps1（含 dump 恢复与健康等待）

# 2) 采集黄金基准（Java 为准）
.venv/Scripts/python.exe tools/capture_golden.py --base http://127.0.0.1:8081

# 3) 重置两库后，交错回放并出报告
.venv/Scripts/python.exe tools/diff_backends.py --java http://127.0.0.1:8081 --python http://127.0.0.1:8082

# 4) 只读契约回归（CI 用这条）
CONTRACT_BASE_URL=http://127.0.0.1:8082 .venv/Scripts/python.exe -m pytest tests/contract -q
```

要求：被测数据库处于**种子态**（`resource.detail` 会增加浏览量，重复跑若不重置会出现假差异）。

## 6. 下一步（M2 修复清单，按依赖排序）

| 顺序 | 修复 | 验收 |
|---|---|---|
| 1 | F1 时间格式 | `pytest tests/contract -q` 中 37 个与时间相关用例转绿 |
| 2 | F3 信封逃逸 + F4 参数文案 | `boundary.*`、`auth.*` 用例转绿 |
| 3 | F2 分页规范化 | `boundary.page*` 6 用例转绿（`pageSize=0` 按决策记录例外） |
| 4 | F5 + F6 + F7 字段对齐 | 对应 5 个用例转绿 |
| 5 | F8 稳定排序 + 用例标记顺序不敏感 | `stats.overview` 转绿 |

目标：只读用例 **89 / 89 全绿**，然后才能进入 M3（并发与性能）。

---

## 7. 修复结果（2026-11-17 18:50，M2 第一轮）

| 编号 | 修法 | 落点 |
|---|---|---|
| F1 | `fmt_dt` 改为 `%Y-%m-%dT%H:%M:%S` | `app/utils/common.py` |
| F2 | 新增 `page_window()`：`pageNum<=0→1`、`pageSize` 夹到 1..100、`pageSize<0→size=100 且 total=0`、`pageSize=0` 复刻 Java 的 `code=500`（带 TODO）；`page_result()` 同步夹取值 | `app/utils/paging.py`（新）、`app/core/response.py`、11 个分页 service |
| F3 | `StarletteHTTPException` 处理器（405→500 信封）+ `/api/{path:path}` 兜底路由（未知路径：无 token→401、有 token→500；方法不支持→500） | `app/core/exceptions.py`、`app/main.py` |
| F4 | `RequestValidationError` 映射为 `缺少必填参数：X` / `参数格式错误：X`；登录空字段复刻 `xxx不能为空` | `app/core/exceptions.py`、`app/api/v1/auth.py` |
| F5 | 资源/帖子"不存在"改用 `code=500`（未发布无权查看仍是 404） | `app/api/v1/resource.py`、`post.py` |
| F6 | `to_comment_vo` 增加 `children: None` | `app/services/comment_service.py` |
| F7 | 收藏列表 `fileExists` 置 `null` | `app/services/favorite_service.py` |
| F8 | 统计分布加 `ORDER BY cnt DESC, <name> ASC` 稳定次序；用例标记 `unordered` 做顺序不敏感比对 | `app/services/stats_service.py`、`tests/contract/cases.py`、`diff.py` |

复测（每次重置两库到种子态后重跑）：

| 检查 | 结果 |
|---|---|
| Python 只读契约 `pytest tests/contract -q` | **89 / 89 通过** |
| Java 自检（同一套用例回放 Java 自己） | **89 / 89 通过** |
| 全量交错对拍 `diff_backends.py`（147 用例，含全部写链路） | **147 / 147 一致，0 差异** |
| 既有探针 `_probe_smoke.py` / `_probe_admin.py` | 27/27、44/44 通过 |

⚠️ 两处**有意保留的偏差**（都已在代码注释标注）：

1. `pageSize=0`：复刻 Java 的 `code=500 系统异常`，待 Java 下线后改为 `参数格式错误：pageSize`。
2. `stats.overview` 并列名次：Java 侧不确定，Python 用稳定次序；测试按顺序不敏感比对。

新增的 `pageSize<0 → total=0` 属 MyBatis-Plus 的"负数即不限量、跳过 COUNT"语义，同样是为字节级一致而复刻。

