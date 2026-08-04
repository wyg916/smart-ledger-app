# 应用商店审核访问说明

首发渠道：应用宝。登录页无游客入口，普通用户使用本机号码或微信；审核人员展开“其他登录方式”使用专用 review user。

- 账号由 `services/api/scripts/provision_review_account.py` 从环境变量创建；真实用户名/密码不进入 Git、APK、文档或截图。
- 在应用宝审核备注填写中文步骤和凭据；未来 Google Play 使用 `PLAY_REVIEW_INSTRUCTIONS_EN.md` 并只在 Play Console App access 交付凭据。
- 审核账号必须可重复登录、不依赖 SIM/微信/OTP/地区，可访问所有核心用户功能，无后台管理权。
- 每次提交前验证 enabled、限流、密码轮换和合成本地数据初始化；提交后可禁用但应保留复审恢复流程。

当前状态：代码与配置能力已完成；生产实例尚未部署，因此审核账号真实登录为 BLOCKED。
