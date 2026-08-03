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

P1C Local Budget & Analytics 已在 `origin/main` 正式关闭。P1D Kimi AI Lite 也已通过
`p1d/kimi-ai-lite` 独立门禁并 fast-forward 合入 main：三类聚合 AI 场景、严格结构化输出、隐私边界、离线/超时/
429 降级、Android release 联网、温柔知性文案、22 个内置收支分类和统一暖色轻卡通主题均已
完成本地与 Android 验收。FastAPI 26/26、Flutter 52/52、真实 Kimi 三场景、Release APK、
冷启动留存和安全扫描已通过；main FastAPI Run `30834204550`、Flutter Run `30834203471`
和 Repository Safety Run `30834202262` 均成功。最终 fast-forward 状态以
`docs/05_ai/P1D_KIMI_AI_IMPLEMENTATION_REPORT.md` 为准。完整配置和隐私说明见
`docs/05_ai/KIMI_PROVIDER_CONFIGURATION.md` 与 `docs/05_ai/AI_PRIVACY_AND_DEGRADATION.md`。

P1D 不包含登录、云同步、后端业务表、备份恢复、应用锁、正式旧库迁移、通用聊天、Agent、
RAG、正式签名或发布能力。`IOS_TOOLCHAIN = BLOCKED`；正式包名、签名、真实用户和商店资源
仍未确认，不得自动进入下一阶段。

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
