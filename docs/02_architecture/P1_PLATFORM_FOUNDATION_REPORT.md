# P1A Platform Foundation 验收报告

执行日期：2026-08-03

结论：**PARTIAL**

`IOS_TOOLCHAIN = BLOCKED`

## 范围结论

Flutter Android、FastAPI、PostgreSQL 16、Alembic、Docker Compose、CI 和文档骨架
均已建立并取得本机运行证据。未实现记账、登录、预算、统计、同步、Outbox、AI、
Agent、RAG、向量数据库、正式签名或发布能力，也未修改旧 Android 工程。

P1A 未标记 PASS 的原因不是代码或本地平台门禁：本机 GitHub HTTPS 凭据不可用，
已验收 P0 无法推送到 `origin/main`，P1 分支也无法推送。完成正常非强制推送前，
不允许进入 P1B。

## 工具链

| 项目 | 现场结果 |
|---|---|
| Flutter / Dart | 3.44.8 stable / 3.12.2，Android enabled |
| Android | SDK 36、Build Tools 36.0.0、JDK 17、许可已接受 |
| Python | uv 0.12.1、CPython 3.12.13 |
| Docker | Desktop 4.84.0、Engine 29.6.2、Compose 5.3.1 |
| PostgreSQL | `postgres:16-alpine`，容器 healthy，本机端口 54329 |
| Xcode | 完整 Xcode 未安装；CocoaPods 未安装 |

`flutter doctor -v` 的 Flutter、Android 和设备检查通过；Xcode 子门禁失败。网络资源
检查访问 `https://maven.google.com/` 超时，但真实 Flutter Android 构建已现场成功。

## Flutter 验收

| 检查 | 结果 |
|---|---|
| Dart format | 9 个文件，0 变更 |
| Flutter analyze | No issues found |
| Flutter test | 2/2 通过 |
| Debug APK | 149,101,148 字节；SHA-256 `1271883bf8aeb9ea5021ab74859db89518ecab16689b2576e145be802b9e33b1` |
| applicationId | `com.smartledger.dev.smart_ledger`（临时开发标识） |
| 模拟器 | API 34 ARM64，冷启动成功，TotalTime 3110 ms |
| 共存 | 旧 `com.offline.ledger` 与新包同时安装 |
| 稳定性 | 前台 Activity 与进程存在，logcat 未命中 FATAL/ANR |

APK 位于 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`，构建目录被 Git
忽略且不会提交。完整 Xcode 未就绪，因此没有执行 iOS 构建。

## FastAPI 与数据库验收

| 检查 | 结果 |
|---|---|
| Ruff format | 10 个文件通过 |
| Ruff lint | 通过 |
| mypy strict | 9 个源文件通过 |
| pytest | 4/4 通过 |
| Compose config | 通过；API/数据库端口仅绑定本机 |
| 容器 | API 与 PostgreSQL 16 均 healthy |
| Alembic | `0001_platform_foundation (head)`；空版本，无业务表 |
| `/health/live` | 200，`status=ok` |
| `/health/ready` | 200，`status=ready`，实际检查数据库 |
| `/version` | 200，只返回服务名、版本、环境 |

Docker 首次拉取 Python 镜像时出现一次 Docker Hub token 请求超时，重试后镜像构建、
容器启动和全部联调成功。

## CI 与安全

新增 Flutter、FastAPI、旧 Android 三个 GitHub Actions 工作流；均只使用公开工具链、
开发构建和本地测试，不含正式签名、生产地址或密钥。仓库安全工作流继续保留。

`.gitignore` 覆盖环境文件、签名材料、数据库、Docker 数据、Flutter/Gradle/Python
缓存、IDE、APK/AAB、IPA 和 Xcode 构建产物。提交前扫描 239 个候选文件：禁止文件
0、大于 20 MiB 文件 0、高置信秘密模式命中 0；`git diff --check` 通过。

## Git 与阶段门禁

- 本地 `main` 已 fast-forward 到 P0 HEAD `e1573c96abda96905204fbeea045e3263309e58a`。
- `git push origin main` 失败：HTTPS 无法取得 GitHub 用户名，未产生远端写入。
- 本地 `p1/platform-foundation` 已创建；其首次推送同样因凭据缺失失败。
- 未 force push、未 reset、未删除远端分支、未创建 Release、未合并 P1 到 main。
- P1A 结论为 `PARTIAL`，当前不允许进入 P1B。
