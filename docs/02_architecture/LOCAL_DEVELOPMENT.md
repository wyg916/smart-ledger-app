# 本地开发

## 前置工具

- Flutter 3.44.8 stable / Dart 3.12.2
- JDK 17
- Android SDK Platform 36 / Build Tools 36.0.0
- uv 0.12.1 / Python 3.12
- Docker Desktop 4.84.0 或兼容的 Docker Engine + Compose

工具应安装在仓库外。不要提交本机绝对路径、SDK 配置或 `local.properties`。

## Flutter

```bash
cd apps/mobile
flutter pub get
dart run build_runner build
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8001
flutter run --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://10.0.2.2:8001
```

SQLite 使用 `package:sqlite3` 官方支持的系统库 hook 模式，避免构建时依赖外部
预编译资产下载。Drift smoke test 使用内存库且不创建业务表。

临时 Android applicationId 是 `com.smartledger.dev.smart_ledger`。它只用于开发
验收，不是已冻结的生产包名，也不应用于正式签名或商店提交。

## FastAPI

```bash
cd services/api
cp .env.example .env
uv sync --frozen
uv run ruff format --check .
uv run ruff check .
uv run mypy .
uv run pytest
uv run uvicorn app.main:app --reload --port 8001
```

`.env` 只供本地使用且已被 Git 忽略。日志和健康接口不得输出数据库 DSN。
Kimi Key 只保存于该文件或秘密存储，Flutter 不持有 Key。真实 smoke 默认禁用；配置和
命令见 `docs/05_ai/KIMI_PROVIDER_CONFIGURATION.md`。

## Docker Compose 与数据库

```bash
docker compose -f infra/docker/compose.yaml config
docker compose -f infra/docker/compose.yaml up -d --build
docker compose -f infra/docker/compose.yaml ps
docker compose -f infra/docker/compose.yaml exec api uv run alembic upgrade head
docker compose -f infra/docker/compose.yaml exec api uv run alembic current
curl http://127.0.0.1:8000/health/live
curl http://127.0.0.1:8000/health/ready
curl http://127.0.0.1:8000/version
docker compose -f infra/docker/compose.yaml down
```

默认 PostgreSQL 端口为本机 `54329`，API 为本机 `8000`。默认值都是开发占位值，
不能复用于部署环境。P1A Alembic 基础版本只记录版本，不建立正式业务表。

## iOS 阻断

当前仅有 Command Line Tools，完整 Xcode 与 CocoaPods 不可用。最小人工步骤：

1. 从 App Store 或 Apple Developer 下载并安装完整 Xcode。
2. 执行 `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`。
3. 执行 `sudo xcodebuild -runFirstLaunch` 并接受所需系统许可。
4. 安装 CocoaPods 后重新运行 `flutter doctor -v`。

完成前不得声称 iOS 构建通过，也不得开始正式 iOS 发布工作。
