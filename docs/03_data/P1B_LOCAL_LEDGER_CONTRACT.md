# P1B 本地记账数据契约

状态：冻结用于 P1B 实现

日期：2026-08-03
事实优先级：`CURRENT_STATE` → 数据库 V2 / 已冻结 ADR → PRD → P1A → 旧 Android

## 范围与实体

P1B 只建立离线本地闭环。正式 Drift Schema 包含 `ledgers`、`accounts`、
`categories`、`transactions` 和 `app_settings`。账号、云端表、Outbox 执行器、
附件、标签、预算、目标、AI 和正式旧库迁移不在本轮实现。

`ledgers`、`accounts`、`categories`、`transactions` 是未来同步业务实体，统一包含：

| 字段 | SQLite / Dart | 可空 | 默认与规则 |
|---|---|---:|---|
| `id` | TEXT / String | 否 | 小写带连字符 UUID；主键 |
| `created_at_ms` | INTEGER / int | 否 | 首次创建 UTC epoch ms，后续不修改 |
| `updated_at_ms` | INTEGER / int | 否 | 最近本地写入 UTC epoch ms |
| `deleted_at_ms` | INTEGER / int | 是 | Tombstone；默认查询排除非空记录 |
| `version` | INTEGER / int | 否 | 创建为 1，每次成功修改或逻辑删除加 1 |
| `last_modified_device_id` | TEXT / String | 是 | P1B 无设备身份，保留为空 |
| `sync_status` | TEXT / String | 否 | `pending`；字段仅预留，本轮不执行同步 |
| `legacy_id` | INTEGER / int | 是 | 仅未来旧 Android 迁移对账使用 |

### ledgers

| 字段 | 类型 | 可空 | 默认与约束 |
|---|---|---:|---|
| `name` | TEXT | 否 | 非空；首次启动为“默认账本” |
| `currency_code` | TEXT | 否 | `CNY`；3 位大写 ISO 4217 |
| `time_zone_id` | TEXT | 否 | IANA 时区 ID |
| `is_default` | INTEGER/Bool | 否 | 默认 `true`；P1B 单账本 |
| `settings_json` | TEXT | 是 | P1B 不写业务设置 |

### accounts

| 字段 | 类型 | 可空 | 默认与约束 |
|---|---|---:|---|
| `ledger_id` | TEXT | 否 | FK `ledgers.id`，RESTRICT |
| `name` | TEXT | 否 | trim 后非空 |
| `normalized_name` | TEXT | 否 | trim 后小写；同账本活动记录唯一 |
| `account_type` | TEXT | 否 | `cash/bank/wallet/other` |
| `opening_balance_minor` | INTEGER | 否 | Int64 最小单位；允许负期初余额 |
| `icon_code` | TEXT | 是 | 跨端图标编码 |
| `sort_order` | INTEGER | 否 | 默认 0 |
| `enabled` | INTEGER/Bool | 否 | 默认 true；禁用后不能用于新交易 |

账户余额不持久化：`期初余额 + 收入 - 支出 - 转出 + 转入`。账户不物理删除；
历史交易继续联表显示被禁用账户。

### categories

| 字段 | 类型 | 可空 | 默认与约束 |
|---|---|---:|---|
| `ledger_id` | TEXT | 否 | FK `ledgers.id`，RESTRICT |
| `category_type` | TEXT | 否 | `income/expense` |
| `name` | TEXT | 否 | trim 后非空 |
| `normalized_name` | TEXT | 否 | 同账本、同类型活动记录唯一 |
| `icon_code` | TEXT | 是 | 跨端图标编码 |
| `color_token` | TEXT | 是 | 设计系统颜色 Token |
| `sort_order` | INTEGER | 否 | 默认 0 |
| `enabled` | INTEGER/Bool | 否 | 默认 true；禁用后不能用于新交易 |
| `system_key` | TEXT | 是 | 内置分类稳定标识；同账本唯一 |

分类不物理删除。收入分类只能用于收入，支出分类只能用于支出；历史交易继续显示
已禁用分类。

### transactions

| 字段 | 类型 | 可空 | 默认与约束 |
|---|---|---:|---|
| `ledger_id` | TEXT | 否 | FK `ledgers.id`，RESTRICT |
| `transaction_type` | TEXT | 否 | `income/expense/transfer` |
| `account_id` | TEXT | 否 | 来源账户 FK，RESTRICT |
| `to_account_id` | TEXT | 是 | 转账目标账户 FK，RESTRICT |
| `category_id` | TEXT | 是 | 收支必填、转账为空；FK RESTRICT |
| `amount_minor` | INTEGER | 否 | Int64 正整数 |
| `occurred_at_utc_ms` | INTEGER | 否 | 发生时间 UTC epoch ms |
| `time_zone_id` | TEXT | 否 | 发生时的 IANA 时区 ID |
| `note` | TEXT | 是 | trim 后最多 500 个字符 |
| `merchant` | TEXT | 是 | P1B UI 暂不采集 |
| `source_type` | TEXT | 否 | P1B 固定 `manual` |
| `transfer_group_id` | TEXT | 是 | V2 单行转账表达下为空 |

