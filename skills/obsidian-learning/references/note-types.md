# 笔记类型与属性契约

九种笔记类型，通过 `type` 属性区分。每类笔记只承担一个职责。

## 公共属性（所有笔记）

```yaml
---
title: ""            # 人类可读标题，允许中文
type: concept        # 见下表
status: draft        # draft | active | archived
tags: []             # 可搜索标签
aliases: []          # 别名，用于双链建议
created: YYYY-MM-DD  # 创建日期
---
```

- 新笔记一律 `draft`；内容完成后改 `active`；停止维护改 `archived`。
- `created` 用 `YYYY-MM-DD` 格式，便于排序与筛选。

## 类型总览

| type | 一句话职责 | 通常位置 |
| --- | --- | --- |
| `mission` | 为什么学、成功标准、约束 | `02-Areas/<领域>/` 或 `03-Projects/<项目>/` |
| `moc` | 领域 / 课程导航入口 | 各目录的 `_MOC.md` |
| `source` | 原始资料与其元数据 | `04-Resources/来源/` |
| `concept` | 一个独立概念 | 所属 Area / Project |
| `lesson` | 一节可短时完成的课 | 所属 Area / Project 下 |
| `practice` | 练习、实验、错误与证据 | 所属 Area / Project 下 |
| `learning-record` | 掌握情况、薄弱点、复习安排 | 所属 Area / Project 下 |
| `glossary` | 术语定义（全局唯一） | `04-Resources/术语/` 或 Area 内 |
| `diagram` | 图示的说明页 | 与图示同目录 |

## 按类型补充的属性

### source

```yaml
type: source
source_url: https://example.com   # 原始链接
source_kind: doc | blog | video | paper | code | book
accessed: YYYY-MM-DD              # 获取日期
confidence: medium                # high | medium | low
```

正文结构：概述 → 关键论点（每条可加 `^block-id` 便于被引用）→ 与使命的相关性 → 疑问。

### concept

```yaml
type: concept
source_notes: ["[[source-xxx]]"]  # 结论的来源
prerequisites: []                 # 学它之前需要先懂的概念
review_after: YYYY-MM-DD          # 下一次复习
confidence: medium
```

正文结构：是什么 → 为什么 → 怎么用 → 常见误区 → 来源与相关概念。一个概念一篇。

### lesson

```yaml
type: lesson
mission: "[[mission-xxx]]"        # 服务于哪个使命
concepts: ["[[concept-a]]"]       # 本课涉及的概念
review_after: YYYY-MM-DD
```

正文结构：目标 → 前置知识 → 正文（约 3–5 分钟）→ 自测（折叠 Callout）→ 练习。
自测答案必须收在折叠 Callout 里，先回忆再展开。

### practice

```yaml
type: practice
lesson: "[[lesson-xxx]]"          # 关联的课
outcome: unknown                  # unknown | success | partial | failed
review_after: YYYY-MM-DD
```

正文只记录真实发生的：做了什么 → 观察到什么 → 错在哪 → 证据 → 下一步。
不写想象中的结果。

### learning-record

```yaml
type: learning-record
mastery: 1                        # 0–5，0=未接触，5=可教别人
evidence: "[[practice-xxx]]"      # 支撑该等级的实践证据
review_after: YYYY-MM-DD
```

每次复习后更新：结论（对/错）、信心、下次复习日期。**没有证据不升级 mastery。**

### glossary

```yaml
type: glossary
aliases: [别名们]                 # 术语的其他叫法
```

一句话定义 + 链接到相关概念。全局同一术语只维护一条笔记，
之后所有笔记一律使用该术语名。

### diagram

```yaml
type: diagram
drawing: "[[foo.excalidraw.md]]"  # 图示文件（若存在）
source_notes: []
```

正文：这张图表达什么 → 关键要点（纯文字）→ 来源。
文字说明是事实来源，图只是可视化。

### mission

见「学习工作流」第 1 节。

### moc

```yaml
type: moc
```

正文是入口列表：领域下的概念、课程、资源、学习记录，全部用双链列出并可维护顺序。

## 例子：最小但完整的 concept 笔记

```markdown
---
title: 直接内存访问（DMA）
type: concept
status: active
tags: [embedded, memory]
aliases: [DMA]
created: 2024-01-15
source_notes: ["[[芯片手册 TRM 第 3 章]]"]
prerequisites: ["[[内存映射 I/O]]"]
review_after: 2024-01-18
---

DMA 允许外设绕过 CPU 直接读写内存……

## 常见误区
- DMA 不提高总线带宽，只释放 CPU。
- 缓存一致性必须由驱动处理。 ^dma-cache-coherency

来源：[[芯片手册 TRM 第 3 章]]#^dma-cache-coherency
相关：[[内存映射 I/O]] · [[中断处理]]
```
