# 发给 Codex 的第一条任务

你现在接管仓库 `wyg916/smart-ledger-app`。

本次只执行 **P0：项目事实审计、基线冻结与可执行开发入口建立**，不要直接开发完整 App，不要部署生产环境。

## 必须先阅读
1. 根目录 `AGENTS.md`
2. `README.md`
3. `docs/00_requirements/` 内全部文档
4. `docs/01_baseline/CURRENT_STATE.md`
5. `docs/02_architecture/DECISIONS.md`
6. `docs/03_delivery/ACCEPTANCE_CRITERIA.md`
7. `legacy/android-kotlin/` 旧 Android 项目

## 本次目标
1. 核实仓库、分支、提交和工作树状态。
2. 全面审计旧 Android 项目：工程结构、技术版本、构建方式、applicationId、签名引用、页面功能、Room、DataStore、备份恢复、应用锁、测试和敏感信息。
3. 在不改变旧业务行为的前提下执行可用构建、格式检查和测试。
4. 更新 `CURRENT_STATE.md` 和 `LEGACY_INVENTORY.md`。
5. 建立后续开发所需但不含业务实现的最小目录与占位说明。
6. 形成 `docs/01_baseline/P0_AUDIT_REPORT.md`。
7. 若安全合理，创建仅含基线和文档的本地 commit；未经授权不得 push。

## 强制约束
- `legacy/android-kotlin/` 默认只读。
- 不删除、移动或覆盖旧项目原文件。
- 不提交密码、Token、证书、签名文件、真实数据库或真实财务数据。
- 不把“未验证”写成“已完成”。
- 缺少环境时记录准确阻断，不伪造结果。
- 不连接或修改生产服务器和生产数据库。
- 本次不实现 Flutter 页面、云同步、AI、登录或后端业务。

## 最终输出
1. 结论：PASS / PARTIAL / FAIL。
2. 仓库与环境基线。
3. 旧项目完整事实清单。
4. 实际执行命令及结果。
5. 敏感信息处理状态（不得复述秘密值）。
6. 阻断、风险和未决策项。
7. 修改文件清单。
8. 本地 commit SHA（如有）。
9. 下一阶段唯一推荐任务。
