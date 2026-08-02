# P0 通过后发给 Codex 的第二条任务

基于已评审通过的 `docs/01_baseline/P0_AUDIT_REPORT.md`，执行 **P1：工程骨架与数据契约**。

范围：
1. 创建 `apps/mobile` Flutter 骨架：Riverpod、go_router、Drift、dev/staging/prod 入口、基础主题和错误状态。
2. 创建 `services/api` FastAPI 骨架：SQLAlchemy 2、Alembic、PostgreSQL、健康检查、结构化错误响应。
3. 冻结第一版 OpenAPI、错误码、金额/时间规则和同步 DTO。
4. 建立仅用于本地开发的 Docker Compose。
5. 建立 Flutter 与 Python 的格式化、静态检查、单元测试和 CI。
6. 不实现完整业务页面、AI 或生产部署。

验收：
- Flutter Android 构建，或明确环境阻断。
- FastAPI 启动且健康检查通过。
- Alembic 空库升级到最新并回退到 base。
- OpenAPI 可导出。
- CI 配置可解析。
- 结果写入 `docs/03_delivery/P1_ENGINEERING_REPORT.md`。
