# P1E Android Auth RC 工程证据

记录时间：2026-08-04/05（Asia/Shanghai）
工程代码验证 HEAD：`466ec2a`（后续仅有证据/文档提交）
发布资料基线 HEAD：`c29796c`
分支：`p1e/android-auth-release`
基线：`main == origin/main == 73113aca99013a5273c04a1cb9b0b9dfb2f4d256`，开始时 0/0 且工作树干净。

## 工程结果

- 正式身份：智能记账 / `com.wyg916.smartledger` / `1.0.0+1` / minSdk 24 / compileSdk 36 / targetSdk 36。
- Flutter：format 与 analyze 通过；86/86 测试通过；LCOV 4181/8882 行，47.07%。
- FastAPI：Ruff format/check、mypy 47 files 通过；44/44 pytest 通过。
- 数据库：SQLite 与临时 PostgreSQL 16 均完成 0001→0002→0003、current、downgrade base、再次 upgrade head。
- Android：Debug、无签名 Release APK、无签名 Release AAB 编译通过；R8、资源压缩、mapping 与 native debug symbols 已生成。
- API 36 模拟器：Android 16/API 36 冷启动安装通过；未登录显示且仅显示号码、微信、协议和受控审核入口；返回键不退出 Gate；定向 HTTPS 深链接仍回登录；无 App FATAL/ANR/SQLiteException。
- 模拟器 Provider：号码明确显示“SDK 尚未配置”；微信明确失败关闭。模拟结果不计真实 Provider PASS。
- 后台预览：Android `FLAG_SECURE` 生效，系统截屏为黑屏；Kimi 图片分析仍通过用户从系统选择已有图片进入。
- 生产 Compose：开发与 production Compose 均通过配置解析；production 仅代理暴露 80/443，数据库/API 不映射公网端口。
- 远端 CI：工程代码提交 `466ec2a` 的 Repository Safety、FastAPI foundation、Flutter foundation、Android release candidate compile check 全部 `success`；发布资料提交 `c29796c` 的 Repository Safety 亦为 `success`。

## 编译工件（不是发布候选）

以下文件位于被 Git 忽略的本机构建目录，仅证明 Release 编译链闭合：

| 工件 | 大小 | SHA-256 | 签名 |
|---|---:|---|---|
| `apps/mobile/build/app/outputs/flutter-apk/app-release.apk` | 67,309,556 bytes | `98cf353b12a822a0711366cc70e558370b918504f695c29eed8db8f9a551d0bb` | `apksigner` exit 1，未签名 |
| `apps/mobile/build/app/outputs/bundle/release/app-release.aab` | 64,602,134 bytes | `f9d8f047271a9b272da5f419104cf6f0b12a7eee2664cdd492982ca589e4aa1d` | `jarsigner` 明确“未签名” |

附属输出：`build/app/outputs/mapping/release/mapping.txt` 与 `build/app/outputs/native-debug-symbols/release/native-debug-symbols.zip`。正式 Keystore 配置后必须重新构建，届时工件大小和哈希全部作废并重新记录。

## 未关闭门禁

- 腾讯云号码认证资质/白名单/专属原生 SDK、服务端正式凭据和插 SIM 蜂窝真机未提供。
- 微信开放平台 Android 应用、正式 AppID/AppSecret、包签名登记和装有微信的真机未提供。
- `apps/mobile/android/key.properties` 与正式 Keystore 不存在；当前工件未签名。
- `https://www.znjz.site:443` 拒绝连接，生产 API、公开政策/删除页、Kimi、Telemetry、review user、备份/恢复和监控未部署验收。
- 无连接 Android 真机，至少两种 Android 版本、升级安装、身份绑定、真实 AI/Telemetry、应用锁与删除端到端未执行。
- 应用宝真实审核规则/账号交付、8 张最终真机截图、宣传图、运营主体、支持邮箱和法律审核文本未完成。
- CI 已闭合，但仅证明仓库安全检查、自动化测试与无签名 Release 编译链通过，不替代真实 Provider、正式签名、生产部署、真机和商店审核门禁。

因此本记录结论固定为 `P1E-ANDROID-AUTH-RC = PARTIAL`；不得合入 `main`，不得声称已上线或已通过商店审核。
