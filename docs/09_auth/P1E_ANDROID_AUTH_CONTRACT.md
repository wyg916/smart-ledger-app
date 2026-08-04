# P1E Android 强制认证契约

状态：FROZEN
日期：2026-08-04

## 产品边界

- 正式 Android App 不提供游客模式；首次安装必须联网并完成登录后才能打开账本。
- 普通用户入口只有“本机号码一键登录”和“微信登录”。审核账号是受控商店审核身份，不是游客绕过。
- 本轮不实现短信验证码、账号密码注册、业务账单上传或云同步。
- 内部 `user_id` 使用 UUID v4；手机号、微信 openid/unionid 不作为主键。
- 所有账单、预算和分类仍只保存在设备上的该用户独立 SQLite 文件中。

## 启动与路由 Gate

启动顺序固定为 Splash → Secure Storage → Session 恢复/必要时刷新 → 登录页或数据绑定页 →
打开用户数据库 → AppShell。未认证时，返回键、深链接、通知和任意业务路由都只能停留或重定向到
`/login`。登录过程中不得创建或读取用户账本数据库。

## 登录 Provider

### 本机号码

Android 原生层负责 SDK 预取号和运营商授权页；Flutter 只接收一次性 token、运营商枚举和结果状态。
FastAPI 使用 `PhoneOneClickProvider` 换号。生产默认腾讯云实现：token 最长两分钟且单次消费，服务端
按官方 `sha256(appkey=...&random=...&time=...)` 规则验证。App key 不进入客户端、日志或 Git。
Fake Provider 只允许 development/test/CI。

无 SIM、双卡、仅 Wi-Fi、蜂窝关闭、不支持运营商、取消、初始化失败、超时、换号失败和 token 重放
均返回稳定错误码，不得退化为用户自报手机号或短信登录。

### 微信

Android 使用微信 OpenSDK，先从 FastAPI 取得一次性 state，再发起 `snsapi_userinfo` 授权。回调只把
code/state 交给 FastAPI；FastAPI 校验并单次消费 state，使用服务端 AppSecret 换取身份，优先使用
unionid，否则使用带 AppID 作用域的 openid。code/state 重放、取消、拒绝、未安装和服务异常均失败关闭。

### 审核账号

`其他登录方式 → 审核账号登录` 使用服务端可禁用、可轮换的专用 review user。真实凭据只交付商店
审核后台，不硬编码 APK、不写 Git、不具备后台权限；合成账本在首次登录后由本地测试流程创建。

## Session 与 Token

- Access Token：短期 JWT，包含 `sub=user_id`、`sid=session_id`、`iat/exp/jti/type`，生产必须使用外部
  注入的高熵 secret。
- Refresh Token：随机不透明值；服务端只存 SHA-256，每次刷新轮换，旧 token 立即标记已使用。
- logout 撤销 session 及其全部 refresh token；删除账号撤销用户全部 session。
- Secure Storage 只保存当前 user_id、access/refresh token、过期时间和最后一次服务端验证时间。
- 成功在线登录后允许最多 7 天离线进入该用户本地核心；首次登录、已撤销、已删除或超过期限不得离线。
- 401/refresh 重放清除本地 session 并回到登录页；网络不可达与认证拒绝必须区分。

## 身份绑定与冲突

同一用户可绑定 `phone_one_click`、`wechat`、`play_review`。`provider + provider_subject_hash` 唯一；
标准化手机号哈希唯一。绑定已属于其他用户的身份返回冲突，不自动合并本地账本。解绑不得移除最后一个
可登录身份。

## 删除账号

App 内二次确认后创建并确认幂等删除请求。确认时撤销 token/session、移除认证身份、解除 Telemetry
用户映射并把用户标记为 deleted。客户端明确选择删除本地独立账本或保留隔离文件；不声称删除不存在的
业务云账单。必要安全审计仅保留去标识化结果和法定期限说明。

## 生产失败关闭

Production 缺少 JWT、Provider、数据库或 HTTPS 配置时服务不得启动或认证接口返回不可用；生产严禁
Fake Provider。AI 在 production 仅接受有效 App Access Token，内部指标仍使用独立内部凭据。
