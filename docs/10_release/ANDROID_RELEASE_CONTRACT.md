# Android 发布候选契约

状态：FROZEN
首发渠道：应用宝

## 不可逆身份

- App 名称：智能记账
- applicationId / namespace：`com.wyg916.smartledger`
- API：`https://www.znjz.site`
- 首个候选版本：`1.0.0`，versionCode `1`
- compileSdk / targetSdk：36；minSdk 保持 Flutter 当前兼容下限。
- 微信回调：`com.wyg916.smartledger.wxapi.WXEntryActivity`
- Deep Link：`https://www.znjz.site/auth/callback` 与 `smartledger://auth/callback`

## Release 安全

- production 构建必须显式传入 `APP_ENV=production` 和 HTTPS API；缺失或非 HTTPS 时启动失败关闭。
- Release 只从被忽略的 `android/key.properties` 读取 Keystore 路径、alias 和密码。
- 缺少正式签名时允许 CI 验证 Debug/无签名 Release 编译，但不得称为 RC、不得生成弱 Keystore。
- Release 开启 R8、资源压缩；mapping/native symbols 作为私有发布工件保存，不进入公共 Git/CI Artifact。
- 网络安全配置 production 禁止明文；仅 debug manifest 允许模拟器开发地址。

## 候选门禁

正式签名 AAB/APK、签名验证、SHA-256、升级安装、API 36、至少两种 Android 版本真机、本机号码真实
登录、微信真实登录、生产 HTTPS/迁移/备份恢复和安全扫描全部通过后才能标记 RC PASS。任何一项缺失
均为 PARTIAL，禁止合入 main。
