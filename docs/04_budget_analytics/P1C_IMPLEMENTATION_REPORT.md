# P1C 本地预算与统计分析闭环验收报告

执行日期：2026-08-03

工程结论：**PASS（已进入 main 并正式关闭）**

`IOS_TOOLCHAIN = BLOCKED`

## 分支与基线

- 分支：`p1c/local-budget-analytics`
- 起点：`1384e94577ea09b5b97f517fc9e799be514ea8a9`
- 开始前 `main` 与 `origin/main` 均为该 SHA，差异 `0/0`，工作树干净。
- 工程 HEAD：`d408157bfef19777d3de254b5ab85c522f47c647`
- 契约提交：`1f7639bd7fcdf5d92e28cc21f99b0c32b684ea4d`

## 契约与 Schema 3

`P1C_BUDGET_ANALYTICS_CONTRACT.md` 已先于代码冻结。Schema 从 2 升为 3，新增本地
`budgets` 表，使用 UUID、Int64 最小货币单位、`YYYY-MM`、币种、IANA 时区、
`total/category` 范围、启停、version、UTC 时间和 Tombstone。表同时保留数据库 V2 的
name、monthly period、本地起止日和阈值字段；P1C 不开放 custom 或多分类组合预算。

索引和约束包括：

- `(ledger_id, year_month)` 活动预算查询索引；
- 同账本同月总预算部分唯一索引；
- 同账本同月同分类预算部分唯一索引；
- 预算金额、范围、周期、月份、币种、时区组合触发器；
- 分类预算必须引用同账本、未删除、启用的支出分类；
- FK 使用 RESTRICT，打开数据库时启用 `foreign_keys`。

停用预算仍保留唯一性和历史显示；逻辑删除后才可重建同范围预算。禁用分类不能用于新
预算，既有预算仍显示分类名并参与历史计算。

## Schema 2 → 3 迁移

迁移只执行 `createTable(budgets)`，不重建或更新 P1B 五张表。文件数据库迁移测试实际将
带账户、分类、正常交易、逻辑删除交易和余额的数据库置为 `user_version=2` 且无预算表，
再由 AppDatabase 打开升级到 3。验证结果：

- 账户、分类、交易数量完全相同；
- 正常/逻辑删除交易金额、version、deleted_at 完全相同；
- 账户余额完全相同；
- budgets 正确创建且为空，无演示预算；
- `PRAGMA foreign_key_check` 为空；
- 新安装 Schema 3 及既有 Schema 1 空基线升级路径通过；
- 迁移失败不捕获后清库，不存在静默重建路径。

## 预算闭环

已完成月度总支出预算和单支出分类预算的创建、编辑、启用、停用、逻辑删除、列表、
详情、空/加载/错误状态、月份切换、进度、接近用尽和超支展示。预算使用额由 Drift 有界
观察查询实时计算：只有未删除 expense 消耗预算；income、transfer 和 Tombstone 不消耗。

剩余为 `max(amount-used, 0)`，超支为 `max(used-amount, 0)`，所有金额与状态比较使用整数；
零预算不除零。测试验证了交易新增、编辑、删除、跨月移动、分类限定和超支回退。

## 统计闭环

统计页提供月度收入、支出、净额、环比、逐日趋势、收入/支出分类排行、账户余额概览，
并共享月份、账户和分类筛选。查询只加载上月起至本月末的有界收支事实；Widget 不访问
DAO/SQL。每日分组使用账本 IANA 时区，月界为 `[当地月首 UTC, 下月月首 UTC)`。

测试覆盖 `Asia/Shanghai` 月初前/正好月初、月末最后一毫秒/正好次月，transfer 与
Tombstone 排除、禁用分类历史保留、排行并列稳定顺序、账户/分类筛选、空基期和上月为
零时不除零。账户余额沿用期初 + 收入 - 支出 - 转出 + 转入的 P1B 口径。

## Flutter 页面与依赖

