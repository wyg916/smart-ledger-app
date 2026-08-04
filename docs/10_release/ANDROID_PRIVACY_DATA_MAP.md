# Android 隐私数据地图（发布草案）

本文件是工程事实映射，不代表法律审查结论。

| 数据 | 位置/接收方 | 用途 | 保留与控制 |
|---|---|---|---|
| 账单、预算、账户、分类 | 用户独立本地 SQLite | 记账核心 | 不上传；用户选择删除本地文件 |
| Access/Refresh Token | Android Secure Storage / FastAPI 哈希 | 会话认证 | 轮换、logout/注销撤销 |
| 手机号 | 腾讯云换号、FastAPI 瞬时处理 | 一键登录 | 服务端仅存标准化哈希与掩码提示；日志禁止原文 |
| 微信 code/token/openid/unionid | 微信、FastAPI 瞬时处理 | 微信登录 | code/token 不持久化；身份仅存带服务端 pepper 的哈希 |
| 图片 | Kimi API，经内存重编码 | 用户主动截图解读 | 不落盘、不进日志/Telemetry |
| AI 聚合文本 | Kimi API | 用户主动问答 | 无长期会话、无模型正文日志 |
| installation/session/事件白名单 | 本地队列、FastAPI PostgreSQL | 稳定性与运营分析 | 与 user_id 可解除；禁止财务/AI正文属性 |
| 生物识别结果 | Android 系统/本地插件 | 应用锁 | App 不读取或保存生物特征 |
| 网络、IP、运营商、设备型号、SIM 状态、OAID | 号码认证 SDK/运营商 | 取号、适配、风控 | 以实际 SDK 版本披露和用户同意为前提 |

生产接入 SDK 后必须用最终二进制重新审计权限、组件、域名和实际采集字段，不能只依赖本草案。
