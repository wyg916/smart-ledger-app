# 旧 Android 项目清单

基线日期：2026-08-02；复核日期：2026-08-03

本文件记录开发前准备阶段已经核实的事实。完整 P0 审计仍以 `CODEX_FIRST_PROMPT.md` 的执行结果为准。

## 工程信息
- Gradle：Wrapper 8.7；2026-08-03 已改为 Gradle 官方 HTTPS 分发地址并固定 SHA-256，macOS 现场执行成功。
- Kotlin：1.9.24。
- Android Gradle Plugin：8.4.2。
- Compose Compiler：1.5.14；Compose BOM：2024.06.00。
- compileSdk / targetSdk：34 / 34。
- applicationId：`com.offline.ledger`。
- minSdk：26。
- Java / JVM target：17。
- 主模块：`app`。
- 源码规模：63 个主 Kotlin 文件、2 个单元测试文件、13 个 Screen、13 个 ViewModel。

## 数据
- Room 数据库名称：`ledger.db`。
- Schema 版本：1，`exportSchema=false`。
- Entity：`BookEntity`、`CategoryEntity`、`TransactionEntity`。
- DAO：`BookDao`、`CategoryDao`、`TransactionDao`。
- Migration：未发现显式 Room Migration。
- 外键：交易到账本、分类均为 `ForeignKey.RESTRICT`。
- DataStore：Preferences DataStore `settings`。
- DataStore Keys：`app_lock_enabled`、`app_lock_timeout_minutes`、`app_lock_biometric_enabled`、`auto_backup_enabled`、`monthly_budget_cent`、`budget_items_json`。
- 备份格式：`.zip.enc`；`LGBK` Magic、版本 1、PBKDF2-HMAC-SHA256、AES-256-GCM；ZIP 内包含 `db.sqlite` 与 `meta.json`。
- 已确认缺口：现有备份未包含预算等 DataStore 数据；恢复流程直接替换活动数据库，缺少完整的预校验与原子回滚门禁。

## 功能页面
| 页面 | 入口 | 核心能力 | 数据来源 | 新版去向 |
|---|---|---|---|---|
| AddTransaction | 主导航/新增 | 新增收入和支出 | Room + 分类 | Flutter 记账模块 |
| Bills | 主导航 | 账单列表与筛选 | Room | Flutter 明细模块 |
| Budget | 主导航/工具 | 总预算与分类预算 | DataStore + Room | Flutter 预算模块 |
| Categories | 工具 | 分类维护 | Room | Flutter 分类模块 |
| Charts | 主导航 | 趋势与分类统计 | Room 聚合查询 | Flutter 统计模块 |
| Details | 主导航 | 月度明细与汇总 | Room | Flutter 首页/明细模块 |
| Discover | 主导航 | 发现页与财务信息 | ViewModel | V1 产品评审后决定 |
| Lock | 应用启动/返回前台 | PIN 与生物识别解锁 | DataStore + SecurePrefs | Flutter 安全入口 |
| Mine | 主导航 | 我的/设置入口 | 本地设置 | Flutter 设置模块 |
| PinSetup | 安全设置 | 设置 PIN | SecurePrefs | Flutter 安全设置 |
| Security | 设置 | 应用锁、生物识别 | DataStore + SecurePrefs | Flutter 安全设置 |
| Tools | 主导航/我的 | 备份、恢复、导出 | Room、MediaStore | Flutter 数据工具 |
| TransactionDetail | 账单详情 | 查看、修改、删除交易 | Room | Flutter 交易详情 |

## 构建与测试
| 命令 | 结果 | 证据 |
|---|---|---|
| APK `aapt dump badging` | PASS | `com.offline.ledger`，1.0.0(1)，min 26，target/compile 34 |
| 文件清单生成 | PASS | `LOCAL_FILE_INVENTORY.txt`，脱敏副本 84 个文件 |
| `test` | PASS | 2026-08-03 在 macOS/Temurin 17 重新执行；Debug 3/3、Release 3/3，0 失败、0 跳过 |
| 原工程既有测试报告 | PASS（历史证据） | 2026-02-18 生成的 XML 显示 3 个测试、0 failure、0 error；不是本轮重新执行结果 |
| macOS 本轮 `assembleDebug` | PASS | Debug APK 21,967,056 字节；SHA-256 与模拟器安装启动结果见 `P0_CLOSEOUT_REPORT.md` |

## 风险
| 风险 | 等级 | 证据 | 处理建议 |
|---|---|---|---|
| Wrapper 依赖不存在的本机绝对路径 | 已关闭 | `gradle-wrapper.properties` | 已改为官方 HTTPS 分发地址、固定 SHA-256，并在 macOS 验证 |
| 无 Room Schema 导出和 Migration | 极高 | `exportSchema=false`、未发现 Migration | 冻结 V1 Schema，补导出与迁移 Fixture |
| 备份遗漏 DataStore | 极高 | ZIP 只写入 DB 与 meta | 先定义跨平台备份 V2，再实施桥接迁移 |
| 恢复直接替换活动数据库 | 极高 | `BackupManager.restoreFromEncryptedBytes` | 临时库校验、对账、原子切换和可回滚 |
| 分类外键 RESTRICT 与删除交互冲突 | 高 | `TransactionEntity` 外键 | 新版使用禁用/逻辑删除，保留历史引用 |
| 自动化测试仅 2 个文件 | 高 | `app/src/test` | P0 建立回归矩阵，P2 补迁移和数据层测试 |
| 当前仅有 Debug APK | 高 | `LEGACY_APK_MANIFEST.md` | 重建可复现 Release、签名和商店流水线 |
| 冷启动锁屏存在异步窗口 | 极高 | `AppLockManager` 初始 `_locked=false`，随后异步读取设置 | 新版启动壳必须先进入安全门，再允许渲染财务页面 |
| 正式签名状态未知 | 极高 | Gradle 未配置 release signing，仓库扫描无签名文件 | 只在仓库外确认签名存在性、受控位置与哈希，不收集密码 |
