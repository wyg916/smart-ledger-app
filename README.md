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

P1D Kimi AI Lite 已在 `main` 关闭。`p1d/rapid-product-upgrade` 正在完成其产品化升级：默认
今日首页、按日/按月统计、日期分组明细、六个常用分类、本地优先的一句话记账、Kimi 自由
对话与单图理解、匿名安全身份、离线运营事件和 DAU/WAU/MAU 查询。完整实现与门禁证据见
`docs/06_ui/`、`docs/07_ai/` 和 `docs/08_identity_analytics/`；只有分支与 main CI 均成功后，
关闭报告才会把阶段标记为 PASS。

本阶段不包含注册、云端账单、业务同步、长期记忆、Agent、RAG、任意 SQL、生产部署或正式
签名发布。语音输入保持 `VOICE_INPUT = DEFERRED`；`IOS_TOOLCHAIN = BLOCKED`，Android 已
实现的应用锁和后台预览保护不等于双端验收通过。

## 本地启动

```bash
cd apps/mobile
flutter pub get
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001

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
