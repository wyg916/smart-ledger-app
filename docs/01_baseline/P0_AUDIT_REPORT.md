# P0 项目事实审计报告

审计日期：2026-08-03
审计结论：**PARTIAL**

## 1. 结论

仓库保护、远端基线核验、旧项目脱敏归档、正式文档归档、静态源码盘点、APK/备份哈希记录、匿名 Fixture 结构检查和仓库安全扫描均已具备可追溯证据。

P0 尚不能判定为 PASS：当前 Mac 缺少 JDK、Android SDK、Flutter、Dart、Docker 与完整 Xcode，旧 Android Gradle Wrapper 还引用 Windows 本机文件，因此本轮无法在干净环境重新执行旧 Android 构建与测试。真实用户、正式签名、商店主体和发布资源也尚未获得事实结论。

## 2. 仓库与保护基线

| 项目 | 结果 |
|---|---|
| GitHub | `wyg916/smart-ledger-app`，Public |
| 分支/起点 | `main` / `bc2c310` |
| 本轮克隆 | `/Users/wyg/smart-ledger-app` |
| 旧工程 | `/Users/wyg/记账统计`，未初始化 Git、未被重构修改 |
| 旧工程备份 | `/Users/wyg/记账统计-backup-20260803.zip`，仓库外，152,840,209 字节、12,246 条目，SHA-256 已记录 |
| 旧 APK | 仓库外；SHA-256 `374772c4017a0597c8084b46b19cefe9271ddc89b263dd5668056e996a0171f1` |
| 旧代码副本 | `legacy/android-kotlin/`，排除构建产物、本机配置、数据库、APK、备份与签名材料 |

## 3. 本机环境基线

| 能力 | 现场结果 | 状态 |
|---|---|---|
| OS | macOS 26.5.2 (25F84), arm64 | 可用 |
| Git | 2.50.1 (Apple Git-155) | 可用 |
| Python | 3.10.4 | 可用，但 P1 应建立项目隔离环境并固定版本 |
| Java/JDK | `/usr/bin/java` 仅为系统启动器，报告无 Java Runtime | 阻断旧 Android 构建 |
| Android SDK | 未发现；原工程 `local.properties` 指向 `E:\\Android\\Sdk` | 阻断旧 Android 构建 |
| Gradle Wrapper | 声明 8.7，分发地址为 `file:///E:/gradle-8.7-bin.zip` | 不可复现 |
| Flutter/Dart | 未安装或不在 PATH | 阻断 P1 移动端骨架验证 |
| Docker | 未安装或不在 PATH | 阻断 P1 PostgreSQL/FastAPI 容器验证 |
| Xcode | 仅 Command Line Tools；`xcodebuild` 要求选择完整 Xcode | 阻断 iOS 构建 |
| GitHub CLI | 未安装或不在 PATH | 不阻断本地开发；发布/PR 自动化受限 |
| PowerShell | 未安装或不在 PATH | 本机不能直接运行现有安全脚本；GitHub Actions 可运行 |

附带环境问题：`~/.zprofile` 第 7 行引用不存在的 `/opt/homebrew/bin/brew`，每次登录 Shell 都会产生警告。修复前应先确认 Homebrew 的真实安装位置，避免盲目改动用户配置。

## 4. 旧 Android 事实清单

- 工程：单模块 Kotlin + Jetpack Compose，AGP 8.4.2、Kotlin 1.9.24、Java 17、compile/target SDK 34、min SDK 26。
- 应用身份：`applicationId`/namespace 为 `com.offline.ledger`，版本 `1.0.0 (1)`；仅有 Debug APK 证据。
- 源码规模：63 个主 Kotlin 文件、7,780 行；13 个 Screen、13 个 ViewModel。
- 数据：Room `ledger.db`，Schema 1，`exportSchema=false`；`books`、`categories`、`transactions` 三张实体表；无显式 Migration。
- 金额：交易金额使用 `Long amount_cent`，符合整数最小货币单位方向。
- 删除：交易使用布尔软删除；分类为物理删除且外键 `RESTRICT`，存在行为冲突。
- 设置：Preferences DataStore `settings`，包含锁设置、自动备份、总预算和预算项 JSON。
- 备份：`.zip.enc` / `LGBK` v1 / PBKDF2-HMAC-SHA256 / AES-256-GCM；压缩内容只有数据库与 `meta.json`，遗漏 DataStore。
- 恢复：写临时文件后替换数据库，但未显式关闭活动 Room 连接、未做完整性/Schema/业务对账，也没有可靠回滚门禁。
- 安全：EncryptedSharedPreferences、Android Keystore、生物识别与 PIN 已实现；锁状态初始为未锁定并异步读取设置，存在冷启动财务内容暴露风险。
- 测试：2 个测试文件、3 个 `@Test`。旧构建目录中的 2026-02-18 XML 报告为 3/3 通过；本轮未能重新执行。
- 签名：未发现 release signing 配置或签名文件。签名是否在仓库外受控保存仍未知。

