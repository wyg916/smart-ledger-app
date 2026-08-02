# 架构决策记录

## 已冻结
| 编号 | 决策 | 状态 |
|---|---|---|
| ADR-001 | Flutter 单代码库交付 Android/iOS | 已确认 |
| ADR-002 | Riverpod + Drift/SQLite | 已确认 |
| ADR-003 | FastAPI + PostgreSQL + Alembic | 已确认 |
| ADR-004 | 本地优先，云同步可选 | 已确认 |
| ADR-005 | Outbox + Push/Pull + Cursor + UUID | 已确认 |
| ADR-006 | AI 仅做问答、总结和规划，不建设 RAG/Agent/记忆系统 | 已确认 |
| ADR-007 | App 不直接连接 PostgreSQL | 已确认 |
| ADR-008 | 首版不强制使用 Redis | 已确认 |

## 待确认
| 编号 | 问题 | 影响 | 截止节点 |
|---|---|---|---|
| OPEN-001 | 是否存在真实存量用户 | 是否需要桥接版本 | P0 |
| OPEN-002 | 正式包名和签名是否可用 | 是否可原地升级 | P0 |
| OPEN-003 | 首发商店范围 | 登录和合规材料 | P0 |
| OPEN-004 | 正式域名和 API 域名 | HTTPS 和 App 配置 | P1 |
| OPEN-005 | AI 模型供应商 | 接口、成本和隐私披露 | P3 |
