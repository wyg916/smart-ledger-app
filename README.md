# Smart Ledger App

Android / iOS 双端智能记账应用。

## 产品定位
以记账为核心，支持纯本地模式、登录后的云端增量同步、统计预算、财务目标，以及轻量 AI 财务问答和规划建议。

不建设复杂 Agent、长期记忆、RAG 或向量数据库。

## 目录
```text
apps/mobile/                 Flutter 客户端
services/api/               FastAPI 后端
packages/contracts/         OpenAPI、DTO、错误码、同步协议
legacy/android-kotlin/      旧 Android 项目事实基线
docs/                       产品、架构、决策、验收和运维资料
infra/                      Docker、部署、反向代理、备份脚本
scripts/                    本地开发与验收脚本
tests/fixtures/             匿名化测试数据
.github/workflows/          CI
```

## 当前阶段

P1C Local Budget & Analytics 已在 `p1c/local-budget-analytics` 完成本地预算与确定性统计
闭环：Drift Schema 3、Schema 2→3 保真迁移、月度总预算/单分类预算、预算 CRUD/启停/
Tombstone、使用额与超支、月度收支净额/环比、日趋势、分类排行、账户余额和三类筛选。
Flutter 本地 39/39 测试、42.33% 行覆盖率、Debug APK、Android 34 ARM64 保留 P1B 数据
升级交互以及 FastAPI/Compose 回归均通过；`IOS_TOOLCHAIN = BLOCKED`。完整事实见
`docs/01_baseline/CURRENT_STATE.md`、`docs/04_budget_analytics/P1C_BUDGET_ANALYTICS_CONTRACT.md`
和 `docs/04_budget_analytics/P1C_IMPLEMENTATION_REPORT.md`。

P1C 不包含登录、云同步、后端业务表、备份恢复、应用锁、目标、AI、正式旧库迁移、正式
签名或发布能力。正式包名、签名、真实用户和商店资源仍未确认；不得自动进入下一阶段。

## 本地启动

```bash
cd apps/mobile
flutter pub get
flutter test
flutter run

cd services/api
uv sync --frozen
uv run pytest

docker compose -f infra/docker/compose.yaml up -d --build
```

详细环境变量和命令见 `docs/02_architecture/LOCAL_DEVELOPMENT.md`。

## 必读
1. `AGENTS.md`
2. `docs/00_requirements/`
3. `docs/01_baseline/CURRENT_STATE.md`
4. `docs/02_architecture/DECISIONS.md`
5. `docs/02_architecture/LOCAL_DEVELOPMENT.md`
6. `docs/03_delivery/ACCEPTANCE_CRITERIA.md`

## 机密信息
不得提交密码、Token、密钥、证书、签名文件、真实数据库或真实用户财务数据。
