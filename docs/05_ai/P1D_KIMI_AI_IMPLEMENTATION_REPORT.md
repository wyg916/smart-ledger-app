# P1D Kimi AI Lite 实现报告

状态：本地与 Android 门禁通过，等待分支/主线 CI 关闭
日期：2026-08-03
分支：`p1d/kimi-ai-lite`
起点：`c8c656be20a4322cca94c70451f0798099b926f0`

## 结论

P1D 已完成三条本地确定性数据 → FastAPI → Kimi → 严格结构化结果 → Flutter 展示/降级的
垂直闭环。真实 Key 未进入仓库、客户端、Compose、日志或截图。AI 不读取原始账单、不改账，
失败时本地记账、预算、统计和历史数据继续可用。

用户追加的体验要求也已纳入：AI 语气改为温柔知性、甜美但克制；默认分类扩至 14 个支出
和 8 个收入；Flutter 使用奶油黄、珊瑚、薄荷绿的统一 Material 3 主题与原创“零钱精灵”；
当前 13 个路由页面均有成套 UI 参考图。

## 实现范围

- FastAPI：Provider Protocol、Fake/Kimi Provider、三类 strict DTO、状态与生成接口、统一错误、
  请求体限制、结构化输出、Pydantic 二次校验、一次修复、一次网络重试、非敏感日志。
- Flutter：三场景请求工厂/API Client/Riverpod 状态/页面/结果与失败面板；只发送聚合 DTO；
  `API_BASE_URL` 编译期注入；release Android 网络权限和本地 HTTP 白名单。
- 本地数据：22 个固定 ID 内置分类通过 `insertOrIgnore` 增量补齐，不覆盖老用户停用状态、
  自定义分类、交易或预算。
- 视觉：全局 design tokens、圆角卡片、首页快捷入口、分类图标、AI 小伙伴和温柔失败文案；
  参考图见 `docs/05_ai/ui_references/`。

## 自动化结果

| 门禁 | 结果 |
|---|---|
| Ruff format/lint | PASS |
| mypy | PASS |
| FastAPI pytest | 26/26 PASS |
| Flutter format/analyze | PASS |
| Flutter tests | 52/52 PASS |
| Flutter 行覆盖率 | 2,986 / 6,606，45.20% |
| Release APK | PASS；61,480,250 字节 |
| APK SHA-256 | `7ad3552fc42029d5c0131a254682001e343b52698b0771e8b0ab42405b03fa9e` |
| Compose config/up/health | PASS（合入前复跑） |
| Repository secret scan | tracked 0；history 0；`.env` ignored，mode 600 |

## 真实 Kimi 受控验证

模型清单为 `kimi-k2.6`、`kimi-k2.7-code`；K3 不可用，所以三场景均显式路由到
`kimi-k2.6`，关闭 thinking。输出仅记录非敏感元数据：

| 场景 | 状态 | 延迟 | prompt/completion/total tokens |
|---|---:|---:|---:|
| 月度总结（最终自然中文提示词） | PASS | 18,019 ms | 501 / 384 / 885 |
| 预算解释 | PASS | 16,769 ms | 295 / 376 / 671 |
| 财务规划（单场景复核） | PASS | 26,543 ms | 333 / 569 / 902 |

全部通过 JSON Schema 与 Pydantic。一次财务规划受控尝试按预期超时，随后单场景重试通过；
没有无限重试，也没有输出 prompt、正文或 reasoning content。

## Android 34 ARM64 现场验收

- 使用 `adb install -r` 更新 release APK；first install 保持 `2026-08-03 22:24:19`，最终
  last update 为 `2026-08-03 23:48:33`。
- 冷启动后既有收入 100.00、工资分类、净额 100.00 保留；预算 500.00、已用 0、剩余
  500.00 保留。
- 22 个内置分类在真机 UI 可见，图标、颜色和启停控件正常。
- 月度、预算、规划三类真实 API 已现场成功；最终月度回答为自然中文、无内部字段名。
- 无服务、HTTP 429、40 秒客户端超时均显示明确温柔降级条，本地金额与上一份结果保留。
- 最终 logcat：FATAL/crash 0、ANR 0、SQLite/migration error 0、Key 候选 0。

说明：本 AVD 在本轮开始时没有可证明的历史 P1C 新包状态；因此先通过真实 UI 创建合成收入
和预算基线，再用两次 `adb install -r` 与冷启动证明 P1D 更新不清库。未声称处理真实用户数据。

## 待关闭门禁

- 普通推送 P1D 分支并等待 Flutter、FastAPI、Repository Safety 全部通过。
- 确认 `main` 未分叉后只做 fast-forward；普通推送 main 并等待适用主线 CI。
- 把最终工程 SHA 与 CI Run ID 回填本报告和 `CURRENT_STATE.md`，再宣布 P1D 关闭。
- `IOS_TOOLCHAIN = BLOCKED`；不声称 iOS 构建或发布通过。
