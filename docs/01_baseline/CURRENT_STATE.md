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
- 已完成 P0 静态事实审计与本机环境审计，见 `P0_AUDIT_REPORT.md`；结论为 `PARTIAL`。

## 待审计
- [ ] 全新环境构建（本机缺少 JDK、Android SDK，且旧 Wrapper 为 Windows 绝对路径）
- [x] applicationId、版本与 Debug APK 元数据
- [x] Room V1 实体、DataStore Key 和已知迁移缺口初查
- [x] 13 个 Screen 与 13 个 ViewModel 初始清单
- [x] 测试文件数量初查；执行被本机缺少 JDK 17 阻断
- [ ] 是否存在真实用户或真实数据
- [x] 文件名、大文件和高置信秘密模式扫描；135 个候选文件在本地和 GitHub Actions 均通过，发现项仅为 `.env.example` 占位值和单元测试虚构密码
- [x] Flutter、Python、Docker、Xcode 环境已审计；Flutter/Dart/Docker/完整 Xcode 当前不可用
- [x] GitHub Actions `Repository Safety` 基线工作流；Flutter、后端和旧 Android 构建工作流待 P1/P0 补充
- [ ] 服务器域名、HTTPS、备份和端口条件

## 当前门禁
P0 静态审计已完成，但构建与发布环境门禁未关闭。安装并固定 Flutter、JDK 17、Android SDK 和完整 Xcode，修复旧 Wrapper 后，重新执行旧 Android 构建与 3 个单元测试；在此之前不进入大规模功能开发或生产部署。
