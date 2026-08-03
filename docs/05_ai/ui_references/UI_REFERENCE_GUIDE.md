# P1D UI 参考图与生成记录

生成日期：2026-08-03
用途：Flutter 后续逐页视觉实现参考，不是可直接切图的生产资源。

## 设计语言

- 奶油底 `#FFF8E8`、纸白 `#FFFDF8`、珊瑚 `#E97867`、薄荷 `#56B6A3`、蜂蜜黄
  `#F4BF4F`、深可可文字 `#3C332E`。
- Material 3、22px 大圆角、8pt 间距、清晰金额层级、少阴影、足够留白。
- 原创“零钱精灵”：圆形薄荷色零钱伙伴、点状眼睛、微笑、腮红和小金币。只作陪伴，
  不覆盖数据；明确避开参考图中的猫、鲨鱼、鲸鱼、鱼或任何品牌角色。
- AI 文案温柔知性、甜美但克制；失败状态不制造焦虑，同时保留明确风险和本地结果。

## 页面覆盖

| 文件 | 覆盖页面/状态 |
|---|---|
| `01_core_ledger_flow.png` | 我的⼩账本、记一笔（新增/编辑共用）、账单详情 |
| `02_accounts_categories.png` | 账户管理/新增账户、分类管理支出/收入、新增分类 |
| `03_analytics_budgets.png` | 统计分析、预算管理、新建/编辑预算、预算详情 |
| `04_ai_companion.png` | AI 小伙伴、月度总结、预算解释、财务规划、加载/离线提示 |

6 张用户参考图均已人工查看；生成器单次最多接收 5 张，因此每张参考板选择首页、存钱、
统计和智能记账等信息互补的 5 张作为风格输入。只提取配色、圆角、信息层级与轻卡通氛围。

## 原始生成提示词

### 01 核心记账流程

```text
Use case: ui-mockup.
Create a polished 16:9 product-design reference board for a Chinese Flutter personal finance app, showing THREE complete Android phone screens side by side at equal scale. This is board 1: 核心记账流程.
Screen 1 exact title: “我的小账本”. Include a friendly warm header, month selector, three summary cards labeled “收入 / 支出 / 净额”, five quick actions “AI陪伴 / 统计 / 预算 / 账户 / 分类”, filters, transaction list, and coral “记一笔” floating button.
Screen 2 exact title: “记一笔”. Include income/expense/transfer segmented control, large amount entry, category icon grid with common categories, account selector, date, note, and a strong coral “保存” button.
Screen 3 exact title: “账单详情”. Include category icon, amount, type, account, date/time, note, and restrained edit/delete actions.
Visual direction inspired only by the references: warm cream and soft honey background, clean white rounded cards, coral pink primary accents, mint green and pale blue secondary accents, dark cocoa typography, generous whitespace, crisp modern Flutter/Material 3 hierarchy. Add a SMALL ORIGINAL mascot called “零钱精灵”: a round mint coin-shaped helper with two dot eyes, a tiny smile, rosy cheeks and a small golden ¥ coin; it must be an original character and must not resemble or copy any cat, shark, whale, fish, or branded mascot from the references. Use it sparingly in headers/empty state, never covering data.
High-fidelity app UI, feasible production layout, consistent 8pt spacing, accessible contrast, no black poster bars, no marketing poster headlines, no hands or device mockup frames. Show Chinese UI text clearly, avoid gibberish, avoid overcrowding, no logos, no watermarks.
```

### 02 账户与分类

```text
Use case: ui-mockup.
Create a polished 16:9 product-design reference board for the SAME Chinese Flutter finance app and exact design system as the previous board. Show THREE complete Android phone screens side by side. This is board 2: 账户与分类.
Screen 1 exact title “账户管理”: a balance summary card, enabled accounts such as “现金 / 工资卡 / 微信钱包 / 支付宝”, each with colorful icon, account type, current balance and gentle enabled switch; coral floating add button. Include a neat bottom-sheet/dialog reference for “新增账户” with name, account type, opening balance.
Screen 2 exact title “分类管理”, selected segment “支出”: show a clean, scrollable two-column grid or compact list of 14 expense categories: 餐饮, 交通, 购物, 住房, 日用, 娱乐, 医疗, 教育, 通讯, 水电燃气, 人情礼物, 旅行, 宠物, 其他支出. Each has a distinct friendly icon and small enabled control.
Screen 3 exact title “分类管理”, selected segment “收入”: show 8 income categories: 工资, 其他收入, 奖金, 兼职, 理财收益, 报销, 红包礼金, 退款; include an “新增分类” modal preview.
Visual system: warm cream background, clean white large rounded cards, coral primary, mint and pale blue secondary, honey yellow highlights, dark cocoa typography, refined Material 3, generous whitespace and accessible contrast. Include the same SMALL ORIGINAL “零钱精灵”, a round mint coin-shaped helper with dot eyes, tiny smile, rosy cheeks and a small golden ¥ coin. It must not resemble or copy any cat, shark, whale, fish, or branded reference character. Use sparingly.
High-fidelity production-feasible UI, consistent spacing, no device frames, no poster headline, no black bars, no logos/watermarks. Chinese labels should be readable and accurate, no gibberish, no overcrowding.
```

