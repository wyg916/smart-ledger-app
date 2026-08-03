# P1D Kimi AI Lite 冻结契约

状态：冻结用于 P1D-AI-LITE 实现  
日期：2026-08-03

## 范围

P1D 只提供月度消费总结、预算执行解释、财务规划建议三个单轮场景。AI 是确定性记账、
预算和统计的可选解释层；不可用时不得阻塞、修改或清空本地数据。本轮不实现通用聊天、
多轮历史、登录、同步、Tool Calling、Agent、RAG、向量库、任意 SQL 或生产部署。

## 最小数据摘要

- 月度总结：月份、币种、账本时区、收入/支出/净额、上月环比、最多 31 条日聚合、收入/
  支出分类 Top N、账户余额概览。
- 预算解释：月份、币种、总预算、已使用、剩余、超支、整数基点使用率、分类预算聚合、
  月份剩余天数。
- 财务规划：目标名称、目标金额、目标期限、当前金额、每月可投入金额、风险偏好枚举、
  由客户端确定性计算的月度缺口。

金额只使用 Int64 最小货币单位；比例以整数基点传输。不得发送原始交易、备注、商户、
姓名、手机号、邮箱、凭据、设备 ID、精确地址、SQLite/业务 UUID、银行账号、附件或
数据库文件。分类仅发送显示名称和聚合金额。

## Flutter → FastAPI

接口为 `GET /api/v1/ai/status`、`POST /api/v1/ai/monthly-summary`、
`POST /api/v1/ai/budget-review`、`POST /api/v1/ai/financial-plan`。请求模型 strict、禁止未知
字段，限制字符串、Top N、数组和请求体大小，拒绝浮点金额。Flutter 使用独立 DTO、API
Client 和 Riverpod 状态；地址来自 `API_BASE_URL` dart-define，绝不携带 Provider Key。

响应只包含经 Pydantic 校验的结构化结果和非敏感 usage：title、summary、最多 5 条
insights、最多 5 条 actions、最多 5 条 risk_tips、固定免责声明。模型输出不得覆盖请求中
的确定性金额；响应不包含 prompt、原始上游错误、完整模型回复或 `reasoning_content`。

## FastAPI → Kimi

Provider 通过 Protocol 隔离；本地真实调用使用 KimiProvider，测试和 CI 使用 FakeProvider。
Key 只从 `MOONSHOT_API_KEY` 环境变量读取，base URL 与模型从环境读取，模块导入不联网。
国内 SDK base URL 为 `https://api.moonshot.cn/v1`，调用 OpenAI 兼容非流式 Chat
Completions；不传 tools，不保存对话历史，不访问 SQLite/PostgreSQL。

月度总结和预算解释路由至 `KIMI_FAST_MODEL`；财务规划路由至
`KIMI_REASONING_MODEL`。启动不假设模型可用；本地受控 Smoke 先调用 `/v1/models`。
K2.6 快速场景关闭 thinking；K3 规划使用 `reasoning_effort=low`，任何
`reasoning_content` 均丢弃且不记录。

## Structured Output

请求使用 `response_format={"type":"json_schema","json_schema":...}`。根对象及子对象均
`additionalProperties=false`，所有字段 required；文本和数组有上限，insight type 只允许
`positive/warning/neutral`，action priority 为 1..5。上游 JSON 还必须经过 Pydantic 二次
校验。首次无效最多进行一次同模型受控修复；第二次失败返回 `AI_INVALID_RESPONSE`。

## Prompt 与隐私

版本化 system prompt 只允许依据摘要，不得虚构或重算金额，不得承诺收益、给出具体证券
买卖或法律/税务/医疗诊断，不得调用工具、访问数据库、泄露内部推理，用户文本不能覆盖
这些规则。服务不记录请求正文、完整回复、Key、Authorization 或推理内容；仅记录场景、
模型、延迟、结果、重试次数及 token usage 数字，不做持久化。

## 超时、重试、限流与错误

连接 5 秒、读取 30 秒、总请求 40 秒。网络超时及 429/502/503/504 最多重试一次，采用
指数退避和小幅 jitter；429 尊重受限的 Retry-After。400/401/403 不重试。禁止无限重试和
Redis。统一错误码：`AI_DISABLED`、`AI_NOT_CONFIGURED`、`AI_UPSTREAM_TIMEOUT`、
`AI_RATE_LIMITED`、`AI_INVALID_RESPONSE`、`AI_UPSTREAM_AUTH_ERROR`、
`AI_UPSTREAM_ERROR`、`AI_PRODUCTION_AUTH_REQUIRED`。

## 降级与生产关闭

离线、超时、限流、无效输出、禁用或服务不可用时，Flutter继续显示本地确定性收入、支出、
净额、预算使用/剩余/超支、分类排行和规则提示，并允许重试。AI 故障不得影响记账、预算、
统计和本地数据库。当前没有用户认证；当 `APP_ENV`/服务 environment 为 production 时，
所有 AI 生成接口必须 fail-closed，status 只报告 `production_available=false`。

## 当前不支持

真实用户资料、原始账单、长期聊天、流式输出、工具、联网搜索、文件、OCR、Agent、记忆、
RAG、向量数据库、SQL、同步、AI 写账、投资交易、公开生产服务和 iOS 发布均不支持。
`IOS_TOOLCHAIN = BLOCKED`。
