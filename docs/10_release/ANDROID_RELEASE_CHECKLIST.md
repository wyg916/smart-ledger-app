# Android 应用宝发布候选检查表

## 已冻结

- [x] 名称：智能记账
- [x] applicationId：`com.wyg916.smartledger`
- [x] API：`https://www.znjz.site`
- [x] 首发渠道：应用宝

## 工程

- [ ] 强制登录与所有路由 AuthGuard
- [ ] 多账号独立数据库及 Schema 4 显式绑定
- [ ] 号码/微信真实 Provider 与审核账号
- [ ] 账号删除和公开 `/account-deletion`
- [ ] compileSdk/targetSdk 36，format/analyze/test/build 全绿
- [ ] 正式签名 AAB/APK、签名校验、hash、mapping 和 symbols 私有归档
- [ ] API 36 模拟器与至少两种 Android 版本真机验收

## 生产

- [ ] `https://www.znjz.site/health/live` 和 `/health/ready` 成功
- [ ] PostgreSQL Alembic head、生产 Provider、Kimi、Telemetry、限流和最小 CORS
- [ ] 数据库不公网暴露；HTTPS、备份、恢复演练和监控通过
- [ ] `/privacy`、`/terms`、`/account-deletion` 可公开访问

## 应用宝材料

- [ ] 512×512 图标、Feature Graphic/宣传图、8 张手机截图
- [ ] 短描述、完整描述、版本说明、支持邮箱/URL
- [ ] 隐私政策、用户协议、账号删除、第三方 SDK 与审核账号说明
- [ ] 内容分级、权限/数据采集清单和测试说明

当前外部事实（2026-08-04）：本机无正式签名文件、无连接真机、腾讯云白名单/专属 SDK 与微信开放
平台 AppID/AppSecret 未提供，`www.znjz.site:443` 拒绝连接。上述事实解除前不得标记 PASS。
