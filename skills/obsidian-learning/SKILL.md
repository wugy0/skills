---
name: obsidian-learning
description: 在 Obsidian 知识库中执行「目标→采集→研究→课程→练习→复习」的完整学习闭环，产出 Markdown 原生的 mission/moc/source/concept/lesson/practice/learning-record/glossary/diagram 笔记。用户说"教我、带我学、开始学习 X、把这个主题整理进知识库、做学习计划、复习安排"时使用；也负责把网页/资料提炼成可复习的概念笔记并安排间隔复习。只要求目标目录是遵循 PARA 的 Obsidian Vault（含 01-Inbox、02-Areas、03-Projects、04-Resources、99-Templates），不依赖任何第三方插件。
---

# Obsidian Learning：Markdown 原生的学习编排

在指定的 Obsidian Vault 内组织学习：从「为什么学」到「已掌握并可复述」全程用 Markdown 笔记记录，用双链织成知识网络，用 MOC 导航，用检索练习和间隔复习保证长期记忆。

本 skill 自带完整方法论：一手资料优先、证据链与交叉验证、先提纲后展开；以及目标驱动、短课、回忆练习、实践反馈、间隔复习。它不依赖任何其他学习类 skill，也不生成 HTML 课程；所有产物都是 Obsidian 原生 Markdown。

## 何时使用

- 用户说「教我 / 带我学 / 系统学习 X / 把 X 整理进知识库」
- 用户给出网页、PDF、代码或想法，要求整理成可复习的学习笔记
- 需要制定学习目标、课程路线、练习或复习计划
- 需要根据已学内容判断下一步教什么（Zone of Proximal Development）

## 核心原则

1. **Markdown 是事实来源**。每个结论可追溯到 `source` 笔记；不确定就明说，不把推测写成事实。
2. **知识与学习状态分离**。知识笔记（source/concept/glossary）记录"它是什么"；状态笔记（mission/lesson/practice/learning-record）记录"我学到哪了"。
3. **状态只由证据更新**。看过 ≠ 掌握。只有练习、自测或真实使用证明了，才更新 `mastery` / `status`。
4. **难度是工具**。用检索练习（先回忆再看答案）与间隔复习（`review_after`）构建长期记忆，不用"反复阅读"制造虚假的流畅感。
5. **少即是多**。每条笔记一个主题；元数据最小化；普通 Markdown 可读性是第一优先级，Obsidian 特性是增强。

## 开始一个新学习项目

用户给出目标后，按此流程（详见 `references/learning-workflow.md`）：

1. **建档**：先澄清，再写 `mission` 笔记——为什么学、可观察的成功标准、约束、范围外内容。Mission 不清则不开始采集。
2. **采集**：来源进 `01-Inbox/` 或建 `source` 笔记，保留来源链接与获取日期。
3. **研究提炼**：把来源消化为 `concept` / `glossary` / `source` 笔记，用双链互连，矛盾显式保留。
4. **课程**：基于 mission 与已有概念，规划 MOC 课程路线，写短小 `lesson` 笔记（一个目标 + 例子 + 自测 + 练习）。
5. **实践与复习**：`practice` 笔记记录实验与证据；按 `review-method` 安排复习，更新 `learning-record`。
6. **整理**：把 Inbox 归位、更新 `_MOC.md`。不自动移动、删除或提交 Git。

一次教学会话通常只产出 1–3 条笔记，且必须落在用户当前的最近发展区内——多问一句「这个对你是不是太简单/太难」，胜过盲目推进。

## 笔记类型与数据契约

九种类型，通过 `type` 属性区分，公共属性见 `references/note-types.md`：

| type | 职责 |
| --- | --- |
| `mission` | 为什么学、目标、成功标准、约束 |
| `moc` | 领域 / 课程导航入口（`_MOC.md`） |
| `source` | 原始资料与引用元数据 |
| `concept` | 一个独立概念的权威解释 |
| `lesson` | 一节可短时完成的课，含自测 |
| `practice` | 练习、实验、错误与证据 |
| `learning-record` | 掌握情况、薄弱点、复习安排 |
| `glossary` | 术语定义（全局唯一） |
| `diagram` | Excalidraw / Mermaid 图示的说明页 |

