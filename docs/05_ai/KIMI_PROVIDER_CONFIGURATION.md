# Kimi Provider 配置

状态：P1D 本地开发配置
更新日期：2026-08-03

## 安全原则

- 真实 Key 只保存在 `services/api/.env` 或部署系统的秘密存储中，不进入 Flutter、Dart
  define、源码、日志、截图、文档、Compose 或 GitHub Actions。
- `.env` 已被 Git 忽略；本机文件权限应为 `600`。`.env.example` 只保留占位值。
- Flutter 只接收 FastAPI 地址；Provider Key 永远不下发客户端。
- 当前没有用户认证，`production` 环境下所有生成接口 fail-closed。

## 环境变量

| 变量 | 建议值 | 说明 |
|---|---|---|
| `MOONSHOT_API_KEY` | 仅本地秘密 | Moonshot/Kimi 凭据 |
| `KIMI_BASE_URL` | `https://api.moonshot.cn/v1` | 国内 OpenAI 兼容 API |
| `KIMI_FAST_MODEL` | `kimi-k2.6` | 月度总结、预算解释 |
| `KIMI_REASONING_MODEL` | `kimi-k2.6` | 财务规划；可在模型可用性复核后覆盖 |
| `KIMI_AI_ENABLED` | `true`/`false` | 总开关，默认关闭 |
| `KIMI_PROVIDER` | `kimi`/`fake` | 本地真实调用或 CI 合成 Provider |
| `KIMI_LIVE_TEST` | `false` | 真实 smoke 显式开关，默认关闭 |

2026-08-03 受控 `/v1/models` 仅返回 `kimi-k2.6`、`kimi-k2.7-code`，未返回 K3；因此
当前快速和规划场景均使用 `kimi-k2.6`，并关闭 thinking。不得把 coding 模型自动当作财务
规划模型。将来如模型清单变化，先受控查询再显式修改环境变量。

## 本地启动

```bash
cd services/api
cp .env.example .env
# 在终端编辑 .env；不要把 Key 粘贴进命令历史或 Codex 提示词
chmod 600 .env
uv sync --frozen
uv run uvicorn app.main:app --host 127.0.0.1 --port 8001

cd ../../apps/mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001
```

Android release 已声明 `INTERNET` 权限。网络安全配置默认禁止明文流量，只为模拟器宿主
地址 `10.0.2.2` 和 `localhost` 开放本地 HTTP；正式服务必须使用 HTTPS。

## 状态与真实 smoke

`GET /api/v1/ai/status` 只返回开关、Provider、模型名、配置就绪和生产可用性，不返回 Key。

```bash
cd services/api
KIMI_LIVE_TEST=true uv run python -m scripts.kimi_smoke

# 仅复核一个场景：monthly_summary / budget_review / financial_plan
KIMI_LIVE_TEST=true KIMI_SMOKE_SCENARIO=financial_plan \
  uv run python -m scripts.kimi_smoke
```

smoke 只输出模型 ID、HTTP/结构校验状态、耗时和 token 数；不输出请求正文、模型回答、
内部推理或 Key。测试和 CI 始终使用 `KIMI_PROVIDER=fake` 且 `KIMI_LIVE_TEST=false`。

## 故障处理

- `AI_NOT_CONFIGURED`：检查服务进程是否读到秘密存储；不要在状态接口或日志打印 Key。
- `AI_UPSTREAM_AUTH_ERROR`：停止重试，检查 Key 权限/状态。
- `AI_RATE_LIMITED`：客户端保留本地结果并稍后重试。
- `AI_UPSTREAM_TIMEOUT`：客户端 40 秒终止并展示本地结果；服务端只做一次受控重试。
- `AI_INVALID_RESPONSE`：同模型最多修复一次，仍失败则降级，不把原始响应透传客户端。
