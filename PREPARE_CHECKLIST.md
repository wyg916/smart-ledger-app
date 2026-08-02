# 开发前准备清单

## 1. 先做备份
- 保留 `E:\移动端开发\记账统计` 原目录，不在原目录直接重构。
- 将原目录压缩备份到其他磁盘。
- 记录旧 APK、数据库 Schema 和关键文件哈希。

## 2. 新仓库根目录
推荐使用：`E:\移动端开发\smart-ledger-app`

不要把空 GitHub 仓库直接初始化在旧项目目录，避免新旧工程混杂。

## 3. 复制旧项目
复制到 `legacy/android-kotlin/`，排除 `.git`、构建缓存、IDE 目录、local.properties、.env、签名文件、真实数据库、日志和用户备份。

## 4. 放入需求文件
放在 `docs/00_requirements/`：PRD、数据库设计、技术架构、7 日计划、原双端方案、UI 原型和截图。

## 5. 首次提交前检查
```powershell
cd "E:\移动端开发\smart-ledger-app"
git status --short
git ls-files
```

重点确认没有密码、Token、证书、私钥、签名、真实数据库、真实账单和 build 目录。

## 6. 首次提交
建议提交信息：
`chore: establish smart ledger project baseline`

## 7. 交给 Codex
先执行 `CODEX_FIRST_PROMPT.md`；P0 评审通过后再执行 `CODEX_SECOND_PROMPT.md`。不要第一条任务就要求七天全部开发和上线。