### 03 统计与预算

```text
Use case: ui-mockup.
Create a polished wide product-design reference board for the SAME Chinese Flutter finance app and design system. Show FOUR complete slender Android phone screens side by side with readable content. This is board 3: 统计与预算闭环.
Screen 1 exact title “统计分析”: month selector; three cards 收入/支出/净额; a clear coral-mint daily trend chart; category ranking with icon, amount, percent and horizontal bars; account balance section. Use real-looking CNY example numbers but no impossible precision.
Screen 2 exact title “预算管理”: month selector; total budget progress hero card labeled 总预算, 已用, 剩余; category budget cards with progress bars and status chips “进行中 / 接近上限 / 已超支”; coral “新建预算” button.
Screen 3 exact title “新建预算”: segmented scope “总预算 / 分类预算”, month, category selector, integer-safe amount input, simple helpful validation message, large “保存预算” button.
Screen 4 exact title “预算详情”: circular or linear progress visualization, budget/used/remaining/overrun deterministic amounts, linked category, edit button, gentle explanatory copy. Keep AI out of this screen.
Visual system: warm cream background, clean white large rounded cards, coral primary, mint and pale blue secondary, honey highlights, dark cocoa type, refined Material 3, strong chart legibility and accessible contrast. Include the same SMALL ORIGINAL “零钱精灵”, a round mint coin helper with dot eyes, tiny smile, rosy cheeks and a small golden ¥ coin, only in one or two non-data areas. It must not resemble/copy any cat, shark, whale, fish, or branded mascot.
Production-feasible UI, consistent 8pt spacing, no device frames, no poster headline, no black bars, no logos/watermarks. Chinese labels should be readable and accurate, no gibberish, no overcrowding.
```

### 04 AI 小伙伴

```text
Use case: ui-mockup.
Create a polished wide product-design reference board for the SAME Chinese Flutter finance app and design system. Show FOUR complete slender Android phone screens side by side. This is board 4: 温柔知性的 AI 陪伴.
Screen 1 exact title “AI 小伙伴”: welcoming header with the original mint coin helper and warm line “想看懂哪一部分呢？”, privacy note “只读取本地聚合，不查看原始账单”; three large entry cards “月度消费总结 / 预算执行解释 / 财务规划建议” with distinct coral, mint and honey icons.
Screen 2 exact title “月度消费总结”: clearly separate a deterministic summary card (收入/支出/净额 and month) from an AI result card. AI card starts “给你整理好啦”, includes short warm summary, 2 insights with evidence, 2 gentle next actions, “温柔提醒” and a discreet disclaimer. Include generate/retry control.
Screen 3 exact title “预算执行解释”: deterministic budget/used/remaining/overrun card, progress bar, then AI explanation with supportive but honest tone; never hide overspending; include action steps and disclaimer.
Screen 4 exact title “财务规划建议”: approachable form for 目标名称/目标金额/当前金额/每月投入/目标期限/风险偏好, a deterministic monthly gap card, and a warm structured AI result preview. Include small compact references for loading and offline fallback at the bottom: “正在认真整理…” and “本地结果仍可使用”.
Tone and copy: gentle, knowledgeable, sweet but restrained; supportive, non-judgmental, never childish, never vague about risk.
Visual system: warm cream, white rounded cards, coral primary, mint/pale blue secondary, honey highlights, dark cocoa type, Material 3, excellent content hierarchy. Same SMALL ORIGINAL “零钱精灵”: round mint coin helper, dot eyes, tiny smile, rosy cheeks, small golden ¥ coin; do not resemble/copy any cat, shark, whale, fish, or branded mascot. Use sparingly and never over data.
Production-feasible UI, consistent 8pt spacing, no device frames, no poster headline, no black bars, no logos/watermarks. Chinese labels readable and accurate, no gibberish, no overcrowding.
```
