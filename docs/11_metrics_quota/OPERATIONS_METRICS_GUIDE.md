# 运营指标与 AI 配额运维指南

适用范围：P1E2 认证用户指标、内部运营查看和 AI 配额。正式口径与禁止项分别以
`P1E2_USER_METRICS_CONTRACT.md` 和 `P1E2_AI_QUOTA_CONTRACT.md` 为准。

## 1. 权限与数据边界

设置独立的 `INTERNAL_METRICS_TOKEN`，它不能复用 Kimi Key、App Access Token、审核账号或 Provider
凭据。Production 缺少该值时应用启动 fail-closed。Token 只放 `Authorization: Bearer` Header，
不得进入 URL、日志、脚本参数、Git 或导出文件。

正式 DAU 以内部 UUID `user_id` 去重。默认所有接口只查询 `authenticated`；P1D 旧数据只能在
overview 显式传 `identity_scope=anonymous_legacy` 单独查看，不能与正式 DAU 相加或混合去重。

运营数据不含业务账单、金额、账户/分类/备注、手机号、微信身份、AI 问题/回答/Prompt、图片、
Token 或 Provider Secret。遇到需要这些内容的排障请求，应停止并改用客户端本地诊断流程。

## 2. 最小运营查看

开发 Compose 使用 Fake Provider，并在空库启动时自动执行 `alembic upgrade head`：

```bash
docker compose -f infra/docker/compose.yaml up -d --build
docker compose -f infra/docker/compose.yaml ps
```

聚合 HTML 页固定展示最近 30 天 DAU/WAU/MAU、新用户、安装、AI 成功率、配额拦截、Token、
D1/D7、趋势和主要维度：

```bash
curl --fail --show-error \
  -H "Authorization: Bearer $INTERNAL_METRICS_TOKEN" \
  http://127.0.0.1:8000/internal/metrics
```

不要把带凭据的响应转存到仓库。生产环境必须通过受控 HTTPS 和运维身份代理访问。

## 3. 指标 API

所有接口前缀为 `/api/v1/internal/metrics`：

| 路径 | 用途 |
|---|---|
| `/overview` | DAU/WAU/MAU、安装、session、登录/记账/AI 漏斗与 D1/D7 摘要 |
| `/timeseries` | 日期粒度的活跃、安装和 session 趋势 |
| `/dimensions?dimension=...` | 固定 allowlist 的维度分布 |
| `/retention` | cohort D1/D7；未成熟 cohort 返回 null |
| `/ai-usage` | 调用、成功/失败、Token、延迟、成本与错误分类 |
| `/ai-quota` | 拦截、日/周触达与高用量用户数 |

日期可用 `days=1|7|30` 或 `start_date/end_date`，闭区间最多 400 天。筛选可组合：
`platform`、`android_version`、`app_version`、`application_id`、`auth_provider`、`user_type`、
`release_channel`、`feature`、`network_type`、`ai_feature`、`ai_status`、`error_type`、`model`。
未知维度和非法枚举返回 422，不支持任意列名、任意 JSON 或任意 SQL。

示例只读取聚合值：

```bash
curl --fail --show-error \
  -H "Authorization: Bearer $INTERNAL_METRICS_TOKEN" \
  "http://127.0.0.1:8000/api/v1/internal/metrics/overview?days=7&auth_provider=phone_one_click"
```

## 4. 可重复导出

脚本从环境变量读取内部凭据，不会输出身份或财务内容：

```bash
SMART_LEDGER_METRICS_BASE_URL=http://127.0.0.1:8000 \
  scripts/product_metrics_report.py --days 30 --format console

scripts/product_metrics_report.py \
  --start-date 2026-08-01 --end-date 2026-08-05 \
  --format json --output /tmp/smart-ledger-metrics.json

scripts/product_metrics_report.py --days 7 --format csv \
  --output /tmp/smart-ledger-metrics.csv
```

导出文件只允许进入受控临时目录或运营系统，不得提交 Git。分享前复核无内部 UUID 或额外字段。

## 5. 口径 QA

每次版本发布或埋点变更至少核对：

1. 同用户两个 session：active users/DAU 仍为 1，sessions 为 2。
2. 同用户两个 installation：active users 为 1，active installations 为 2。
3. 登录失败只增加登录失败，不增加正式 DAU。
4. overview 的 AI calls/success 与 `ai-usage` 对齐；quota blocked 与 `ai-quota` 对齐。
5. 默认 overview 不出现 anonymous legacy；显式 legacy 查询必须标注 UTC 口径。
6. D1/D7 未成熟 cohort 为 null，不显示 0%。
7. 页面、JSON 和 CSV 不出现手机号、微信身份、账单/备注或 AI 正文。

## 6. 配额与成本运维

free 为 2/日、10/周；review 和 internal_test 也必须是有限值。计划只由服务端配置，Flutter 无切换
入口。价格通过 `AI_MODEL_PRICING_JSON` 维护，只接受受控模型的 prompt/completion 每百万 Token
价格；未配置模型成本显示 0，不得从 AI 正文推算。

排查配额时优先看聚合 `ai-quota` 和状态计数，不读取用户问题。发现 reservation 长时间不释放，先
确认 `AI_RESERVATION_TTL_SECONDS`，再触发一次 quota 查询或受控运维请求使 10 分钟回收逻辑运行。
不得手工把 used 归零。时区更新有冷却，当前使用量会带入新周期，活动 reservation 会阻止更新。

## 7. 保留与删除

显式执行清理任务：

```bash
cd services/api
uv run python scripts/prune_metrics.py
```

默认删除 90 天前原始事件和 400 天前聚合；任务只输出删除行数。先备份和验证配置，禁止用清库、
重建数据库或放宽账号删除契约代替保留策略。

## 8. 故障处理

- 401：检查 Header 和独立内部凭据是否配置；不要临时匿名开放接口。
- 422：检查日期、维度或固定枚举；不要扩展为自由查询。
- 指标不一致：按 source grain 核对 user/session/installation 与日期时区，停止发布错误报表。
- AI 配额异常：核对 plan、daily/weekly counter、reservation 状态和 request id 唯一性，不读取正文。
- Telemetry 不可用：保持本地记账可用；Flutter 有限队列稍后重试，不能用同步上传业务账单补偿。

P1E 仍是 PARTIAL。本指南不代表真实 Provider、生产部署、正式签名、真机矩阵或商店上线已完成。
