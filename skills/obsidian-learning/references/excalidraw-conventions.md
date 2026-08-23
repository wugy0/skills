# Excalidraw 图示约定

Excalidraw 是**可选增强**，不是知识库的一部分：Markdown 笔记与双链是事实来源，
图示只是可视化。

## 何时用图

只在这些场景值得动手画（文字/表格说不清时）：

- 概念关系图（哪些概念依赖哪些）
- 学习路线图（先学什么后学什么）
- 系统架构图 / 数据流 / 时序图
- 对比图（A vs B）
- 调试流程图

没有 Excalidraw 插件时的降级方案（按优先级）：

1. Mermaid（Obsidian 内置渲染）——流程、时序、类图
2. 普通 Markdown 表格 / 列表——对比、步骤
3. 纯文字

## 文件与嵌入

- 图示文件使用 Obsidian Vault 中 Excalidraw 插件已配置的格式（通常 `*.excalidraw.md`），**不手写序列化内容**：绘制工作由用户或插件生成，Agent 只处理说明与骨架文本。
- 每条图示搭配一条 `diagram` 笔记：图表达什么、关键要点（纯文字）、来源链接。
- 在概念 / 课程笔记中用 `![[foo.excalidraw.md]]` 嵌入图，并在下方补一句文字说明。

## 硬性规则

1. **图不承载唯一知识**：图中所有关键结论在对应 Markdown 里都有文字版和来源。
2. **来源可追溯**：`diagram` 笔记的 `source_notes` 指向 `source` 笔记或 URL。
3. **不追美观**：先保证信息准确、结构清晰；配色和布局是用户的自由。
4. **增量绘制**：建议先画草图确认结构，再补充细节；改动大时先问用户。

## diagram 笔记模板

```yaml
---
title: DMA 数据流图
type: diagram
status: active
drawing: "[[dma-dataflow.excalidraw.md]]"
source_notes: ["[[芯片手册 TRM 第 3 章]]"]
created: YYYY-MM-DD
---

这张图表达什么：DMA 描述符链在内存与外设间的流动。

关键要点：
- 描述符由软件初始化，硬件消费后回写状态。
- 半满/全满中断两个水位。

来源：[[芯片手册 TRM 第 3 章]] · [[DMA|DMA 概念]]
```
