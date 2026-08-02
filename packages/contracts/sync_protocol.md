# 同步协议草案

## Push
每条 Outbox 操作包含 operation_id、entity_type、entity_id、operation、base_version、payload、device_id、occurred_at。服务端按 operation_id 幂等处理。

## Pull
客户端携带 cursor，服务端返回该 cursor 之后的变更和 next_cursor。

## 删除
通过 deleted_at 和版本号传播，禁止同步前直接物理删除。

## 冲突
同一实体并发修改必须通过版本/CAS 检测，不得静默丢弃本地变更。
