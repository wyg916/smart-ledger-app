# 旧 Android 到 Flutter V2 映射

状态：P1B 只读审计与未来迁移设计；本轮不执行真实迁移。

## 已核实的旧模型

旧 Room `ledger.db` 为 Schema 1，包含 `books`、`categories`、`transactions`，业务
主键均为自增 `Long`。旧 App 没有账户表，交易固定使用 `book_id=1`；金额使用
`Long amount_cent`；交易用 `deleted` 布尔软删除；分类调用物理删除，但交易外键
`RESTRICT`，所以“历史保留”文案与实际删除行为存在冲突。Preferences DataStore
`settings` 保存锁、自动备份、总预算和预算项 JSON。

## 字段映射

| 旧来源 | Flutter V2 | 转换与风险 |
|---|---|---|
| `books.id` | `ledgers.legacy_id` | 生成 UUID；不可把 Long 当新主键 |
| `books.name` | `ledgers.name` | trim 后非空；币种默认 CNY |
| `books.created_at` | ledger 创建/更新时间 | 视为 epoch ms；迁移前仍需样本范围校验 |
| 无旧账户 | `accounts` | 每个旧账本创建固定 UUID 的“默认账户” |
| `categories.id` | `categories.legacy_id` | 生成 UUID；交易引用按映射表替换 |
| `categories.type` | `category_type` | `0 → expense`，`1 → income` |
| `name/icon_code/sort_order` | 同语义字段 | 名称标准化后检测同类型重复 |
| `enabled` | `enabled` | 被引用分类即使旧值异常也不得物理删除 |
| `is_default` | `system_key` | 未来迁移器生成稳定内置标识；P1B 不执行 |
| `transactions.id` | `transactions.legacy_id` | 生成 UUID，重复导入按 legacy_id 幂等 |
| `book_id` | `ledger_id` | 使用 book→ledger 映射 |
| 无旧账户字段 | `account_id` | 使用该 ledger 的迁移默认账户 |
| `type` | `transaction_type` | `0 → expense`，`1 → income`；旧库无 transfer |
| `amount_cent` | `amount_minor` | Int64 原值，不经浮点转换；必须大于 0 |
| `category_id` | `category_id` | 使用 category Long→UUID 映射；类型必须匹配 |
| `occurred_at` | `occurred_at_utc_ms` | 旧值为 epoch ms；原 IANA 时区未保存，是迁移风险 |
| 无旧时区字段 | `time_zone_id` | 不能凭空恢复；未来迁移需用户确认的源时区并记录 |
| `note` | `note` | trim；超过 500 字时必须显式拒绝或报告，不能静默 |
| `created_at/updated_at` | 同语义 UTC ms | 校验范围；确保 updated ≥ created |
| `deleted` | `deleted_at_ms` | `false → NULL`；`true` 缺删除时刻，未来迁移需明确策略 |
| DataStore 预算 | budgets 相关表 | P1B 不实现；不得只迁交易而宣称完整迁移 |
| DataStore 普通设置 | `app_settings` | 仅非秘密字段；P1B 不执行迁移 |
| PIN/生物识别/Keystore | 不迁移 | 新 App 必须重新配置 |

## 行为差异

- 新版账户是数据库 V2 新实体；旧 `BookEntity` 语义是账本而不是账户。
- 新版账户和分类统一采用禁用生命周期，并保留历史联表显示；不复制旧分类物理删除。
- 新版日期范围为半开区间并保留 IANA 时区；旧统计使用 SQLite `localtime`，换时区后
  可能漂移，正式迁移必须逐月对账。
- 新版交易 Tombstone 使用 `deleted_at_ms`；旧布尔删除没有删除时间和版本信息。
- 新版支持单行 transfer；旧模型没有目标账户字段，不能从旧数据推断转账。
- 旧备份只含数据库，不含 DataStore，因此不能宣称预算和设置完整恢复。

## 未来迁移方案与停止条件

未来迁移器应在临时库中执行：读取旧库 → 建 UUID 映射 → 创建默认账户 → 导入分类和
交易 → 校验外键/类型/金额/时间 → 对账记录数和逐月收支 → 用户确认后原子切换。
同一 `legacy_id` 重复导入必须幂等。源时区、真实用户、正式包名/签名或旧删除时间无法
确认时必须停止相应迁移决策；P1B 不修改旧 Schema、不读取真实数据库、不覆盖旧 APK。
