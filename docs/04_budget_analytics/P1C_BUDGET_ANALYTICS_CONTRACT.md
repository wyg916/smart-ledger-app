# P1C 本地预算与统计分析契约

状态：冻结用于 P1C 实现

日期：2026-08-03

事实优先级：`CURRENT_STATE` → P1B 冻结契约 → 数据库 V2 → PRD → 当前 Flutter → 旧 Android

## 范围与兼容决策

P1C 只建立完全离线的月度预算和确定性统计闭环。登录、云同步、Outbox、后端业务表、
备份恢复、应用锁、目标、AI、导入导出和发布均不在本轮。

数据库 V2 定义了可扩展的 `budgets` 与 `budget_categories`，本轮产品要求则明确为单月
总支出预算和单月单支出分类预算。Schema 3 采用 V2 字段的兼容超集，并冻结以下 P1C
特化：`period_type` 只能为 `monthly`；分类预算由 `category_id` 唯一关联一个支出分类；
`budget_categories` 的多分类组合与 `custom` 周期暂不开放。这样不会把旧 Android 的任意
分类集合行为错误提升为新契约，未来扩展也必须另行迁移和评审。

## 预算实体

`budgets` 是同步预留业务实体，包含：

| 字段 | SQLite / Dart | 可空 | P1C 规则 |
|---|---|---:|---|
| `id` | TEXT / String | 否 | 小写带连字符 UUID；主键 |
| `ledger_id` | TEXT / String | 否 | FK `ledgers.id`，RESTRICT |
| `name` | TEXT / String | 否 | 总预算为“月度总预算”；分类预算默认使用分类名 |
| `scope_type` | TEXT / enum | 否 | `total/category` |
| `category_id` | TEXT / String | 是 | total 必须为空；category 必须为同账本支出分类 FK |
| `year_month` | TEXT / String | 否 | 公历 `YYYY-MM`，固定 7 字符 |
| `amount_minor` | INTEGER / int | 否 | Int64 最小单位，允许 0，禁止浮点 |
| `currency_code` | TEXT / String | 否 | 与所属账本一致的 3 位大写 ISO 4217 |
| `time_zone_id` | TEXT / String | 否 | 创建时所属账本的有效 IANA 时区 |
| `period_type` | TEXT / String | 否 | P1C 固定 `monthly` |
| `start_date_local` | TEXT / String | 否 | 该月首日 `YYYY-MM-01` |
| `end_date_local` | TEXT / String | 否 | 下月首日，表示半开区间终点 |
| `alert_thresholds_json` | TEXT / String | 是 | P1C 默认 `[0.8,1.0]`，仅展示状态，不发通知 |
| `is_active` | INTEGER / bool | 否 | 默认 true；停用不再作为当前生效预算 |
| `created_at_ms` | INTEGER / int | 否 | 首次创建 UTC epoch ms，不修改 |
| `updated_at_ms` | INTEGER / int | 否 | 最近成功本地写入 UTC epoch ms |
| `deleted_at_ms` | INTEGER / int | 是 | Tombstone；默认查询排除 |
| `version` | INTEGER / int | 否 | 创建为 1，每次编辑、启停或删除加 1 |
| `last_modified_device_id` | TEXT / String | 是 | P1C 保持空，仅为未来同步预留 |
| `sync_status` | TEXT / String | 否 | P1C 固定写 `pending`，不执行同步 |
| `legacy_id` | INTEGER / int | 是 | 未来旧数据迁移对账预留 |

## 唯一性、生命周期与校验

- 活动记录按 `(ledger_id, year_month, scope_type, category_id)` 唯一；total 的
  `category_id IS NULL` 由独立部分唯一索引保证同账本同月只有一个未删除总预算；分类
  预算由部分唯一索引保证同账本同月同分类只有一个未删除预算。停用记录仍占用唯一键；
  只有逻辑删除后才可重新创建同范围预算。
- 分类预算只能选择同账本、未删除、当前启用的 `expense` 分类。禁用分类不能用于新预算，
  也不能在编辑时改选；已经存在的历史预算仍联表显示禁用分类名称并正常计算历史支出。
- 创建、编辑、启停、逻辑删除都通过 Repository / Use Case。Widget 不访问 DAO 或 SQL。
- 编辑保留 `id`、`created_at_ms`，更新允许字段、`updated_at_ms`、`version + 1`；逻辑删除
  设置 `deleted_at_ms`、`updated_at_ms`、`version + 1`，不物理删除。
- 停用只设置 `is_active=false`，不删除、不清零、不改变历史使用额；列表可显示停用预算。
- 默认查询排除 `deleted_at_ms IS NOT NULL`；详情仍可由内部迁移/诊断按 ID 读取 Tombstone。

## 金额、币种与预算计算

- 所有持久化、过滤、求和、比较、剩余和超支只使用 Dart `int` / SQLite `INTEGER` 的
  Int64 最小货币单位。金额输入沿用 P1B `Money` 字符串解析；百分比只作为展示值。
- P1C 单账本预算的 `currency_code` 必须等于账本币种；不做换汇、跨币种合并或汇率。
- 已使用金额：预算所属账本与月份半开区间内，未逻辑删除且类型为 `expense` 的交易
  `amount_minor` 之和。总预算包含全部合法支出；分类预算再限定 `category_id` 相等。
