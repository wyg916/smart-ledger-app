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
开发前基线准备。正式状态以 `docs/01_baseline/CURRENT_STATE.md` 为准。

## 必读
1. `AGENTS.md`
2. `docs/00_requirements/`
3. `docs/01_baseline/CURRENT_STATE.md`
4. `docs/02_architecture/DECISIONS.md`
5. `docs/03_delivery/ACCEPTANCE_CRITERIA.md`

## 机密信息
不得提交密码、Token、密钥、证书、签名文件、真实数据库或真实用户财务数据。
