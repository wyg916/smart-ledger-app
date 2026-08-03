# P1A 项目结构

## Monorepo

```text
apps/mobile/                 Flutter Android/iOS 单代码库
services/api/                FastAPI 与 Alembic
infra/docker/                本地 PostgreSQL 16 + API Compose
packages/contracts/          后续契约事实源；P1A 不扩展业务契约
legacy/android-kotlin/       只读旧 Android 行为与数据基线
docs/                        需求、基线、架构与交付事实
.github/workflows/           安全、Flutter、API、旧 Android CI
```

## Flutter

```text
apps/mobile/lib/
├── app/                     MaterialApp 与 go_router
├── core/config/             编译期环境入口
├── data/local/              Drift 数据库连接骨架
├── features/foundation/     仅平台状态首页
└── main.dart                ProviderScope 入口
```

Android 与 iOS 平台目录均由 Flutter 生成并保留。当前只存在基础路由、基础
Riverpod Provider、Material 3 首页和无业务表的 Drift 数据库连接。Flutter 不连接
PostgreSQL。

## FastAPI

```text
services/api/
├── app/                     配置、数据库探针、路由、响应模型与应用入口
├── migrations/              Alembic 异步环境与空基础版本
├── tests/                   live/ready/version pytest
├── Dockerfile               Python 3.12 + 锁定 uv 环境
├── pyproject.toml           依赖和质量工具配置
└── uv.lock                  完整解析锁文件
```

API 只实现 `GET /health/live`、`GET /health/ready` 和 `GET /version`。P1A 不含
登录、账单、预算、同步或 AI 接口。

## 基础设施

`infra/docker/compose.yaml` 只在 `127.0.0.1` 暴露 API 与 PostgreSQL 端口，
使用明确的本地开发占位凭据和命名卷。没有 Redis、Elasticsearch 或向量数据库。