新增 `features/budgets`、`features/analytics` 的 domain/data/presentation 分层及 go_router
路由；首页增加统计和预算入口。页面使用 Riverpod、Material 3 和原生轻量进度组件，未
引入云图表或分析框架。新增 `timezone 0.10.1`（BSD-3-Clause）用于离线 IANA 转换；
`sqlite3` 仅作为迁移测试的显式 dev dependency。

## 本地门禁

首次以登录 shell 执行时，`.zprofile` 的失效 Homebrew 路径导致 `flutter` 不在 PATH，命令
退出 127；使用已审计 Flutter SDK 的显式 PATH 和非登录 shell 后重跑。
`build_runner 2.15.1` 对已移除参数给出既有兼容警告，但退出 0。

| 命令 | 结果 |
|---|---|
| `flutter pub get` | exit 0 |
| `dart run build_runner build --delete-conflicting-outputs` | exit 0 |
| `dart format --set-exit-if-changed .` | 47 文件，0 变更，exit 0 |
| `flutter analyze` | No issues found，exit 0 |
| `flutter test` | 39/39 通过，0 失败，0 跳过，exit 0 |
| `flutter test --coverage` | 39/39 通过，exit 0 |
| 覆盖率 | 2,593 / 6,126 行，42.33% |
| `flutter build apk --debug` | exit 0 |

