# 当前事实基线

更新日期：2026-08-04

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
- P1A 已以 fast-forward 合并并正常推送；P1B 随后也已 fast-forward 合入并普通推送到
  `origin/main`，最终工程 HEAD 为 `821609117d72e6f555f761200e685c4d90074fa5`。
- P1B 已完成 Drift Schema 2 与基础本地记账闭环：账户、分类、
  收入、支出、单行转账、筛选、汇总、详情、编辑、Tombstone 删除和持久化均可用。
- P1B 使用 UUID、Int64 最小金额单位、UTC epoch ms + IANA 时区、可注入 Clock、版本递增
  和启用/禁用历史保留；正常 App 不 seed 演示交易。
- 独立复核确认金额、时间、UUID、外键、分类类型、停用历史、版本、Tombstone 和转账规则
  符合冻结契约；补充 UUID 批量唯一性定向测试后，Flutter format、analyze、26/26 测试、
  38.28% 行覆盖率和最终 Debug APK 通过；APK 为
  187,940,313 字节，SHA-256 为
  `2e2a32b3699c5b4c85681721b70f99c1296c62cdcf3380b5bbee61f629e04baf`。
- API 34 ARM64 模拟器完成创建账户/分类、收入/支出、编辑、确认删除和冷启动持久化验证；
  最终 logcat 未命中 SQLite 加载错误、FATAL 或应用 ANR。
- P1B 最终工程 HEAD `821609117d72e6f555f761200e685c4d90074fa5` 的分支 Flutter Run
  `30807188699`、main Flutter Run `30807541069` 与 main Repository Safety Run
  `30807541194` 均通过；P1B 没有修改后端、基础设施或旧 Android，P1B 已正式关闭。
- 完整 Xcode 与 CocoaPods 仍未就绪，`IOS_TOOLCHAIN = BLOCKED`；本轮未声称 iOS 构建通过。
- 用户已于 2026-08-03 明确授权 P1C；分支 `p1c/local-budget-analytics` 从 main
  `1384e94577ea09b5b97f517fc9e799be514ea8a9` 创建并普通推送。
- P1C 已冻结预算与统计契约，建立 Drift Schema 3 和真实 Schema 2→3 保真迁移；新增
  月度总预算/单分类预算、CRUD、启停、Tombstone、进度与超支，以及月度收支净额、环比、
  日趋势、收入/支出分类排行、账户余额和月份/账户/分类筛选。
- P1C Flutter format/analyze、39/39 测试、42.33% 行覆盖率和 Debug APK 通过；APK 为
  187,940,313 字节，SHA-256 为
  `566cb783ad4bdd65205dbe8376b314bec666f7bc79cc7a6fbf71dc8e28a8b033`。
- API 34 ARM64 模拟器使用 `adb install -r` 从既有 P1B 数据升级：P1B 账户、分类和交易
  保留；总/分类预算及支出、收入、转账、编辑、删除、统计、空月份和冷启动持久化交互通过；
  最终 App 观察未命中 FATAL、ANR、SQLite 或 migration 错误。
- P1C 未修改 FastAPI、PostgreSQL、Docker 业务或旧 Android；Ruff、mypy、pytest 4/4 和
  Compose config 回归通过。工程 HEAD `d408157bfef19777d3de254b5ab85c522f47c647`
  的 Flutter Run `30814256211` 已通过。
- P1C-MERGE 独立复核确认 Schema 2→3 不重建或清空 P1B 数据，预算唯一性、Int64 金额、
  IANA 半开月界、收入/转账/Tombstone 排除、禁用分类历史、环比和确定性排行符合冻结
  口径；Flutter format/analyze、39/39 测试、42.33% 覆盖率、Debug APK、13/13 定向测试、
  FastAPI 4/4 和 Compose config 均再次通过，安全扫描未发现提交秘密或构建产物。
- P1C 已从 `1384e94577ea09b5b97f517fc9e799be514ea8a9` 以 fast-forward 合入 main 并普通
  推送；`origin/main` 的 P1C 最终工程 SHA 为
  `ad51835d25dd66b64553184a5f050af2d34050b3`。main Flutter Run `30816470054` 与
  Repository Safety Run `30816469579` 均在该 SHA 通过；FastAPI 和 Legacy Android 因
  路径过滤不适用、未触发。P1C 已正式关闭；随后用户已授权 P1D，见下文。
- 用户已明确授权 P1D-AI-LITE；分支 `p1d/kimi-ai-lite` 从 main
  `c8c656be20a4322cca94c70451f0798099b926f0` 创建。已实现月度总结、预算解释、财务规划
  三个聚合 AI 场景，Kimi/Fake Provider、严格 JSON Schema + Pydantic、一次修复/重试、
  生产 fail-closed、隐私日志和 Flutter 离线/超时/429/无效输出降级。
