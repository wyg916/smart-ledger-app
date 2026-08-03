# P1B 核心本地记账闭环验收报告

执行日期：2026-08-03

结论：**PASS**

`IOS_TOOLCHAIN = BLOCKED`

## 范围结论

P1B 已按冻结契约完成账户、分类、收入、支出、单行转账、列表、筛选、月度汇总、
详情、编辑、逻辑删除和本地持久化。实现只使用本地 Drift / SQLite，不包含登录、
云同步、Outbox 执行、预算、目标、附件、AI、正式迁移、正式签名或发布能力。

旧 Android 目录没有修改。10 组匿名 Fixture 均能解析且有显式 P1B 决策；其中 4 组
接受，6 组因超出 P1B 范围而明确拒绝。正常 App 启动不会读取 Fixture 或 seed 演示账单。

## 数据库与领域模型

Drift Schema 版本为 2，包含 `ledgers`、`accounts`、`categories`、`transactions` 和
`app_settings`。P1A 的空 Schema 1 可升级到 Schema 2；外键在打开数据库时启用，
交易、账户、分类的常用查询索引和交易字段组合校验触发器已建立。

- 新业务实体使用 UUID；默认账本、默认账户和内置分类使用固定 UUID，以保证初始化
  幂等。
- 金额只使用 Int64 最小单位，十进制输入通过字符串和整数解析，不使用浮点计算。
- 时间保存为 UTC epoch ms，同时保存发生时的 IANA 时区 ID；Clock 和时区服务可注入。
- 交易创建版本为 1，编辑和逻辑删除递增版本；删除写 Tombstone，默认查询与汇总排除。
- 账户和分类只提供启用/禁用；被禁用记录不能用于新交易，历史交易仍可读取名称。
- 转账使用单行来源/目标账户表达，影响双方余额但不计入收入、支出或净额。
- 账户余额按期初、收支和转入转出实时计算，不保存派生余额列。

## Flutter 本地验收

| 检查 | 结果 |
|---|---|
| `flutter pub get` | 通过 |
| Drift 代码生成 | 通过；32 个输出 |
| Dart format | 33 个文件，0 变更 |
| Flutter analyze | No issues found |
| Flutter test | 25/25 通过 |
| Flutter coverage | 1,709 / 4,470 行，38.23% |
| Debug APK | 187,940,313 字节 |
| APK SHA-256 | `2e2a32b3699c5b4c85681721b70f99c1296c62cdcf3380b5bbee61f629e04baf` |

APK 位于 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`，构建目录由 Git 忽略。
`build_runner 2.15.1` 会提示 `--delete-conflicting-outputs` 已移除并忽略，但代码生成退出码
为 0、生成内容稳定，CI 使用与本地相同命令。

首次 Android 安装暴露 `source: system` 会在 Android 34 查找不存在的
`libsqlite3.so`。已移除该覆盖，让 `sqlite3 3.x` 的 Build Hook 按默认行为随 APK
打包 SQLite；重建、重装和后续完整交互通过。这是 P1B 范围内的最小运行时修复。

## Android 模拟器验收

在既有 API 34 ARM64 模拟器安装最终 APK，最终构建首次冷启动成功，启动耗时 3,167 ms。
现场通过真实界面完成：

1. 创建账户 `P1BAccount` 和支出分类 `P1BExpense`。
2. 在该账户和分类下创建支出 12.34，并在该账户创建收入 100.00。
3. 核对列表与汇总为收入 100.00、支出 12.34、净额 87.66。
4. 将支出编辑为 20.00，详情版本从 1 递增到 2。
5. 经确认弹窗逻辑删除该支出，汇总更新为收入 100.00、支出 0.00、净额 100.00。
6. 强制停止并重新启动 App；收入、汇总、账户、分类和账户余额 100.00 均保留。

最终进程前台 Activity 正常，logcat 未命中 SQLite 加载错误、FATAL EXCEPTION 或应用 ANR。
模拟器软件渲染较慢，持久化验证的 `am start -W` 等待状态曾超时，但 Activity 随后正常
恢复且 UI 与数据检查全部通过；该性能现象不影响功能结论。

## 后端、基础设施与安全回归

P1B 未修改 FastAPI、PostgreSQL、Alembic 或 Docker 业务状态。回归结果：Ruff format
10 个文件通过、Ruff lint 通过、mypy strict 9 个源文件通过、pytest 4/4 通过，
Docker Compose 配置校验通过。

关闭前执行格式差异、安全模式、禁止产物和旧 Android 差异检查；未提交真实财务数据、
数据库、APK、环境文件、Token、Cookie、签名材料或构建缓存。没有 force push、rebase、
reset、clean、PR、Release、远端删除或对 `main` 的 P1B 合并。

## CI 与 Git 门禁

Flutter 工作流已补充 Drift 代码生成步骤和 `p1b/**` 分支触发条件。P1B 工程 HEAD
`8be54ec2f93f943c812de03f4ecaa8ad45a3a304` 的 Flutter format、analyze、25 个测试与
无签名 Debug APK 在 GitHub Actions Run `30804449797` 通过。

P1A 已先以 fast-forward 合并并正常推送到 `main`；`origin/main` 保持
`03b1840bf9b413d408c5d8a8ad3741d6bfdab46a`。P1B 使用独立分支
`p1b/core-local-ledger`，工程提交通过普通推送同步；最终文档提交 SHA 以 Git 远端引用
和关闭汇报为准。

## 未完成与下一阶段门禁

完整 Xcode 与 CocoaPods 仍未就绪，因此 `IOS_TOOLCHAIN = BLOCKED`，没有声称 iOS 构建
通过。P1B 不处理真实旧数据库迁移、登录、云端业务表、同步、预算、统计图表、AI、
正式包名、签名或商店发布。

P1B 可以在本报告、最终工作树和远端 CI 全部关闭后结束；不得据此自动进入 P1C。
