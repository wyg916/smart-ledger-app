# P1E2 用户指标与 AI 配额实现报告

状态：PASS
日期：2026-08-05  
分支：`p1e/ai-quota-user-metrics`

## 冻结范围

本轮仅交付认证 `user_id` 运营指标、多维查询、D1/D7、受保护运营页面/脚本、AI 2/日与
10/自然周服务端配额、Flutter 展示、Token/成本元数据和对应测试。业务账单仍只在用户设备；
不做云同步、iOS、Agent、RAG、长期记忆、向量数据库或任意 SQL。

## 基线

- `origin/main = 73113aca99013a5273c04a1cb9b0b9dfb2f4d256`
- `p1e/android-auth-release = origin/p1e/android-auth-release = 059201207c36801413e61a520c128562e407c9ec`
- 开始时工作树干净，P1E 分叉 `0/0`。
- P1E 整体仍为 `PARTIAL`；真实号码/微信 Provider、正式签名、生产 HTTPS 与双真机仍阻断。

## 工程提交

- `f73515c`：认证用户指标、多维查询、AI 原子配额、0004 迁移、运维导出与后端测试。
- `2bdea0d`：Flutter Schema 5、认证 Telemetry、IANA 时区、配额展示/禁用与稳定 request id。
- `1d30029`：Fake-only CI、覆盖率、迁移回环、安全扫描与开发/生产 Compose 配置。

## 用户指标闭环

- 正式 DAU/WAU/MAU、活跃用户、安装和 session 均以服务端认证 `user_id` 为主键；同用户多设备、
  多 session 不重复计用户。登录失败不计 DAU。
- Flutter 离线队列 Schema 5 在入队时冻结 `user_id/identity_scope`；登录前不伪造用户，旧 Schema 4
  数据保持 `anonymous_legacy`，默认报表不混合。
- 运营 API 提供 overview、timeseries、dimensions、retention、ai-usage、ai-quota，固定 allowlist
  支持 Provider、版本、平台、用户类型、功能、网络、模型与受控错误维度。
- `/internal/metrics` 是摘要优先的 30 天聚合页；`scripts/product_metrics_report.py` 支持 1/7/30 天、
  自定义区间以及 console/JSON/CSV。页面、API 与导出均需独立内部 Bearer 凭据。
- 原始事件默认保留 90 天、聚合 400 天，清理为显式运维任务；账号删除按契约去标识化历史事件。
- 业务账单不上传；Telemetry、运营页和导出不包含金额、账户、分类、备注、手机号、微信身份、
  AI 问题/回答、图片或 Token。

## AI 配额闭环

- 普通用户由服务端权威限制为 2 次/当地自然日、10 次/当地周一自然周；Flutter 只展示与提前
  禁用，普通用户不能切换 plan。
- 六个真实 AI 路由统一经过 `(user_id, request_id)` 幂等 usage event、daily/weekly 条件更新与
  reservation 状态机。三个并发请求最多两个获准。
- 401/403、Kimi 429、明确 5xx 在无有效输出时释放；读取超时和生成后结构化校验失败消费一次；
  内部修复重试不重复扣次，10 分钟陈旧预占可回收。
- 日/周周期按账户 IANA 时区计算。时区修改有 24 小时冷却，并把当前已用量带入新周期；有活动
  reservation 时拒绝修改，因此不能通过切换时区刷新额度。
- `ai_usage_events` 只记录状态、功能、模型、Token、延迟、时区/周期和受控错误；成本使用服务端
  价格配置计算，不保存问题、回答、Prompt、图片或财务正文。

## 本地门禁

| 范围 | 结果 |
|---|---|
| FastAPI | Ruff format/check、mypy 52 个 source files、pytest 59/59 通过 |
| Flutter | format、analyze、test 94/94 通过；LCOV 4326/9115 行，47.46% |
| Android | API 36 debug APK 191,000,972 bytes；SHA-256 `ea3887cb3802052bb1bcc815e5cc0bfc15e1e0f878cb1caaa2c414087730e9cf` |
| SQLite | 0001→0004、downgrade base、再 upgrade，foreign key check 与索引检查通过 |
| PostgreSQL 16 | 独立临时实例 upgrade/downgrade/re-upgrade 到 `0004_user_metrics_ai_quota`；14 个相关索引可见 |
| Compose | 开发/生产 config 通过；开发空卷启动自动迁移到 0004，PostgreSQL/API 均 healthy |
| 导出 | 1/7/30 天、自定义区间、console/JSON/CSV 全部通过 |

## API 36 与 PostgreSQL 验收

- 未登录不能进入账本；development APK 仅使用 FakePhone/FakeWeChat，登录后启动认证 Telemetry。
- 两次 AI 自由对话成功，UI 从 2/2 变为 0/2 并禁用第三次发送；服务端第三次与同 request id
  重试均返回产品配额 429，只留下一个 blocked 记录，Provider 不会被调用。
- App 重启后仍为 0/2、8/10；额度耗尽后本地一句话草稿、确认保存、预算页和统计页继续可用，
  本地 25 元合成记录未上传后端。
- PostgreSQL 现场模拟同周前 10 次成功、第 11 次拦截；三个并发请求只允许两个 reservation。
- 运营读数现场为 DAU 1、active users 1、sessions 2、AI 成功 2、配额拦截 2；同用户多 session
  仍只计一个 DAU。19/19 authenticated 事件均带服务端用户身份。
- App 进程与 API 日志未命中 FATAL、ANR、数据库/迁移错误、Access/Refresh Token、Provider
  Secret、手机号或微信身份。`ai_usage_events` 不存在问题、回答、content 或 image 字段。

## CI 与合并状态

功能分支工程/本地证据 HEAD `4cc758f07c8b65954c278c72693095964c01b6fb` 已普通推送，四组 CI
全部成功：

- Repository Safety：`31005929979`
- FastAPI foundation：`31005930023`
- Flutter foundation：`31005929996`
- Android release candidate compile check：`31005930029`

合并前重新 fetch 并确认 `origin/p1e/android-auth-release` 仍为授权基线
`059201207c36801413e61a520c128562e407c9ec`，功能分支与远端一致且工作树干净；随后只执行
`git merge --ff-only p1e/ai-quota-user-metrics` 和普通推送。P1E 到 `4cc758f` 后本地/远端 0/0，
合入后四组 CI 再次全部成功：

- Repository Safety：`31006458176`
- FastAPI foundation：`31006458194`
- Flutter foundation：`31006458282`
- Android release candidate compile check：`31006458180`

因此 `P1E2-METRICS-AI-QUOTA = PASS`。全程未合入或推送 `main`。

## 不变的发布结论

P1E 仍因真实号码/微信 Provider、正式签名、生产域名与部署、真实 Kimi、真机矩阵和商店资料保持
`P1E-ANDROID-AUTH-RC = PARTIAL`。本轮 Fake Provider、无签名 APK 和模拟器结果不等于 Android
正式上线，不合入 `main`，也不声称通过商店审核。
