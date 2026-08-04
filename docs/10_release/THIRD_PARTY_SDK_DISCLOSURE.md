# 第三方 SDK 与服务披露草案

| SDK/服务 | 供应方 | 目的 | 可能处理的数据 | 当前状态 |
|---|---|---|---|---|
| 腾讯云号码认证专属 Android SDK | 腾讯云/运营商 | 本机号码一键登录 | 临时 token、手机号、SIM/运营商/网络/设备/IP，OAID 以最终版本为准 | SDK/白名单未提供，真实门禁阻断 |
| 微信 OpenSDK `6.8.40` | 腾讯 | 微信授权登录 | AppID、一次性 code/state、openid/unionid、设备/网络信息 | 客户端回调已编译；真实 AppID/Secret 未提供 |
| Kimi API | 月之暗面 | AI 问答、解析和图片分析 | 用户主动提交的聚合数据、文字、图片、网络信息 | 生产凭据/域名部署待验收 |
| Flutter Secure Storage | 开源插件/Android Keystore | 保存会话与设备匿名标识 | user_id、token、过期时间、installation ID | 已接入 |
| Local Auth | Android 系统/开源插件 | 应用锁 | 仅系统认证结果 | 已接入；不读取生物特征 |
| 自有 Telemetry | 智能记账 FastAPI/PostgreSQL | 稳定性与运营分析 | installation/session、白名单事件、版本、平台、user_id 映射 | 已实现；生产待部署 |

发布前以最终 AAB 做 SBOM、Manifest、网络域名和运行时采集复核；不得用本草案替代 SDK 官方隐私条款。
