# P0-CLOSEOUT：旧 Android 可复现构建关闭报告

执行日期：2026-08-03
最终结论：**PASS**
基线 HEAD：`ad0b20a2cac17af8ed53f019fca4d22e76a9dde5`

## 1. 范围与结论

本轮只完成开发工具链核验、旧 Android Wrapper 的最小可移植性修复、构建/测试/APK/模拟器验收与基线文档更新。未修改业务代码、Room Schema、数据语义、包名、版本号或签名配置，也未开始 P1。

JDK 17、Android SDK、adb、Gradle Wrapper、clean、现有单元测试、assembleDebug、Debug APK 哈希、模拟器安装与首页启动均取得现场成功证据，满足本任务定义的 P0 PASS 标准。

## 2. 系统与工具链

| 项目 | 现场版本或状态 |
|---|---|
| macOS | 26.5.2 (25F84), arm64 |
| Xcode | 仅 Command Line Tools；完整 Xcode 不可用 |
| Homebrew | 未安装；登录 Shell 仍提示失效的 `/opt/homebrew/bin/brew` 引用 |
| JDK | Eclipse Temurin 17.0.20+8, arm64 |
| Gradle Wrapper | 8.7 |
| Android SDK Command-line Tools | 22.0 |
| Android Platform | Android 34，revision 3 |
| Android Build Tools | 34.0.0 |
| adb / Platform Tools | 1.0.41 / 37.0.1-15733141 |
| Android Emulator | 37.1.11.0 |
| 测试 AVD | Pixel 6，Android 14 / API 34，Google APIs，arm64-v8a |
| Flutter / Dart | 未安装或不在 PATH；本轮不需要 |
| Docker | 未安装或不在 PATH；本轮不需要 |

初始 `JAVA_HOME`、`ANDROID_HOME`、`ANDROID_SDK_ROOT` 均为空。本轮把工具安装到用户级标准目录，并在验收命令中显式配置环境变量；没有把用户名、SDK 绝对路径或 `local.properties` 写入 Git。

## 3. 实际安装与配置

1. 从 Eclipse Adoptium 官方发布源安装 Temurin JDK 17.0.20+8，并按发布元数据校验 SHA-256。
2. 从 Android Developers 官方下载 ARM64 Command-line Tools，并按官网 SHA-256 校验。
3. 通过 SDK 管理器安装并接受许可：`platform-tools`、`platforms;android-34`、`build-tools;34.0.0`。
4. 为启动验收额外安装 `emulator` 与 `system-images;android-34;google_apis;arm64-v8a`，创建 `p0_closeout_api34` AVD。

## 4. Gradle Wrapper 原始问题与修复

原始 `distributionUrl` 为 Windows 本机文件 `file:///E:/gradle-8.7-bin.zip`，macOS 与干净环境不可访问。

最小修复：

- 改为 Gradle 官方 HTTPS 地址 `https://services.gradle.org/distributions/gradle-8.7-bin.zip`。
- 增加 Gradle 官方发布的 `distributionSha256Sum`，固定分发包完整性。
- 将 `gradlew` 权限从 `100644` 修正为 `100755`。

AGP 8.4.2、Kotlin 1.9.24、KSP、Hilt 和业务依赖均未升级。

## 5. 构建与测试证据

工作目录：`legacy/android-kotlin/`。完整原始日志保存在仓库外 `/tmp/smart-ledger-p0-closeout-20260803/`，不会提交；可提交证据摘要见 `evidence/p0_closeout/README.md`。

| 命令 | 退出码 | 用时 | 结果 |
|---|---:|---:|---|
| `./gradlew --version` | 0 | 20.92 s | Gradle 8.7 / JVM 17.0.20 / arm64 |
| `./gradlew tasks` | 0 | 94.22 s | 成功识别 `test`、`testDebugUnitTest`、`testReleaseUnitTest`、`connectedDebugAndroidTest` |
| `./gradlew clean --stacktrace` | 0 | 0.60 s | PASS |
| `./gradlew test --stacktrace` | 0 | 148.87 s | PASS |
| `./gradlew assembleDebug --stacktrace` | 0 | 56.47 s | PASS |

现有两个测试类包含 3 个唯一测试方法。`test` 对 Debug 与 Release 两个变体各执行一次：共 6 次执行，6 通过、0 失败、0 错误、0 跳过；失败测试名称：无。构建仅出现既有弃用 API、协程 opt-in 与注解处理器选项警告，不影响结果。

## 6. APK 验收

| 项目 | 结果 |
|---|---|
| 路径 | `legacy/android-kotlin/app/build/outputs/apk/debug/app-debug.apk` |
| 大小 | 21,967,056 字节（`ls -lh` 显示 21M） |
| SHA-256 | `2e4fb5df6077266fbd1e14385c640c61c6b27baf36f85c1e91cc57e36354210f` |
| applicationId | `com.offline.ledger`（由 APK 元数据确认） |
| 主 Activity | `com.offline.ledger.MainActivity`（由 APK 元数据确认） |

APK 位于被 Git 忽略的构建目录，不提交。

## 7. 安装与启动验证

- `adb install -r`：成功。
- `am start -W -n com.offline.ledger/.MainActivity`：`Status: ok`，冷启动 `TotalTime: 2383 ms`。
- 启动后进程存在，前台 Activity 为 `com.offline.ledger/.MainActivity`。
- 启动日志未匹配到该应用的 FATAL EXCEPTION、AndroidRuntime 崩溃或 ANR。
- 现场截图确认进入“明细”首页，显示月份、收支筛选、“本月暂无记录”和底部导航，基础首页可进入。
- 验收后已通过 emulator console 关闭模拟器。

## 8. 修改文件

- `legacy/android-kotlin/gradle/wrapper/gradle-wrapper.properties`
- `legacy/android-kotlin/gradlew`（仅执行权限）
- `docs/01_baseline/P0_AUDIT_REPORT.md`
- `docs/01_baseline/CURRENT_STATE.md`
- `docs/01_baseline/LEGACY_INVENTORY.md`
- `docs/01_baseline/P0_CLOSEOUT_REPORT.md`
- `docs/01_baseline/evidence/p0_closeout/README.md`

## 9. 尚未关闭的事项

- 完整 Xcode、Flutter/Dart、Docker 与 Homebrew 仍不可用；它们不影响本轮旧 Android P0-CLOSEOUT，但后续对应工作开始前必须单独准备。
- `~/.zprofile` 的失效 Homebrew 引用未修改。
- 是否存在真实用户/正式签名、最终应用标识和商店资源仍需由用户确认；它们阻断迁移与发布决策，但不否定本轮工具链与旧 Android 可复现构建门禁。
- 既有源码编译警告未在本轮修复，以避免扩大到业务代码。

## 10. 安全与远端声明

提交前安全扫描、超过 20 MiB 文件扫描、`git diff --check` 与完整 diff 复核结果见证据摘要。未把 APK、SDK、AVD、Gradle 缓存、原始日志、签名材料或本机路径配置加入 Git。

本轮没有执行 push、force push、创建 PR、修改远端分支或发布 Release。P0 门禁允许在用户明确授权后进入 P1；本轮没有进入 P1。
