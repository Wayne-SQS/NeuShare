# 测试说明

## 目录

| 路径 | 作用 |
|---|---|
| `contract/cases.py` | 147 个契约用例（84 端点全覆盖 + 负例/边界/写链路），声明式、可回放 |
| `contract/replay.py` | 回放引擎：登录三种身份、执行用例、捕获派生 ID |
| `contract/normalize.py` | 响应归一化：遮蔽 token/UUID/时间戳，但保留时间戳**样式** |
| `contract/diff.py` | 字段级差异（type / missing / extra / value / length / numberType） |
| `contract/test_contract.py` | pytest 入口：只读用例对比黄金基准 |
| `contract/golden/golden.json` | 黄金基准（由 Java 参考实现采集，已提交） |
| `contract/FINDINGS.md` | M0 比对结论与缺陷清单 |
| `contract/reports/` | 每次 diff 的 Markdown/JSON 报告（生成物，已 gitignore） |

## 运行

```bash
# 只读契约回归（CI 用）
CONTRACT_BASE_URL=http://127.0.0.1:8080 .venv/Scripts/python.exe -m pytest tests/contract -q

# 需要写用例时（必须指向可丢弃的数据库）
CONTRACT_BASE_URL=http://127.0.0.1:8082 CONTRACT_ALLOW_WRITES=1 \
    .venv/Scripts/python.exe -m pytest tests/contract -q
```

前提：被测数据库处于**种子态**。`/api/resource/detail/{id}` 会自增浏览量，
不重置数据库直接重跑会产生假差异。CI 里"每次跑前重新灌种子数据"即可。

## 采集与对拍

```bash
# 从 Java 参考实现采集黄金基准
.venv/Scripts/python.exe tools/capture_golden.py --base http://127.0.0.1:8081 --label java

# Java(8081) 与 Python(8082) 交错回放，出差异报告
.venv/Scripts/python.exe tools/diff_backends.py --java http://127.0.0.1:8081 --python http://127.0.0.1:8082
```

对拍要求两个实例各连一套**从同一 dump 恢复**的数据库，否则读接口的数据本身就不同，比对无意义。

## 归一化约定（为什么字段被遮蔽）

- `token`：含签发时间，两边必然不同 → `<token>`
- 时间戳：新建行毫秒级不同 → 保留样式（`<timestamp:isoT>` / `<timestamp:space>`），样式差异算**真差异**
- 上传文件名：各自生成 UUID → `<uuid>`
- 逗号拼接的校验消息：Java 的违例集合无序，按集合比较（内容仍参与校验）