Debug APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`（Git 忽略），
187,940,313 字节，SHA-256：
`566cb783ad4bdd65205dbe8376b314bec666f7bc79cc7a6fbf71dc8e28a8b033`。

Flutter 构建仅提示 `flutter_timezone` 尚使用 Kotlin Gradle Plugin、未来 Flutter 版本需迁移
Built-in Kotlin；当前 Flutter 3.44.8 构建不受影响，列为依赖维护事项。

## Android 34 ARM64 升级验收

设备为 `sdk_gphone64_arm64`、API 34、`arm64-v8a`。使用 `adb install -r` 安装最终 APK，
没有 uninstall 或 clear；包的 `firstInstallTime=2026-08-03 15:18:11` 保持不变，仅
`lastUpdateTime` 更新。升级后 UI 直接显示 P1B 的 `P1BAccount`、`P1BExpense`、工资交易
和 100.00 收入/净额，证明 P1B 数据保留。

现场完成：

1. 创建本月总预算 500.00 和 P1BExpense 分类预算 100.00。
2. 新增支出 20.00，两预算实时已用 20.00。
3. 新增收入 50.00，预算不变；新增转账 10.00，预算不变。
4. 将支出编辑为 30.00，两预算实时已用 30.00。
5. 逻辑删除支出，两预算实时回退到 0.00。
6. 统计页显示收入 150.00、支出 0.00、净额 150.00；日趋势 08-03 收入 150.00，
   收入分类排行工资 150.00，账户余额反映 10.00 转账。
7. 切换到 2026-09，月汇总、趋势和排行显示无数据状态。
8. 强制停止并冷启动；P1B 原账单、新收入/转账和两个预算均保留。

模拟器软件渲染极慢，冷启动约 19-36 秒，`am start -W` 曾超时但 Activity 最终正常前台。
一次并发 `uiautomator dump` 的 shell 进程因重复注册 Accessibility 服务产生 FATAL；已确认
该进程不是 App。清空 logcat 后再次强制停止/冷启动，App PID 9157 前台运行，独立观察
45 秒未命中 App FATAL、ANR、SQLite、Drift 或 migration 错误。

## 后端、基础设施与安全

P1C 未修改 FastAPI、PostgreSQL、Alembic、Docker 或旧 Android。回归结果：Ruff format
10 文件通过、Ruff lint 通过、mypy 9 源文件通过、pytest 4/4 通过、Compose config 67 行
生成且 exit 0。第一次非登录 PATH 找不到 uv 退出 127，定位
已审计 uv 的显式 PATH 后完整重跑通过。

提交前检查 `.env`、本机配置、签名、数据库、APK、coverage、缓存、绝对路径、Token、
私钥、身份数据和真实账单。APK、coverage 和模拟器数据库均未加入 Git；测试与模拟器只用
既有合成 P1B 验收数据和本轮合成金额。无 force push、reset、rebase、后端业务扩展、
云同步、备份、锁、AI 或发布动作。

## CI、限制与阶段结论

Flutter workflow 已增加 `p1c/**` push 触发，并保留 pub get、build_runner、format、analyze、
test 和 Debug APK 六项强制步骤。工程 HEAD `d408157` 的 Flutter Run `30814256211` 在
4 分 59 秒内通过，六项工程步骤及 post steps 全部成功；仅有 GitHub 托管 runner 将
actions 的 Node.js 20 强制到 24 的平台弃用注释，不影响任务结论。

P1C 不代表完整 App 完成。custom/多分类组合预算、通知、目标、正式旧 DataStore 导入、
登录、同步、云端表、备份、锁、AI、正式包名/签名、iOS 构建和发布均未实现。
完整 Xcode/CocoaPods 仍未就绪，`IOS_TOOLCHAIN = BLOCKED`。

## P1C-MERGE 独立复核与主线关闭

独立复核再次确认 Schema 3、Schema 2→3 保真迁移、预算约束、整数金额、IANA 半开月界、
收入/转账/Tombstone 排除、禁用分类历史、环比空基期与确定性排行符合冻结口径；UI 不
访问 DAO 或 SQL，正常启动不 seed 预算，P1C 未修改 FastAPI、PostgreSQL、同步、AI 或旧
Android 业务。统计仓储只读取上月初至本月末的有界收支事实，随后在仓储层生成确定性
快照；该实现不会让 UI 加载无边界历史，也不改变冻结统计语义。

主线合入前复核门禁结果：Flutter 依赖解析、代码生成、47 文件格式检查（0 变更）、analyze
（0 issues）、39/39 测试、覆盖率 2,593/6,126 行（42.33%）和 Debug APK 均通过；迁移、
预算、统计与 Widget 定向测试 13/13 通过。复核 APK 为 187,940,313 字节，SHA-256 为
`a6794d8ba1ed0aacd8e2cf62232487ae2a785c0c0d8d283cda249d20b7885560`；这是本次独立重建
产物，不替换前文分支验收 APK 的历史哈希。Ruff、mypy、pytest 4/4 和 Compose config
再次通过。人工秘密/产物扫描与 main Repository Safety 均通过；本机缺少 PowerShell，
因此未在 macOS 直接执行 PowerShell 安全脚本，远端 Run 已执行同一脚本。

P1C 四个提交从 main `1384e94577ea09b5b97f517fc9e799be514ea8a9` 以 fast-forward
合入，未产生 merge commit，并以普通 push 更新 `origin/main`。最终工程 SHA 为
`ad51835d25dd66b64553184a5f050af2d34050b3`。首次两次 `git pull --ff-only` 因 GitHub
443 连接超时失败，未修改任何引用；GitHub API 确认远端 main/P1C SHA 未漂移后完成本地
fast-forward，普通 push 成功。未执行 force push、rebase、reset、squash 或 cherry-pick。

该 SHA 的 main CI：Flutter foundation Run `30816470054` success（依赖、代码生成、格式、
analyze、test、Debug APK 全部通过），Repository Safety Run `30816469579` success。FastAPI
和 Legacy Android 因本次路径过滤不适用而未触发，不写作通过。CI 无失败、无修复提交。

远端工程门禁、独立复核、主线同步与安全扫描均通过，`P1C = PASS` 并已正式关闭。P1D
尚未开始；完整 Xcode/CocoaPods、正式包名、签名、真实用户和商店资源仍未冻结，
`IOS_TOOLCHAIN = BLOCKED`。下一阶段仍必须获得用户明确授权，不得自动进入同步、备份、
安全锁、AI 或发布。
