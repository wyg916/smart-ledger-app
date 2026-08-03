# P0-CLOSEOUT 脱敏证据摘要

执行日期：2026-08-03

## 命令结果

| 序号 | 命令 | 退出码 | 实际用时 | 结果 |
|---:|---|---:|---:|---|
| 1 | `./gradlew --version` | 0 | 20.92 s | Gradle 8.7 / Temurin 17.0.20 |
| 2 | `./gradlew tasks` | 0 | 94.22 s | PASS |
| 3 | `./gradlew clean --stacktrace` | 0 | 0.60 s | PASS |
| 4 | `./gradlew test --stacktrace` | 0 | 148.87 s | 6/6 变体执行通过 |
| 5 | `./gradlew assembleDebug --stacktrace` | 0 | 56.47 s | PASS |

测试汇总：3 个唯一测试方法，Debug 3/3、Release 3/3；失败 0、错误 0、跳过 0，失败名称无。

## APK 与运行证据

- APK：`legacy/android-kotlin/app/build/outputs/apk/debug/app-debug.apk`
- 大小：21,967,056 字节
- SHA-256：`2e4fb5df6077266fbd1e14385c640c61c6b27baf36f85c1e91cc57e36354210f`
- `adb install -r`：成功
- 主 Activity 冷启动：成功，2383 ms
- 前台 Activity：`com.offline.ledger/.MainActivity`
- 启动崩溃/ANR 扫描：未发现
- 首页目视检查：成功进入“明细”基础首页

## 日志处理

完整原始构建日志保存在仓库外 `/tmp/smart-ledger-p0-closeout-20260803/`。原始日志包含本机用户目录与主机信息，因此不提交；本文件只保留不含秘密和本机私有路径的结果摘要。APK、截图、SDK、AVD、构建缓存与 Gradle 缓存同样不提交。

## 安全检查摘要

- 敏感扩展名/文件名扫描：未发现 `.env`、签名文件、`local.properties` 或数据库。
- 大文件工作树扫描：只发现 3 个被 Git 忽略的 Android 构建产物（Debug APK、DEX 和 Java 资源缓存）。
- Git 候选文件检查：无禁止文件，无超过 20 MiB 文件。
- 高置信秘密模式扫描：未发现。
- `git diff --check`：通过。
