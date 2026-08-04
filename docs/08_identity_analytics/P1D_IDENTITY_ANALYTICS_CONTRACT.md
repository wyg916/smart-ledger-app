# P1D 匿名身份与运营分析契约

状态：冻结用于 `P1D-RAPID-UPGRADE`  
日期：2026-08-04

## 匿名身份

- 首次启动生成 UUID v4 `installation_id` 与 `anonymous_actor_id`；存入 Android Keystore /
  iOS Keychain 兼容的安全存储，升级和重启保持，不使用 IMEI、MAC、广告 ID 或硬件标识。
- 每次前台会话生成新的 UUID v4 `session_id`；同一前台会话稳定，结束后不复用。
- 三个标识不得写日志；客户端只用于身份注册和白名单运营事件，不携带财务内容。
- 服务端注册 installation 后签发随机安装 Token；只存 Token 的 SHA-256 哈希。Token 至少
  256 bit，不复用 Kimi Key或静态字符串，并由客户端安全存储。
- 当前 UI 固定为“游客模式”。未来注册时由显式绑定流程把匿名 actor 与账号关联；注册完成
  前无法准确合并同一人的多设备，匿名 DAU 不等于账号去重自然人。

## 白名单事件

允许：`app_open`、`session_start`、`session_end`、`home_viewed`、`transaction_created`、
`transaction_edited`、`transaction_deleted`、`quick_category_used`、
`natural_language_entry_submitted`、`natural_language_entry_confirmed`、
`natural_language_entry_cancelled`、`analytics_viewed`、`budget_viewed`、`ai_chat_submitted`、
`ai_chat_success`、`ai_chat_failed`、`image_analysis_submitted`、`image_analysis_success`、
`image_analysis_failed`。

事件 properties 仅允许受控枚举/布尔/计数，如 `entry_method`、`result`、`failure_kind`、
`view_mode`；拒绝所有未知 key。金额、账户名、分类名、备注、AI 问答正文、图片、手机号、
邮箱、姓名、银行账号、精确位置和硬件标识绝不采集。

## 本地离线队列

Drift Schema 4 只新增 `analytics_event_queue`，与未来业务同步 Outbox 分离。字段为 UUID
`event_id`、白名单事件名、session、UTC 时间、schema version、受控 properties JSON、
尝试次数、下次重试时间。最多 500 条、保留 30 天；批量最多 50 条；成功删除，失败有限退避
（最多 6 次）。队列失败不影响记账、预算、统计或 AI 降级。

## 后端表与接口

Alembic 独立新增 `analytics_installations`、`analytics_sessions`、`analytics_events`、
`analytics_daily_metrics`。不新增云端账单表。

- `POST /api/v1/telemetry/installations`
- `POST /api/v1/telemetry/sessions/start`
- `POST /api/v1/telemetry/sessions/end`
- `POST /api/v1/telemetry/events/batch`
- `GET /api/v1/internal/metrics/overview`

除 installation 注册外均使用 installation Bearer Token；事件以 `event_id` 唯一幂等。内部指标
要求环境配置 Token，Production 缺失正式后台认证时 fail-closed。不得用 Kimi Key 访问。

## 指标定义

- DAU：当地统计日内产生 `session_start` 或核心功能事件的去重 `anonymous_actor_id`。
- WAU/MAU：截至目标日的 7/30 个自然日窗口内同口径去重 actor。
- 新增安装：`first_seen_at` 落入窗口的 installation 数；会话数：有效 session_start 数。
- 人均会话数：会话数 / 活跃 actor；记账用户/次数来自 `transaction_created`。
- 快捷分类使用率：`quick_category_used` 次数 / `transaction_created` 次数，分母为零返回 null。
- 自然语言确认率：confirmed / submitted；AI/图片成功率：success / submitted。
- D1/D7：安装首日 cohort 中在第 1/7 个自然日再次活跃的 actor 占比；样本未成熟时不计。

当前无注册，所有去重均为匿名 actor，不能宣称真实自然人或跨设备去重。

## 保留与删除

客户端队列 30 天；服务端原始运营事件默认 90 天，日聚合 400 天，installation/session 在
匿名身份删除请求后级联或匿名化删除。用户执行“删除匿名运营身份”时清除本地 Token、队列和
安全存储标识，并尽力请求服务端删除；网络失败需明确提示未完成，不能伪称已删除。

## 安全

事件 API 严格模型、请求体/批次上限、Token 哈希验证、常量时间比较；日志不记录 Token、
标识或 event properties。指标接口不开放公网匿名访问。`IOS_TOOLCHAIN = BLOCKED`。
