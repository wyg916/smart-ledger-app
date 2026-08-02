# 当前事实基线

更新日期：2026-08-02

## 仓库
- GitHub：`wyg916/smart-ledger-app`
- 仓库可见性：Public。
- 默认分支：`main`；开发前基线已于 2026-08-02 推送。
- 本地仓库：`E:\移动端开发\smart-ledger-app`
- 旧项目来源：`E:\移动端开发\记账统计`

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

## 待审计
- [ ] 全新环境构建
- [x] applicationId、版本与 Debug APK 元数据
- [x] Room V1 实体、DataStore Key 和已知迁移缺口初查
- [x] 13 个 Screen 与 13 个 ViewModel 初始清单
- [x] 测试文件数量初查；执行被本机缺少 JDK 17 阻断
- [ ] 是否存在真实用户或真实数据
- [x] 文件名、大文件和高置信秘密模式扫描；135 个候选文件在本地和 GitHub Actions 均通过，发现项仅为 `.env.example` 占位值和单元测试虚构密码
- [ ] Flutter、Python、PostgreSQL、Docker、Xcode 环境
- [x] GitHub Actions `Repository Safety` 基线工作流；Flutter、后端和旧 Android 构建工作流待 P1/P0 补充
- [ ] 服务器域名、HTTPS、备份和端口条件

## 当前门禁
首次审计完成前不进行大规模功能开发、不部署生产环境、不提交密钥和真实数据。
