# 环境配置

## 原则

- 仓库只提交 `.env.example`；真实 `.env`、密钥和凭据不得提交。
- 默认端口只绑定 `127.0.0.1`。
- 开发占位凭据不得复用于测试共享环境或生产环境。
- Flutter 只读取客户端环境标识，不持有 PostgreSQL DSN。
- API 配置由 Pydantic Settings 统一读取，环境变量前缀为 `SMART_LEDGER_`。

## Flutter 编译期参数

| 参数 | 默认值 | 用途 |
|---|---|---|
| `APP_ENV` | `development` | 显示并区分开发、测试、生产构建环境 |

示例：`flutter run --dart-define=APP_ENV=test`。P1A 未配置任何真实远端 API 地址。

## FastAPI

| 环境变量 | 本地示例 | 用途 |
|---|---|---|
| `SMART_LEDGER_ENVIRONMENT` | `development` | API 运行环境 |
| `SMART_LEDGER_DATABASE_URL` | 本机 PostgreSQL asyncpg DSN | 后端数据库连接；不得记录到日志 |

## Docker Compose

| 环境变量 | 默认值 | 用途 |
|---|---|---|
| `API_PORT` | `8000` | 本机 API 端口 |
| `POSTGRES_PORT` | `54329` | 本机 PostgreSQL 端口 |
| `POSTGRES_DB` | `smart_ledger_dev` | 本地开发库名 |
| `POSTGRES_USER` | `ledger_dev` | 本地开发用户 |
| `POSTGRES_PASSWORD` | `ledger_dev` | 仅本地占位密码 |

Compose 内 API 使用服务名 `postgres` 连接数据库；宿主机使用 `127.0.0.1:54329`。
部署环境必须通过独立秘密管理提供随机凭据，本文件不定义生产配置。
