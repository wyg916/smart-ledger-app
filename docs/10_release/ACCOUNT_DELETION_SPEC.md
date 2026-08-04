# 账号删除规格

入口：`账号与安全 → 注销账号`。客户端必须二次确认，并让用户选择“删除当前账号本机账本”或“保留隔离文件”。

1. `deletion-request` 使用客户端 UUID 幂等键创建请求。
2. `deletion-confirm` 只接受当前用户的请求与明确 `DELETE` 确认。
3. 服务端撤销所有 session/refresh token，删除认证身份和 review 绑定，把用户标记为 deleted，并将 Telemetry `user_id` 置空；保留去标识化安全审计。
4. 客户端先清除会话使按用户 Drift 实例关闭，再按选择删除 SQLite、WAL、SHM 和绑定决定文件。
5. 重复请求返回同一语义结果；状态可由 `deletion-status` 查询。网络失败保持登录并允许重试，服务端确认成功后本地删除失败不得恢复服务端身份。

公开页面：`https://www.znjz.site/account-deletion`。工程目标处理时间 7 个自然日，正式承诺需与法律和运营流程一致。
