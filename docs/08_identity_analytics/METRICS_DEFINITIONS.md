# P1D 匿名运营指标定义

状态：冻结并已实现
日期：2026-08-04

## 统计身份与时间

所有用户口径均按 `anonymous_actor_id` 去重。它代表匿名安装身份，不等于经账号去重的真实
自然人，无法合并同一人的多设备。当前服务端窗口使用 UTC 自然日；产品进入正式区域化运营前
需新增报表时区参数，不能把 UTC 日误称为特定市场当地日。

## 指标

| 指标 | 定义 |
|---|---|
| DAU | 当天至少产生一次 `session_start` 或核心功能事件的去重匿名 actor |
| WAU / MAU | 截至查询日 7 / 30 个自然日内同口径去重 actor |
| 新增安装 | `first_seen_at` 落入所选窗口的 installation 数 |
| 会话数 | 窗口内服务端已接受的 session 数 |
| 人均会话数 | 会话数 / 窗口活跃匿名 actor；分母为零时返回 null |
| 记账用户 / 次数 | `transaction_created` 的去重 actor / 事件数 |
| 快捷分类使用率 | `quick_category_used` / `transaction_created` |
| 一句话确认率 | `natural_language_entry_confirmed` / `natural_language_entry_submitted` |
| AI 成功率 | `ai_chat_success` / `ai_chat_submitted` |
| 图片成功率 | `image_analysis_success` / `image_analysis_submitted` |
| D1 / D7 | 安装首日 cohort 在第 1 / 7 个自然日再次活跃的 actor 占比 |

所有率的分母为零时返回 null；D1/D7 cohort 尚未成熟时返回 null，不能显示为 0%。查询接口
支持 1–30 天窗口；`scripts/product_metrics_report.py` 固定输出最近 7 天和 30 天摘要。

## 隐私与质量限制

指标事件只允许契约白名单与受控 properties，不含金额、账户/分类名、备注、问题或回答、图片、
身份信息、硬件标识或位置。重装、清除安全存储、多设备和未来账号绑定都会影响匿名去重；因此
当前数据适合产品行为趋势，不适合作为注册用户或真实自然人的财务经营口径。
