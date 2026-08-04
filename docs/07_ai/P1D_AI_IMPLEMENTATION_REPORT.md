# P1D 对话、智能记账与图片实现报告

状态：本地、真实 Kimi 与 Android 门禁通过，远端门禁待完成
日期：2026-08-04

## 交付

- AI 主页面为短会话自由对话，支持发送、停止、重试、新会话、三个原能力快捷入口、提示 Chip、
  离线/超时/429/服务不可用降级和免责声明。最多发送最近 8 轮，默认不附带账本。
- 首页和记一笔页使用本地优先自然语言解析；AI 只在本地无法确定时补充，且永远形成待确认
  草稿。金额使用 Int64 分，账户/分类由 Flutter 映射到真实启用实体，模型不能直接写账。
- 单图支持 PNG/JPEG/WebP、8 MiB、16MP、最大边 4096；客户端与服务端均验证并重编码，
  删除 EXIF。服务端内存处理，不落 PostgreSQL/日志/Telemetry/长期会话。
- Kimi/Fake Provider、严格 JSON Schema、Pydantic 二次校验和最多一次修复重试覆盖 chat、
  parse-transaction、analyze-image 以及既有三个聚合场景。

## 真实 Kimi 脱敏 Smoke

2026-08-04 `/v1/models` 现场只返回 `kimi-k2.6`、`kimi-k2.7-code`；六场景均路由到
`kimi-k2.6`。月度、预算、规划、自由对话、一句话和合成截图全部 HTTP/Structured Output/
Pydantic 通过。脚本只输出场景、模型、耗时和 token 数，不输出 Key、请求、回答、图片或
推理内容。规划场景发生一次受控超时重试后成功，没有无限重试。

| 场景 | 状态 | 延迟 ms | prompt / completion / total tokens |
|---|---:|---:|---:|
| monthly_summary | 200 | 22972 | 811 / 348 / 1159 |
| budget_review | 200 | 8489 | 690 / 296 / 986 |
| financial_plan | 200 | 60992 | 693 / 422 / 1115 |
| chat | 200 | 7187 | 383 / 242 / 625 |
| parse_transaction | 200 | 3152 | 448 / 74 / 522 |
| image_analysis | 200 | 16207 | 671 / 419 / 1090 |

## Android 验收

FakeProvider 联网验收完成自由对话与图片结构化解读；图片候选交易明确显示“待确认，不会自动
保存”。自然语言草稿显示金额、收支、分类、账户、时间、备注和确认动作；取消不会新增账单，
确认后才保存。停止服务时本地记账、预算和统计继续可用。

FastAPI 31/31 测试、Ruff format/lint、Mypy 与 Alembic SQLite/PostgreSQL 迁移通过；CI 使用
FakeProvider，不配置或调用真实 Kimi。

## 非目标

没有服务端聊天持久化、长期记忆、RAG、向量库、Tool Calling、Agent、任意 SQL、自动记账、
生产匿名开放或云端账单。`VOICE_INPUT = DEFERRED`；`IOS_TOOLCHAIN = BLOCKED`。
