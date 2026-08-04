# P1D AI 对话、智能记账与截图契约

状态：冻结用于 `P1D-RAPID-UPGRADE`  
日期：2026-08-04

## 能力与边界

AI 是可选解释和草稿层。支持自由财务对话、月度总结、预算解读、财务规划、自然语言交易解析
与单张财务相关截图理解。不得建立长期记忆、RAG、向量库、Tool Calling、Agent、任意 SQL，
不得让模型直接新增、编辑或删除账单。

服务端不保存聊天记录；客户端只维护当前短会话，发往服务端最多最近 8 轮（16 条消息），按
单条 2000 字、总 12000 字裁剪。新建会话立即清空。`reasoning_content` 永不返回或展示。

## 一句话记账

处理顺序：本地确定性解析 → 无法确定时 `POST /api/v1/ai/parse-transaction` → 待确认草稿 →
用户确认后调用现有交易 Use Case 写入 Drift。

本地至少识别收入/支出、正金额、今天/昨天/前天、`yyyy-MM-dd`/中文年月日、早餐/午餐/晚餐/
奶茶/打车/公交/地铁/购物/工资/奖金等关键词。金额通过字符串转 Int64 分，不使用浮点。
多个金额、日期歧义、分类歧义或置信度低时必须确认或补充。

AI 解析响应字段固定为：`transaction_type`、`amount_minor`、`currency_code`、
`category_candidate`、`occurred_at`、`timezone`、`note`、`confidence`、
`needs_confirmation`、`warnings`。服务端 Pydantic 与客户端再次校验金额、日期和结构；
客户端仅将候选映射到真实、启用且类型匹配的本地分类和账户。AI 不得创建分类。

## 自由对话

`POST /api/v1/ai/chat` 接收短消息列表和三个显式布尔授权：今日聚合、本月聚合、当前预算。
默认均为 false；不发送原始交易、备注、商户或账户名。响应稳定为 `title`、`answer`、
`insights`、`actions`、`warnings`、`disclaimer`，并经 JSON Schema + Pydantic 校验。

支持发送、客户端取消/停止等待、重试、新会话、快捷 Chip、加载、离线、40 秒超时、429 和
服务不可用。当前 HTTP 非流式，停止表示取消客户端请求；不自动重发。确定性聚合继续可用。

## 截图

`POST /api/v1/ai/analyze-image` 使用 multipart，单次一张 PNG/JPEG/WebP；客户端和服务端
限制 8 MiB、最大边 4096、最大 16MP。客户端重编码为 JPEG/PNG 以删除 EXIF并压缩；服务端
解码验证真实格式/尺寸后只在内存或受控临时文件处理，`finally` 立即删除，不写 PostgreSQL、
日志、Telemetry 或聊天历史。

响应包含 `summary`、`important_information`、`risk_flags`、`transaction_drafts`、
`disclaimer`。交易草稿使用严格 Schema，只能待确认；图片理解不能自动写账。

Kimi 官方当前支持 base64 `image_url`，`message.content` 必须是多段数组；本轮服务端直接将
已验证并重新编码的图片作为 data URL 提交，不使用长期文件 ID。参考：
<https://platform.kimi.com/docs/guide/use-kimi-vision-model>。

## Structured Output 与 Provider

Kimi/Fake 均通过 Provider Adapter。普通对话和截图使用可配置多模态模型，交易解析使用
可配置低延迟模型，规划使用可配置推理模型；Flutter 不知道模型名。真实调用前必须现场执行
`/v1/models`，不凭默认配置宣告可用。

解析、图片草稿和通用回答使用 `response_format=json_schema`，根对象与子对象全部
`additionalProperties=false`。模型结果经 Pydantic 二次校验；无效时最多修复一次，第二次
返回 `AI_INVALID_RESPONSE`，不以正则解析自由文本。

## 错误、生产和隐私

- 400/401/403 不重试；429/502/503/504/超时最多一次有限退避；不得无限重试。
- 统一错误覆盖格式、大小、尺寸、超时、限流、鉴权、服务不可用和无效输出。
- Production 在没有正式用户鉴权时所有生成接口 fail-closed；内部指标亦 fail-closed。
- Key 只来自服务端环境，不进入 Flutter、Git、CI、日志或响应。CI 只用 FakeProvider。
- 日志仅记录场景、模型、状态、延迟、Token 数和校验结果，不记录问题、回答、财务正文、
  图片、Key、Authorization 或内部推理。
