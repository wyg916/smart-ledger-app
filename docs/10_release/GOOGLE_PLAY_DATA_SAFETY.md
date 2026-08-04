# Google Play Data Safety 草稿

首发渠道为应用宝；本表保留给后续 Google Play 申报，必须以最终二进制和正式隐私政策复核。

- Account info / Phone number：由号码认证处理，用于账号管理；服务端仅保留哈希/掩码，传输加密，可删除。
- User IDs：内部 UUID、微信身份哈希，用于账号和安全；传输加密，可删除。
- App activity：白名单功能事件用于分析；不含账单内容，可解除账号映射。
- Photos：仅用户主动选择做图片分析时传给 Kimi，不作为运营分析数据，不在服务端持久化。
- Financial info：账本业务数据仅本地；用户主动调用 AI 时发送必要聚合/草稿内容，需在表单中按“App functionality”准确申报。
- Device or other IDs：installation/session ID；腾讯 SDK 可能处理 OAID，须在正式 SDK 接入后确认。
- Diagnostics / IP：服务运行与第三方 SDK 可能处理，用于安全、适配和稳定性。

安全实践：HTTPS、Secure Storage、服务端身份哈希、Refresh Token 哈希和轮换、用户可请求删除。当前尚未完成独立安全评估，不勾选未经证实的认证项。
