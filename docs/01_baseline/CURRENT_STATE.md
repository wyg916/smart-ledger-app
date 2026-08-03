# 当前事实基线

更新日期：2026-08-03

## 仓库
- GitHub：`wyg916/smart-ledger-app`
- 仓库可见性：Public。
- 默认分支：`main`；开发前基线已于 2026-08-02 推送。
- 本轮本地仓库：`/Users/wyg/smart-ledger-app`（macOS）。
- 本轮旧项目来源：`/Users/wyg/记账统计`；Windows 基线位置仍保留在历史记录中。
- 本轮审计起点：`bc2c310`（`origin/main`，工作树初始干净）。

## 当前事实
- 旧项目为 Kotlin + Jetpack Compose Android 离线记账应用。
- 新目标为 Flutter Android/iOS + FastAPI + PostgreSQL。
- 旧代码放入 `legacy/android-kotlin/`，作为行为、数据和迁移基线。
- 旧项目原目录未用于新 Git 初始化，也未被重构修改。
- 已生成仓库外完整备份并记录 SHA-256，见 `PRE_REFACTOR_BACKUP.md`。
- 旧 Android 脱敏副本共 84 个文件；缓存、IDE 配置、`local.properties`、APK、ZIP、数据库、日志和需求原件未进入 `legacy`。
- 四份正式需求 Word 和四份 Markdown 事实源已进入 `docs/00_requirements/`。
- 已建立 10 组匿名 Fixture 场景规范；二进制数据库将在 P0/P2 按冻结 Schema 生成。
- 旧 APK 仅记录元数据与 SHA-256，不进入 Git，见 `LEGACY_APK_MANIFEST.md`。
- 2026-08-03 已在仓库外新增 macOS 完整备份，见 `PRE_REFACTOR_BACKUP.md`。
- 已完成 P0 静态事实审计与本机环境审计，见 `P0_AUDIT_REPORT.md`。
- 2026-08-03 已完成 P0-CLOSEOUT：JDK 17、Android SDK、adb、Gradle 8.7 Wrapper、clean、现有测试、Debug APK、哈希和 API 34 ARM64 模拟器安装启动均通过；结论为 `PASS`，见 `P0_CLOSEOUT_REPORT.md`。
- 本地 `main` 已以 fast-forward 合并 P0-CLOSEOUT，且 `origin/main` 已通过普通推送同步为 `e1573c96abda96905204fbeea045e3263309e58a`。
- GitHub CLI 身份认证已由用户完成并配置为 Git HTTPS 凭据助手；未在仓库记录 Token、Cookie 或凭据文件。
- `p1/platform-foundation` 已通过普通推送创建于远端；P1A 工程 HEAD `e77836901e32e25767c449c8512a89f789eb4244` 的 Flutter、FastAPI 与旧 Android Actions 均通过。
- 已安装 Flutter 3.44.8 / Dart 3.12.2、uv 0.12.1 / Python 3.12.13、Docker Desktop 4.84.0 / Engine 29.6.2 / Compose 5.3.1。
- Android SDK 已补齐 Platform 36、Build Tools 36.0.0、NDK 28.2 和 CMake 3.22.1；Flutter doctor 的 Android toolchain 为通过。
- `apps/mobile/` 已建立 Flutter Material 3 + Riverpod + go_router + Drift 骨架。临时开发 applicationId 为 `com.smartledger.dev.smart_ledger`，不是最终生产包名。
- Flutter format、analyze、2 个测试、debug APK 构建与 API 34 模拟器安装启动通过；旧包 `com.offline.ledger` 与新包可共存。
- `services/api/` 已建立 FastAPI + SQLAlchemy 2 + asyncpg + Alembic 骨架，Ruff、mypy 和 4 个 pytest 通过。
- PostgreSQL 16 与 API Docker Compose 容器健康，Alembic 空基础版本和三个健康/版本接口现场通过；没有创建业务表。
- 已建立 Flutter、FastAPI、旧 Android 三组 GitHub Actions 基础工作流。
- P1A 已以 fast-forward 合并并正常推送；本地 `main` 与 `origin/main` 均为
  `03b1840bf9b413d408c5d8a8ad3741d6bfdab46a`。
- P1B 已在 `p1b/core-local-ledger` 完成 Drift Schema 2 与基础本地记账闭环：账户、分类、
  收入、支出、单行转账、筛选、汇总、详情、编辑、Tombstone 删除和持久化均可用。
- P1B 使用 UUID、Int64 最小金额单位、UTC epoch ms + IANA 时区、可注入 Clock、版本递增
  和启用/禁用历史保留；正常 App 不 seed 演示交易。
- Flutter format、analyze、25/25 测试、38.23% 行覆盖率和最终 Debug APK 通过；APK 为
  187,940,313 字节，SHA-256 为
  `2e2a32b3699c5b4c85681721b70f99c1296c62cdcf3380b5bbee61f629e04baf`。
- API 34 ARM64 模拟器完成创建账户/分类、收入/支出、编辑、确认删除和冷启动持久化验证；
  最终 logcat 未命中 SQLite 加载错误、FATAL 或应用 ANR。
- P1B 工程 HEAD `8be54ec2f93f943c812de03f4ecaa8ad45a3a304` 的 Flutter Actions Run
  `30804449797` 通过；P1B 没有修改后端、基础设施或旧 Android。
- 完整 Xcode 与 CocoaPods 仍未就绪，`IOS_TOOLCHAIN = BLOCKED`；本轮未声称 iOS 构建通过。

## 待审计
- [x] macOS 旧 Android 可复现构建（JDK 17、Android SDK 34、官方 HTTPS Wrapper、clean/test/assembleDebug）
- [x] applicationId、版本与 Debug APK 元数据
- [x] Room V1 实体、DataStore Key 和已知迁移缺口初查
- [x] 13 个 Screen 与 13 个 ViewModel 初始清单
- [x] 2 个测试文件、3 个唯一测试方法；Debug/Release 共 6/6 次执行通过
- [ ] 是否存在真实用户或真实数据
- [x] 文件名、大文件和高置信秘密模式扫描；135 个候选文件在本地和 GitHub Actions 均通过，发现项仅为 `.env.example` 占位值和单元测试虚构密码
- [x] Flutter、Python、Docker、Xcode 环境已审计；Android、Python、Docker 已就绪，完整 Xcode 仍阻断
- [x] GitHub Actions `Repository Safety`、Flutter、后端和旧 Android 基础工作流已建立；本轮适用的远端运行全部通过
- [ ] 服务器域名、HTTPS、备份和端口条件

## 当前门禁

P0-CLOSEOUT 与 P1A 已同步到 `origin/main`。P1B 的本地数据契约、Drift Schema 2、
账户/分类管理、基础交易闭环、测试、Android 模拟器、回归检查和适用 GitHub Actions
均取得成功证据，阶段结论为 `P1B = PASS`。P1B 不代表真实旧库迁移、登录、同步、
预算、统计图表、AI 或发布能力完成；只有后续获得明确授权才可进入 P1C。

`IOS_TOOLCHAIN = BLOCKED`：需安装完整 Xcode、执行首次初始化并安装 CocoaPods，
在此之前不允许进入正式 iOS 构建或发布阶段。真实用户、正式签名、最终标识和商店
资源仍是迁移/发布决策的前置事实。
