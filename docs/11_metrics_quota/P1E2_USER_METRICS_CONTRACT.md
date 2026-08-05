# P1E2 认证用户运营指标契约

状态：FROZEN  
日期：2026-08-05  
适用范围：`P1E2-METRICS-AI-QUOTA`

## 1. 身份与活跃口径

正式运营统计主键是内部 UUID `user_id`。手机号、微信 `openid/unionid`、Provider subject、
审核账号用户名和设备硬件标识都不得作为统计主键或维度值。

- `installation_id` 表示一次安全存储中的安装身份；一个用户可以映射多个 installation。
- `session_id` 表示一次前台会话；一个 installation 可以产生多个 session。
- 登录成功后，服务端把 installation 显式映射到认证 `user_id`。服务端只接受与该映射一致的
  authenticated 事件；客户端提交的 `user_id` 不能覆盖服务端身份。
- 同一用户同日使用两台设备、三个会话：active users 为 1，active installations 为 2，
  sessions 为 3。

正式 DAU 是用户所属 IANA 自然日内，至少发生一次成功登录后的 `session_start`、登录成功事件
或核心功能事件的去重 `user_id` 数。WAU/MAU 分别是查询日（含）向前 7/30 个用户自然日内按
同一口径去重的 `user_id` 数。登录页展示、登录失败或取消、Provider 配置失败不计正式活跃。

计入认证活跃的核心事件：

- `session_start`
- `phone_login_succeeded`、`wechat_login_succeeded`、`review_login_succeeded`
- `transaction_created`、`transaction_edited`、`transaction_deleted`
- `quick_category_used`、`natural_language_entry_confirmed`
- `analytics_viewed`、`budget_viewed`
- `ai_chat_submitted`、`ai_chat_success`
- `image_analysis_submitted`、`image_analysis_success`

## 2. 登录前、登录后与旧匿名数据

登录前事件只能使用 `identity_scope=pre_auth`，必须没有 `user_id`，且只能是：

- `login_page_viewed`
- `phone_login_started`、`phone_login_cancelled`、`phone_login_failed`
- `wechat_login_started`、`wechat_login_cancelled`、`wechat_login_failed`

登录成功、退出和删除流程事件可在状态切换边界记录：
`phone_login_succeeded`、`wechat_login_succeeded`、`review_login_succeeded`、
`logout_completed`、`account_deletion_started`、`account_deletion_completed`。成功后事件必须与
服务端认证用户一致；删除完成后不得继续形成 authenticated 事件。

迁移前 P1D 的 `anonymous_actor_id`、installation、session 和 event 原样保留，并显式标记
`identity_scope=anonymous_legacy`。不得推测、回填或通过 installation 猜测绑定旧 actor。正式
报表默认只查询 `authenticated`；legacy anonymous 只能通过显式 scope 单独查看，不能与
`user_id` 混合去重。`anonymous_actor_id` 为兼容旧数据保留，不是正式用户指标。

## 3. 日期、时区与留存

- 原始时间统一存 UTC；认证事件同时冻结服务端账户 IANA 时区和据此计算的 local event date。
- 日、周、月运营口径使用事件发生时冻结的用户时区，不随以后时区修改重算历史。
- anonymous legacy 仅使用 UTC 日，报表必须标注该限制。
- D1/D7：以用户首次成功注册/创建的当地日期为 cohort day 0；同一 `user_id` 在第 1/7 个当地
  自然日再次产生认证活跃事件即留存。cohort 尚未成熟时返回 `null`，不得显示成 0%。
- 多 Provider 或多设备只按同一内部 `user_id` 去重；不以手机号、微信身份或 installation 合并。

## 4. 事件与漏斗

除上述登录事件与核心活跃事件外，允许：

- `app_open`、`session_end`、`home_viewed`
- `natural_language_entry_submitted`、`natural_language_entry_cancelled`
- `ai_chat_failed`、`image_analysis_failed`
- `monthly_summary_submitted/success/failed`
- `budget_review_submitted/success/failed`
- `financial_plan_submitted/success/failed`
- `ai_parse_transaction_submitted/success/failed`

漏斗定义：

- 注册/登录：started → succeeded/failed/cancelled，按 Provider 分组。
- 记账：`transaction_created`；快捷分类率为 quick category / created。
- 一句话记账：submitted → confirmed/cancelled；确认率为 confirmed / submitted。
- 预算、统计：对应页面 authenticated unique users 与事件数。
- AI：submitted → success/failed；AI usage 权威调用/Token/配额数据来自 `ai_usage_events`。

事件属性仅允许受控标量：`entry_method`、`result`、`failure_kind`、`view_mode`、
`message_count`、`has_image`、`feature`、`network_type`。`network_type` 只能是
`wifi/mobile/offline/unknown`；所有值有长度和枚举约束，未知 key 拒绝。

## 5. 多维筛选

受保护 metrics API 支持日期范围，并只允许以下维度：

- `platform`、`android_version`、`app_version`、`application_id`
- `auth_provider`：`phone_one_click/wechat/play_review/unknown`
- `user_type`：`new/returning`
- `release_channel`
- `feature`、`ai_feature`、`ai_status`、`error_type`
- `network_type`：`wifi/mobile/offline/unknown`
- `identity_scope`：默认 `authenticated`，可显式选 `anonymous_legacy`

返回同时保留 active users、active installations、sessions，并提供活跃频次、功能排行、登录
Provider 与 App 版本分布。筛选字段必须走固定 allowlist；不得接受任意 SQL、任意列名或自由 JSON
查询。

## 6. 严禁采集与展示

Telemetry、维度、日志、报表和运营页面均不得包含：金额、账户名、分类名、交易备注、商户、
完整手机号、微信 `openid/unionid`、Provider subject、AI 问题/回答/Prompt、图片或 base64、
`reasoning_content`、精确位置、银行/卡号信息、Access/Refresh Token、Provider Secret。

服务端对事件名、属性名、属性值、批量大小、UUID 和身份关系做严格校验。运营页面只显示聚合值；
高用量用户默认只返回数量，必要的排障 ID 也只能是内部 UUID。

## 7. 保留、删除与授权

- Flutter 离线队列：最多 500 条、30 天、每批最多 50、有限退避；失败不阻塞本地记账。
- 服务端原始 analytics events：默认 90 天；session/installation 按账号删除契约解除映射或删除。
- 日/周/月聚合：默认 400 天；超期清理必须是显式运维任务并记录结果。
- 账号删除解除 `user_id` 映射，历史数据只按去标识化 scope 保留，不得保留 Provider 身份。

`/api/v1/internal/metrics/**` 与 `/internal/metrics` 只接受 `Authorization: Bearer` 中的独立内部
metrics 凭据；永久密钥不得放 URL。无凭据、错误凭据一律 401。Production 缺少内部凭据时应用
启动失败关闭，接口绝不匿名降级；Kimi Key、App Access Token 与审核账号均不能充当 metrics 凭据。