## 5. 文档与数据基线

- 四份正式 Word 文档及对应 Markdown 事实源已归档在 `docs/00_requirements/`。
- 文档已生成 84 页渲染图并逐页检查；当前 LibreOffice 渲染环境缺少部分中文字体，多个页面出现中文缺字，因此只能确认页数、表格/图形与基本分页，不能据此宣称 Word 视觉版式完整通过。正文已通过 macOS `textutil` 成功提取并用于事实核对。数据库/架构文档包含横向页面，渲染器提示存在多节页面尺寸。
- 10 个匿名 Fixture 场景 JSON 均可解析；当前仅为场景规范，尚无可执行的二进制 Room 数据库。
- 旧 APK、数据库、用户备份、签名材料和真实财务数据均未纳入仓库。

## 6. 安全扫描

本轮对仓库文件名、超过 10 MiB 的文件和高置信秘密格式进行复核：未发现签名文件、数据库、本机 `local.properties`、安装包、私钥或高置信 API Token。现有 `Repository Safety` 工作流会在 `main` push 与 PR 上运行 PowerShell 扫描。

局限：模式扫描不能证明不存在低熵密码、自然语言中的隐私信息或图片/二进制元数据。正式提交真实 Fixture 前仍需人工匿名化复核。

## 7. 执行与验证结果

| 检查 | 结果 |
|---|---|
| 远端引用与历史读取 | PASS |
| 初始工作树 | PASS（干净） |
| 旧工程仓库外备份与 SHA-256 | PASS |
| 旧 APK SHA-256 与清单交叉核对 | PASS |
| 旧源码/数据/页面/安全静态审计 | PASS |
| 10 个 Fixture JSON 解析 | PASS |
| 禁止文件、高置信秘密和大文件扫描 | PASS |
| 四份 DOCX 正文提取与读取 | PASS |
| 四份 DOCX 视觉渲染检查 | PARTIAL（84 页均生成；部分中文字体缺失） |
| 旧 Android `testDebugUnitTest` 本轮执行 | BLOCKED |
| 旧 Android Debug 构建本轮执行 | BLOCKED |
| Flutter / iOS / Docker 骨架验证 | NOT STARTED（属于 P1，且环境未就绪） |

## 8. 数据库迁移状态

旧 Room Schema 仍为版本 1，未导出 Schema、未发现 Migration。新 Drift/PostgreSQL Schema 与 Alembic 尚未创建。10 个 Fixture 目前只是测试场景定义。因此数据库迁移状态为 **未实施**，不得宣称可迁移或可回滚。

## 9. 未关闭的 P0 门禁

1. 确认是否存在真实用户、是否要求覆盖升级。
2. 仅确认正式 Android 签名“是否存在、受控位置、证书哈希”；不得收集密码或提交签名文件。
3. 确认最终 Android applicationId 与 iOS Bundle ID。
4. 安装并固定 Flutter、JDK 17、Android SDK、完整 Xcode；准备至少一台 Android 和一台 iPhone 真机。
5. 将旧 Wrapper 改为可验证的 HTTPS 分发地址，随后重新执行构建与 3 个单元测试。
6. 明确 Apple Developer、Google Play、商店主体、首发地区、域名、HTTPS、短信服务和隐私政策资源。

## 10. 下一步唯一推荐动作

先执行“开发机工具链就绪与旧 Android 可复现构建”任务：固定 Flutter stable、JDK 17、Android SDK、完整 Xcode 和 Docker，修复 Wrapper 分发地址，然后在不改变旧业务行为的前提下跑通 `testDebugUnitTest` 与 Debug 构建。该门禁通过并补齐真实用户/签名结论后，再进入 P1 工程骨架与数据契约。
