# Android 正式提交检查表

- [ ] 生产域名 HTTPS、live/ready/privacy/terms/account-deletion 可公网访问
- [ ] PostgreSQL 0001→head、备份与恢复演练、监控告警通过
- [ ] 腾讯号码认证资质/白名单/专属 Android SDK 与真机蜂窝登录通过
- [ ] 微信开放平台包名/签名/AppID/Secret 与真实授权通过
- [ ] 审核账号在生产可重复登录，凭据只交付商店后台
- [ ] API 36 模拟器、两种 Android 版本真机、升级/隔离/删除/AI/锁通过
- [ ] 正式 Keystore 本地受控，AAB/APK 签名验证、SHA-256、mapping/symbols 私有归档
- [ ] 最终 AAB 权限、SDK、域名、日志和秘密扫描通过
- [ ] 8 张无真实数据截图、图标、宣传图、文案、分级和隐私申报齐全
- [ ] `<SUPPORT_EMAIL>`、运营主体和法律审核后的政策/协议已发布
- [ ] 分支最终 HEAD CI 全绿且与远端同步
- [ ] 提交后记录商店版本、工件哈希、时间与审核状态；不得提前声称审核通过
