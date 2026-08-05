# P1E2 AI 使用配额契约

状态：FROZEN  
日期：2026-08-05  
适用范围：`P1E2-METRICS-AI-QUOTA`

## 1. 套餐与权威边界

普通用户固定使用 `free` 计划：每日 2 次、每个自然周 10 次；两项同时生效，任一达到上限即
拒绝新的真实 Provider 调用。配额由 FastAPI/PostgreSQL 权威执行，Flutter 仅查询、展示和提前
禁用，不能提交 `plan_code`、覆盖计数、修改时区或绕过服务端。

`review` 与 `internal_test` 只允许服务端受控配置/脚本分配，必须具有明确的有限 daily/weekly
上限。Flutter 不包含审核账号名单、计划切换 UI 或凭据。未来套餐通过带有效期的
`ai_quota_plans` 与服务端用户 `plan_code` 扩展，不改变客户端信任边界。

## 2. 周期与时区

服务端使用 `users.timezone` 中经过 `zoneinfo` 验证的 IANA 时区。缺失为 UTC；首次登录可提交设备
IANA 时区，之后只能调用受认证的时区更新接口。时区更新有最短间隔限制，不能由每次 AI 请求
临时覆盖，且不重算或搬移已存在的 counter/usage。

- daily：用户当地 00:00（含）至次日 00:00（不含）。
- weekly：用户当地周一 00:00（含）至下周一 00:00（不含）。
- counter 保存 UTC period start/end 与使用时区快照。
- API 的 `next_daily_reset_at/next_weekly_reset_at` 均为 UTC 时间戳；Flutter 转成本地时间展示。

## 3. 计次与不计次

以下每次用户主动操作、在服务端完成预占并准备调用 Provider 时计 1 单位：

- `chat`：AI 自由对话
- `monthly_summary`：月度消费总结
- `budget_review`：预算执行解释
- `financial_plan`：财务规划建议
- `image_analysis`：截图分析
- `parse_transaction`：本地确定性解析失败后的 Kimi 辅助解析

以下不计次：本地确定性自然语言解析、本地统计、本地预算、本地记账、请求/Pydantic/图片校验
失败、AI status/quota 查询、Provider 未配置或请求尚未准备发送、同一 `request_id` 的客户端或
服务端重试。图片分析只要一次正常上游调用完成，即使没有草稿也计 1 次。

## 4. request_id、原子预占与状态机

所有计次请求必须提供稳定的 UUID `X-Request-Id`。唯一约束为 `(user_id, request_id)`；同一用户
重复请求只能返回既有 `reserved/consumed/released/blocked` 状态，不再次调用 Provider、不再次
扣费。Flutter 为一次用户动作生成一次 UUID，网络重试复用；用户再次主动点击生成新 UUID。

服务端事务顺序：

1. 验证 App Access Token 与服务端 `user_id`。
2. 读取用户 plan 和 IANA 时区，计算 daily/weekly 周期。
3. 回收该用户已超过 10 分钟 TTL 的 `reserved` 记录。
4. 幂等插入/读取 usage event。
5. 原子创建或锁定 daily、weekly counter。
6. 同时检查 `used_units + reserved_units < limit`。
7. 同一事务分别增加两个 counter 的 `reserved_units` 并创建 `reserved` usage event。
8. 提交后才调用 Provider。
9. 成功或应消费错误把两个 reserved 原子转为 used；应释放错误只减少 reserved。

实现以数据库事务、唯一约束、条件 UPDATE/行锁为准；进程内锁不得成为唯一保护，不引入 Redis。
三个并发 free 请求最多两个获得预占。超过 TTL 的预占在下一次 quota 操作或运维回收命令中释放，
不得永久占额。

## 5. 消费与释放

释放预占、不消耗：

- Provider 配置缺失且未发送请求、连接建立前失败。
- 上游明确 401/403、429 或 5xx，且没有有效输出。
- Fake Provider 明确模拟“未发生上游消费”的失败。
- 任何在预占前完成的本地参数/图片/时区校验失败。

消费 1 次：

- Provider 正常返回并通过结构校验。
- Provider 已生成，Flutter 停止等待或取消展示。
- Provider 成功但 Pydantic/业务二次校验失败。
- 上游请求已发出后读取超时，无法确认是否产生计费。
- request_id 不同的两个用户主动请求分别获准。

Structured Output 修复重试和 Kimi Adapter 的有限重试属于同一用户操作，只保留一个 reservation，
只消费 1 次。结算记录保存最终状态、模型、Token、总延迟和受控 error type；不保存正文。

## 6. API 与错误

`GET /api/v1/ai/quota` 返回：

- `plan_code`
- `daily_limit/daily_used/daily_reserved/daily_remaining`
- `weekly_limit/weekly_used/weekly_reserved/weekly_remaining`
- `next_daily_reset_at/next_weekly_reset_at`
- `user_timezone`

达到任一限制返回 HTTP 429、`error.code=AI_QUOTA_EXCEEDED`，并在响应中带同一组 daily/weekly
limit、used、remaining 和 reset UTC 时间。产品配额与 Kimi 429 严格区分：后者仍为
`AI_RATE_LIMITED`，并按释放规则结算。

重复 request_id 返回 `AI_REQUEST_ALREADY_PROCESSED` 及既有状态和最新 quota，不伪造原回答；
这是“不保存 AI 正文”前提下的原状态幂等语义。

## 7. Flutter 行为

登录后与进入 AI 页面时查询 quota；成功、quota 429 和 AI fallback 完成后刷新。页面显示
“今日剩余 X/2 次”“本周剩余 Y/10 次”和下次恢复时间。明确任一 remaining 为 0 时禁用 AI
发送/图片/生成按钮，但服务端校验仍是唯一权威。

quota 查询失败显示“无法获取AI额度”，不假设还有次数；本地记账、预算、统计和本地确定性解析
继续可用。每日/周边界到达或 App 恢复前台后重新查询。产品额度提示使用“今日AI次数已用完，
明日恢复。”或“本周AI次数已用完，下周一恢复。”；不得展示 Kimi 错误正文、Token、模型成本
或身份信息。

## 8. 数据、成本与隐私

`ai_usage_events` 只保存：内部 UUID、request_id、user/installation、feature、model、状态、
quota units、prompt/completion/total tokens、总延迟、用户时区快照、daily/weekly period、受控
error type 和时间戳。成本只以模型、Token 数和服务端受控价格配置计算。

严禁保存或写入日志/Telemetry/测试快照：用户问题、回答、完整 Prompt、`reasoning_content`、
图片/base64、原始交易、金额、账户/分类/备注、手机号、微信身份、Access/Refresh Token、Kimi Key。

