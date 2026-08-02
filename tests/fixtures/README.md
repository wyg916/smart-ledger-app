# 匿名测试 Fixture

本目录只允许提交虚构数据。当前文件是可审查、可生成的场景规范；P0/P2 阶段根据已确认的 Room V1、DataStore 和 Drift Schema 生成二进制测试数据库，二进制 `.db` / `.sqlite` 不直接提交。

| 场景 | 目的 | 核心断言 |
|---|---|---|
| `room_v1_empty` | 首次启动与空库迁移 | 0 条交易、默认账本和分类可创建 |
| `room_v1_basic` | 基础收支迁移 | 记录数、收入、支出和结余一致 |
| `room_v1_budget` | DataStore 预算迁移 | 总预算与分类预算完整迁移 |
| `room_v1_deleted_category` | 已引用分类处理 | 分类转为禁用而不是破坏历史交易 |
| `room_v1_large` | 一万条交易性能 | 迁移完成且汇总准确、耗时可记录 |
| `sync_single_device` | 单设备 Outbox | 重试幂等、不产生重复交易 |
| `sync_two_devices` | 双设备增量同步 | Push/Pull/Cursor 收敛 |
| `sync_conflict` | 同一交易并发修改 | 使用冻结的冲突规则得到确定结果 |
| `sync_offline_delete` | 离线删除后重连 | `deleted_at` 正确传播且不复活 |
| `corrupted_backup` | 损坏备份恢复 | 拒绝恢复、原库不被覆盖、可回滚 |

所有 UUID、金额、备注、日期和设备标识均为固定虚构值，禁止从真实用户数据库复制。
