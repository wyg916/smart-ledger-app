# Android 正式签名与工件私有归档

不得生成弱口令 Keystore，不得把 Keystore、`key.properties`、密码、AAB/APK、mapping 或 symbols 提交 Git。

由发布负责人在受控设备创建高熵 Keystore，并在 `apps/mobile/android/key.properties` 配置 `storeFile`、`storePassword`、`keyAlias`、`keyPassword`。该文件与 `*.jks`/`*.keystore` 已被忽略。构建脚本缺少任一字段时不会回退 Debug 签名。

正式命令必须同时传：

```text
flutter build appbundle --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://www.znjz.site
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://www.znjz.site
```

使用 `apksigner verify --verbose --print-certs` 验 APK，使用 `jarsigner -verify`/bundletool 验 AAB，并记录 SHA-256、大小和 versionCode。把 `mapping.txt` 与 native debug symbols 连同工件放入加密私有发布库，按版本和哈希索引；公共 CI 不上传正式签名工件。
