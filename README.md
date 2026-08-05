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

`P1E-ANDROID-AUTH-RC` 已实现 Android 强制登录、认证用户隔离、账号安全和发布候选编译链，
但真实号码/微信 Provider、正式签名、生产部署与真机仍未关闭，因此固定为 `PARTIAL`。

当前 `p1e/ai-quota-user-metrics` 正在交付 P1E2：正式 DAU 以 `user_id` 去重，anonymous legacy
只单独展示；运营 API/页面/导出提供多维指标、D1/D7、AI Token/成本与配额拦截。普通用户 AI
由服务端权威限制为 2 次/日、10 次/周，Flutter 只展示且不能绕过。业务账单仍不上传，埋点不含
财务内容或 AI 正文。实现与运维说明见 `docs/11_metrics_quota/`。

本阶段不包含云端账单、业务同步、长期记忆、Agent、RAG、任意 SQL、生产上线或正式签名发布。
语音输入保持 `VOICE_INPUT = DEFERRED`；`IOS_TOOLCHAIN = BLOCKED`，模拟器与 Fake Provider
结果不等于 Android 已正式上线。

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