- 受控模型清单仅返回 `kimi-k2.6`、`kimi-k2.7-code`；K3 不可用，三场景使用
  `kimi-k2.6` 且关闭 thinking。真实 Kimi 三场景结构化/Pydantic 验证通过，未输出提示词、
  回答正文、Key 或内部推理。
- 用户追加的 P1D 体验范围已落地：AI 文案温柔知性、甜美但克制且不淡化风险；默认分类
  扩至 14 个支出和 8 个收入；Flutter 使用奶油黄/珊瑚/薄荷色 Material 3 主题和原创零钱
  精灵；13 个当前路由页面已有 4 张成套 UI 参考板。
- P1D 本地门禁：FastAPI 26/26、Flutter 52/52、行覆盖率最近 45.20%、Release APK
  61,480,250 字节，SHA-256
  `7ad3552fc42029d5c0131a254682001e343b52698b0771e8b0ab42405b03fa9e`。Android 34
  ARM64 使用 `adb install -r` 保留合成收入 100.00 与预算 500.00；真实 AI、无服务、429、
  40 秒超时、冷启动、22 分类均通过，logcat 未命中 FATAL、ANR、SQLite/migration 或 Key。
- P1D 分支 FastAPI Run `30833339810`、Flutter Run `30833339698`、最终文档头 Repository
  Safety Run `30833534342` 均通过。`origin/main` 未分叉，已从 `c8c656b` 使用
  `git merge --ff-only` 合入 P1D 工程 SHA `db8a1f78c417bbfa3f8346d0464052fa3d8b2b50` 并
  普通推送；main FastAPI Run `30834204550`、Flutter Run `30834203471`、Repository
  Safety Run `30834202262` 全部通过。P1D 已正式关闭。
- 用户于 2026-08-04 授权 `P1D-RAPID-UPGRADE`；分支 `p1d/rapid-product-upgrade` 从用户确认的
  `main` 基线 `ad46a0ca723bff41a2a5114cd32efc5506687e75` 创建。三份范围契约已先行冻结。
- 本轮已实现产品化五项底栏、默认今日首页、日期分组明细、统计日/月视图、90 天六分类、
  本地优先自然语言草稿、Kimi 自由对话/单图、匿名安全身份、Drift Schema 4 离线事件队列、
  analytics 四表与指标接口、游客/应用锁及 Android 后台预览保护。
- 当前本地门禁为 Flutter 68/68、行覆盖率 47.17%、FastAPI 31/31、Flutter analyze、Ruff、
  Mypy、Alembic SQLite/PostgreSQL 和 Android Debug/Release 构建通过。真实 Kimi 现场模型为
  `kimi-k2.6` 与
  `kimi-k2.7-code`，六个合成场景均通过 Structured Output 和 Pydantic。
- Android 34 `adb install -r` 保留既有收入 100.00 和确认后支出 25.00；日/月统计、对话、
  图片待确认、匿名指标、冷启动、游客/安全页和空白最近任务预览通过。
- `P1D-RAPID-UPGRADE` 工程提交为 `1936d5123d64ca64d27e74155075dfe22606b6d3`。
  功能分支 Flutter Run `30908130415`、FastAPI Run `30908129729`、Repository Safety Run
  `30908128026` 全部成功；确认远端 main 仍为授权基线 `ad46a0ca723bff41a2a5114cd32efc5506687e75`
  后，以 `git merge --ff-only` 合入并普通推送。main Flutter Run `30908806675`、FastAPI Run
  `30908807065`、Repository Safety Run `30908806639` 全部成功，阶段正式关闭为 PASS。

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

P0-CLOSEOUT、P1A、P1B、P1C 与 P1D 已同步到 `origin/main` 并正式关闭。P1D 本地实现、
真实 Kimi、Android release、分支 CI、fast-forward 合入和 main CI 均已通过，阶段结论为
`P1D = PASS`。P1D 不代表真实旧库迁移、登录、同步、后端业务表、备份、
应用锁、通用聊天、Agent、RAG 或发布能力完成；不得自动进入下一阶段。

`P1D-RAPID-UPGRADE` 的本地、真实 Kimi、Android、功能分支 CI、fast-forward 合入和 main
CI 均已通过，阶段结论为 `P1D-RAPID-UPGRADE = PASS`。这不代表注册、云端账单、多设备同步、
长期记忆、Agent、RAG、生产部署、正式签名或 iOS 发布能力已经完成。

`IOS_TOOLCHAIN = BLOCKED`：需安装完整 Xcode、执行首次初始化并安装 CocoaPods，
在此之前不允许进入正式 iOS 构建或发布阶段。真实用户、正式签名、最终标识和商店
资源仍是迁移/发布决策的前置事实。