所有新笔记必须包含最小 frontmatter：

```yaml
---
title: ""
type: mission | moc | source | concept | lesson | practice | learning-record | glossary | diagram
status: draft | active | archived
tags: []
aliases: []
created: YYYY-MM-DD
---
```

`review_after`、`mastery`、`confidence`、`prerequisites`、`source_notes` 等属性按类型补充（见 note-types.md）。新笔记一律先 `draft`，完成后改 `active`，不再维护改 `archived`。

## Vault 路由

遵循 PARA 变体约定：

```text
00-Home.md        # 首页枢纽
01-Inbox/         # 未整理采集物
02-Areas/         # 长期领域
03-Projects/      # 有目标的学习项目
04-Resources/     # 来源、官方文档
05-Archive/       # 归档
99-Templates/     # 模板
```

- 明确知道归属的内容直接进对应目录；不确定的进 `01-Inbox/`。
- 一个学科技能（如嵌入式、V4L2）建 `02-Areas/<领域>/_MOC.md`；一个有截止目标的学习计划建 `03-Projects/<项目>/`。
- 每次新增笔记后，同步检查所属 `_MOC.md` 是否需要补入口。
- 路由细节见 `references/vault-routing.md`。

## 写笔记的硬性规则

- **概念笔记**：一个概念一篇；用通俗语言先讲清"是什么、为什么、怎么用"；结尾列来源与相关概念双链。
- **课程笔记**：短（约 3–5 分钟读完）；结构为目标、前置知识、正文、自测、练习；自测答案用折叠 Callout 收纳。
- **结论要有出处**：事实性说法通过 `source` 笔记或来源 URL 标注；两个来源矛盾时并列记录，不悄悄选一个。
- **证据优先**：`practice` / `learning-record` 只记录真实发生的实验、错误、可观察结果，不写想象。
- **术语进 glossary**：一旦出现新术语，写或更新 `glossary` 笔记，之后所有笔记使用同一术语。

## 复习与间隔

- 每条 `lesson` / `concept` 设定 `review_after`；用 `learning-record` 记录每次复习结果（对/错、信心）。
- 复习时先尝试回忆，再展开答案 Callout 核对，立即记录结果。
- 间隔建议（可随表现调整）：第 1 天 → 第 3 天 → 第 7 天 → 第 21 天 → 第 60 天。卡的题目缩短间隔，轻松的拉长。
- 方法依据与出处见 `references/review-method.md`。

## Excalidraw / 图示

- `diagram` 笔记是图示的说明页（用途、要点、来源），Markdown 中的文字说明是事实来源。
- Excalidraw 仅用于文字难以表达的图：概念关系、学习路线、架构、时序、对比。
- 未安装 Excalidraw 插件时，用 Mermaid 或普通 Markdown 表格代替。
- 具体约定见 `references/excalidraw-conventions.md`。

## 边界（不做的事）

- 不把特定项目的知识写进本 skill（它们属于用户 Vault 的内容）。
- 不把交互式 quiz 塞进笔记——用折叠 Callout 自测（Obsidian 无法运行 HTML quiz）。
- 不强求 Dataview / Templater / 任何第三方插件。
- 不硬编码 Vault 路径：工作目录就是 Vault，或由用户显式指定。

## Verification

- 新建笔记有合法 frontmatter（`title` / `type` / `status` / `created`），标题层级正确。
- 双链可解析：指向的概念、来源、MOC 均存在；无指向空白的链接。
- 对应 `_MOC.md` 已包含新入口。
- 结论型句子都能追溯到来源；矛盾已显式标注。
- 复习流：`learning-record` 反映真实练习结果，`review_after` 已按表现更新。
- 观察用户在 Obsidian 中打开笔记无渲染错误（frontmatter / Callout / Mermaid）。

## References

- [学习工作流](references/learning-workflow.md)
- [笔记类型与属性契约](references/note-types.md)
- [Vault 路由规则](references/vault-routing.md)
- [复习方法（含研究依据）](references/review-method.md)
- [Excalidraw 图示约定](references/excalidraw-conventions.md)
