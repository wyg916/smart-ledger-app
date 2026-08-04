# P1D 匿名身份与运营分析实现报告

状态：本地与 Android 门禁通过，远端门禁待完成
日期：2026-08-04

## 实现结果

- Flutter 首启生成 UUID v4 installation/actor，安全存储 Token；每次前台会话生成新 session。
- Drift Schema 4 新增独立事件队列：500 条上限、30 天保留、50 条批量、幂等 event ID、
  有限退避；失败不阻塞账本。
- FastAPI/Alembic 新增四张 analytics 表和 installation、session、batch、metrics 五类接口；
  安装 Token 只存 SHA-256，内部指标缺少正确 Token 时 fail-closed。
- 服务端与 Flutter 共享事件名/属性白名单；金额、备注、分类/账户名、AI 正文和图片均被拒绝。
- 游客页准确说明仅本机账本、当前无注册和云同步；应用锁使用系统生物识别/设备凭据，不保存
  明文密码。Android 最近任务预览实测为空白；iOS 未验收。

## Android 合成现场指标

模拟器在成功、取消和故障降级均走过后，最终 30 天接口返回：DAU/WAU/MAU 均为 1，新增安装
1，会话 4，人均会话 4.0，记账 2 次，快捷分类使用率 0.5，自然语言确认率 0.5，AI 成功率
0.6667，图片成功率 1.0；D1/D7 因 cohort 未成熟返回 null。非 1.0 的率来自验收中刻意执行的
取消/未配置降级，不是丢失事件。报告不保留 Token、标识或正文；DAU 是匿名 actor。

## 验证

- FastAPI telemetry、鉴权、幂等、白名单、敏感属性、DAU/WAU/MAU 和未授权指标测试通过。
- Flutter 身份持久化、session 更新、事件清洗、离线队列上限/重试和游客/应用锁测试通过。
- Schema 3→4 升级保留既有账本事实；Android `install -r` 后旧收入、支出和统计仍在。
- `scripts/product_metrics_report.py` 可用环境 Token 拉取 7/30 天脱敏摘要且不打印凭据。

## 边界

没有注册、账号绑定、账单云表、账单 Push/Pull 或多设备同步。服务端原始事件保留/删除策略
已在契约冻结，生产定时清理与匿名身份删除 API 属下一阶段。`IOS_TOOLCHAIN = BLOCKED`。