- `income` 和 `transfer` 永不消耗预算；交易 Tombstone 不消耗预算。禁用账户或分类上的
  历史支出仍消耗对应历史预算。
- `remaining_minor = max(amount_minor - used_minor, 0)`。
- `overrun_minor = max(used_minor - amount_minor, 0)`；`is_overrun = used_minor > amount_minor`。
- 预算为 0 时：使用额为 0 则展示使用率 0；使用额大于 0 则展示已超支，不执行除零，
  展示层可把使用率封顶为 100%。非零预算展示率为 `used / amount`，仅在展示边界转换。
- 接近用尽状态为未超支且 `used * 100 >= amount * 80`；比较使用整数乘法，不用浮点决策。
- 交易新增、编辑、跨月移动或逻辑删除后，Drift 观察查询必须使相关月份预算实时重算。

## 月份、UTC 与 IANA 时区

- `year_month` 表示预算账本时区中的公历月份，不保存为 UTC 月份或设备当前月份。
- 月份边界算法：在预算记录的 `time_zone_id` 中构造当地月首 `00:00:00` 和下月月首
  `00:00:00`，分别转换为 UTC epoch ms，查询使用 `[start_utc_ms, end_utc_ms)`。
- P1C 使用受控 IANA 时区转换器；生产支持账本当前 IANA ID，测试覆盖 `Asia/Shanghai`
  月初/月末边界。无效或无法解析的时区必须拒绝，不静默使用设备/服务器时区。
- 统计月份使用账本 IANA 时区计算统一 UTC 边界；交易自身保存的原始时区继续保留，但
  不把不同时区的同一 UTC 时刻重复计入多个月份。

## 确定性统计口径

- 月度收入只求和未删除 `income`；月度支出只求和未删除 `expense`；净额为收入减支出；
  `transfer` 不参与三者。
- 账户筛选：收入/支出匹配 `account_id`；转账虽然不计收支，但账户余额仍按来源扣减、
  目标增加。分类筛选只匹配 `category_id`。
- 每日趋势在账本时区内按当地日期聚合，并补齐所选月份的每一天；无交易日收入/支出为 0。
- 收入与支出分类排行分别聚合匹配类型。排序依次为金额降序、分类 `sort_order` 升序、
  分类创建时间升序、分类 UUID 字典序；并列金额仍按该确定性规则排序。
- 账户余额概览沿用 P1B：期初余额 + 收入 - 支出 - 转出 + 转入，排除交易 Tombstone；
  可显示禁用账户并保留历史余额。月份/分类筛选不改变“当前账户余额”的事实含义，账户
  筛选只限制显示的账户。
- 禁用账户和分类的历史交易继续进入历史统计并显示原名称；逻辑删除交易全部排除。
- 环比同时返回本月值、上月值和差额。基期无任何对应交易时标记 `noBaseline=true`，率为
  `null`；上月存在交易但汇总为 0 时率同样为 `null`，不得除零或伪造 0%。其余环比率仅
  用于展示，业务差额保持 Int64。
- 所有聚合必须在有月份边界的 Drift/SQLite 查询中完成；UI 不加载无边界全历史再聚合。

## Schema 2 → 3 迁移

- 迁移只创建 `budgets`、相关索引与约束/触发器，不重建、不删除、不更新 P1B 的
  `ledgers/accounts/categories/transactions/app_settings` 数据。
- 升级事务失败必须向上抛错；不得捕获后删除数据库或重新 seed。
- 迁移前后的账户、分类、交易数量，金额、余额、`version`、`deleted_at_ms` 必须相同；
  `PRAGMA foreign_key_check` 必须为空；预算表为空，不自动插入演示预算。
- 新安装直接创建完整 Schema 3；Schema 1 仍可依既有路径创建 P1B 表后继续升级到 3。
- Schema 3 无自动降级。需要回退时保留数据库并使用兼容版本，不声称可逆迁移。

## 旧 Android 预算映射

- `monthly_budget_cent` 将来按用户确认的账本时区和目标月份映射为一个 total 预算；旧值
  没有月份，不能自动复制到所有历史/未来月份。
- `BudgetItem(id,name,budget_cent,category_ids,preset)` 是 DataStore JSON。单一有效支出
  分类可映射为一个 category 预算；零分类或多个分类的预算项不能无损映射到 P1C 单分类
  模型，正式旧库迁移时必须报告并让用户拆分/选择，不能静默丢弃。
- 旧 `preset` 只作为迁移来源信息，不在新安装 seed 任何演示或预设预算。
- 旧 Android 使用 Float/Double 展示比例、剩余额封底为 0，且按设备本地时区统计；P1C
  保留整数金额和剩余封底，同时新增明确超支额，并以账本 IANA 时区为准。

## 当前明确不支持

自定义周期、多分类组合预算、周/年预算、预算结转、多币种换算、提醒通知、退款类型、
财务目标、旧 DataStore 正式导入、账号、云同步、Outbox、冲突、备份恢复、Excel/CSV、
应用锁、生物识别、OCR、银行流水、AI、Agent、记忆、RAG、向量库、任意 SQL、正式包名、
签名、iOS/Android 正式发布均不在 P1C。
