# FastAPI 生产运行手册

参考 `infra/docker/compose.production.yaml`。TLS 只由 Nginx 暴露 80/443；PostgreSQL 与 API 不映射公网端口。所有 `:?required` 环境变量来自服务器 Secret 管理，不写 `.env` 到 Git。

启动前：配置独立高熵 JWT secret/identity pepper/internal metrics token，腾讯和微信 Provider、Kimi key、PostgreSQL 密码、review 开关；证书覆盖 `www.znjz.site`。Production 启动会拒绝 Fake Provider、开发 secret、非 HTTPS public URL 和不安全数据库配置。

部署：先做数据库快照，拉取固定提交，`docker compose ... config`，运行 Alembic upgrade，检查 live/ready，再切流量。失败时回滚应用镜像；数据库只按已验证 downgrade/前向修复方案处理，不盲目回退。

备份：每日加密 `pg_dump`，至少保留 30 天并异地复制；每月至隔离环境恢复并记录 RPO/RTO。监控 HTTPS、live/ready、5xx、认证失败率、Provider 延迟、数据库空间/连接、备份新鲜度；日志按 request_id 检索且禁止手机号、code、token、secret、AI/图片正文。

当前 `https://www.znjz.site:443` 拒绝连接，未取得服务器/证书/Provider 凭据，因此本文件只代表部署准备，不代表已生产上线。