数据库 V2 与开发路线明确包含转账，因此 P1B 采用正式的单行转账表达：来源账户写
`account_id`、目标账户写 `to_account_id`、`category_id=NULL`，且两个账户必须不同。
转账影响账户余额，但不计入收入、支出或净额。

### app_settings

| 字段 | 类型 | 可空 | 默认与约束 |
|---|---|---:|---|
| `key` | TEXT | 否 | 主键 |
| `value_type` | TEXT | 否 | `string/int/bool/json` |
| `value_text` | TEXT | 是 | 序列化值 |
| `updated_at_ms` | INTEGER | 否 | UTC epoch ms |
| `sync_scope` | TEXT | 否 | `device/account`；P1B 只使用 device |

## 标识、金额与时间

- 用户新建业务实体使用 UUID v4；首次启动的账本、默认账户和内置分类使用固定、有效
  的 UUID，以保证重复初始化幂等。数据库不使用自增业务 ID。
- 金额只用 Dart `int` / SQLite `INTEGER` 的 Int64 最小单位。十进制输入通过字符串拆分
  和整数运算解析，最多两位小数；禁止 `double`、`float`、`REAL`。
- 解析先用任意精度整数检查范围，再转换为 Int64；零、负数、非法字符和超出两位小数
  均拒绝。格式化统一输出两位小数。
- 所有时间由可注入 Clock 提供，写入前转 UTC epoch ms。设备 IANA 时区通过平台时区
  服务读取；测试显式注入固定 UTC 时间与 `Asia/Shanghai`。
- 不用当前时间、随机金额或演示账单 seed 正常用户数据库。

## 写入、删除与统计

- 创建记录时 `created_at_ms == updated_at_ms`、`version=1`。
- 修改只改变允许字段，同时更新 `updated_at_ms` 并将 `version + 1`；创建时间不变。
- 交易删除只设置 `deleted_at_ms`，同时更新时间并递增版本。默认列表、详情入口和汇总
  排除 Tombstone。
- 账户和分类的 P1B 生命周期只有启用/禁用；不提供物理删除入口。
- 日期范围采用 `[startUtcMs, endUtcMs)` 半开区间，避免相邻范围重复。
- 收入合计只含未删除 `income`，支出合计只含未删除 `expense`，净额为收入减支出；
  `transfer` 不参与这三项。账户、分类筛选在汇总和列表使用相同口径。

## 旧 Android 与 Fixture

旧表字段映射详见 `LEGACY_TO_FLUTTER_MAPPING.md`。10 组 Fixture 的 P1B 处理如下：

| Fixture | P1B 结果 | 说明 |
|---|---|---|
| `room_v1_empty` | 接受 | 创建幂等默认账本、账户和分类；交易为 0 |
| `room_v1_basic` | 接受并测试入库 | Long ID 映射 UUID；旧 book 映射 ledger；交易映射默认账户 |
| `room_v1_budget` | 明确拒绝 | 预算不在 P1B；不得静默丢弃预算字段 |
| `room_v1_deleted_category` | 接受 | 分类映射为禁用，保留历史交易引用 |
| `room_v1_large` | 接受场景规范 | 以固定 seed 生成测试数据；不在正常 App seed |
| `sync_single_device` | 明确拒绝 | 同步执行器不在 P1B |
| `sync_two_devices` | 明确拒绝 | 多设备同步不在 P1B |
| `sync_conflict` | 明确拒绝 | 冲突处理不在 P1B |
| `sync_offline_delete` | 明确拒绝 | 只验证本地 Tombstone，不执行传播 |
| `corrupted_backup` | 明确拒绝 | 备份恢复不在 P1B |

Fixture 全部是 `synthetic=true` 的规范文件。测试适配器只能在测试环境显式调用，正常
App 启动不读取 `tests/fixtures`，也不把 Fixture 显示为用户数据。

## 当前不支持与未来预留

P1B 不支持登录、JWT、云同步、Outbox 执行、冲突、附件、标签、预算、目标、备份恢复、
导入导出、AI、正式包名/签名或服务器业务表。`version`、`deleted_at_ms`、
`last_modified_device_id`、`sync_status` 与 `legacy_id` 仅为数据库 V2 兼容预留；本轮
不启动网络或同步失败路径。
