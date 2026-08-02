# Smart Ledger App — Codex 工作约束

## 产品目标
本仓库用于开发可在 Android 与 iOS 安装、测试和发布的智能记账 App。
优先级：记账核心、本地离线与数据安全、可选云同步、统计预算、轻量 AI 问答与规划。
AI 不是产品主体；不建设多 Agent、长期记忆、RAG、向量数据库或任意 SQL 生成能力。

## 冻结技术方向
- 移动端：Flutter、Dart、Riverpod、Drift/SQLite、go_router。
- 后端：FastAPI、SQLAlchemy 2、Alembic、PostgreSQL。
- 通信：HTTPS JSON API；App 不得直接连接 PostgreSQL。
- 同步：本地优先、UUID、Outbox、Push/Pull、Cursor、幂等写入、逻辑删除。
- AI：后端通过固定统计查询生成最小必要数据摘要，再调用模型 API。
- 首版不强制引入 Redis、Celery、RAG、向量库或本地大模型。

## 数据与安全硬约束
- 金额统一使用 64 位整数最小货币单位，禁止浮点金额。
- 所有业务实体使用 UUID；时间保存 UTC 与原始时区。
- 无账号、无网络、后端不可用时仍能完成核心记账。
- 云同步失败不得阻塞本地记账。
- 删除通过 deleted_at 传播，待同步完成后再清理。
- 不得提交 .env、密钥、密码、Token、证书、签名文件、真实数据库、真实账单或敏感日志。
- Keystore、Keychain、PIN、生物识别状态不得进入业务备份。
- AI 不得直接访问数据库，不得执行模型生成的任意 SQL。

## 仓库边界
- `legacy/android-kotlin/`：旧 Android 项目事实基线，默认只读。
- `apps/mobile/`：Flutter 客户端。
- `services/api/`：FastAPI 后端。
- `packages/contracts/`：OpenAPI、DTO、错误码和同步协议。
- `infra/`：Docker、反向代理、部署和备份脚本。
- `docs/`：需求、架构、决策、验收和运维文档。
- `tests/fixtures/`：匿名化迁移与同步测试数据。

不得把新 Flutter 或后端代码写入旧 Android 项目目录。

## Codex 执行规则
每个任务必须：
1. 先阅读 README、AGENTS.md、相关 docs 和测试。
2. 先输出事实、影响范围、实施计划和风险，再修改代码。
3. 只改当前任务需要的文件，不顺手大规模重构。
4. 不覆盖用户已有修改；新增或修改行为必须补测试。
5. 执行格式化、静态检查、单元测试和相关集成测试。
6. 环境阻塞时记录准确命令、错误、未完成项和解除条件。
7. 不伪造测试、部署、商店审核或生产运行结果。
8. 未经明确授权，不得 push、建 PR、部署、切流或使用真实密钥。

## 交付格式
- 结论：PASS / PARTIAL / FAIL。
- 变更文件清单。
- 执行命令与测试结果。
- 数据库迁移状态。
- 未解决风险和阻断。
- 下一步唯一推荐动作。
