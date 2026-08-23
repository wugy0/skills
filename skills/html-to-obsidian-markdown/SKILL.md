---
name: html-to-obsidian-markdown
description: Convert HTML teaching material / course pages into Obsidian-friendly Markdown — headings, bold/code inline, code blocks, tables, callout boxes (→ [!note]), and interactive quizzes (→ collapsible self-test callouts). Use whenever the user wants to turn an HTML lesson, doc page, or course file into a native Obsidian note for a knowledge base, especially when the source uses <div class="callout"> or <div class="quiz">.
---

# HTML → Obsidian Markdown 转换

把教学型 HTML（如课程讲义）转成 Obsidian 原生 Markdown：标题、加粗/行内代码、
代码块、表格、callout、自测题，并加 frontmatter 与双链导航。

## When to Use

- 用户要把 HTML 课程/讲义/文档页转成 Obsidian 笔记
- 源文件包含 `<div class="callout">`（提示框）或 `<div class="quiz">`（交互自测）
- 想保留教学结构（标题、表格、代码、闪卡）而不丢内容

## Procedure

1. **看源结构**：`grep -oE '<[a-z0-9]+' file.html | sort | uniq -c` 看有哪些标签，
   重点确认是否存在 `callout` / `quiz`。
2. **用 assets/html2md.py 转换**（stdin 参数为文件路径）：
   ```bash
   python3 html2md.py <input.html>      # 产出同名 <input>.md
   ```
3. **检查输出**：
   - 无未配对 `**` 或 `` ` ``（可脚本统计奇数次的行）。
   - 表格分隔行正确（`| --- |`），无多余空单元格。
   - callout 变成 `> [!note]`，quiz 变成可折叠 `> [!success]-` 自测题（含答案与解析）。
   - 本地相对链接（`../sysdrv/...` 等）已丢弃、只留锚文本，避免坏链接。
4. **加 frontmatter 与双链**：脚本已加 `tags`/`title` 并带上一篇/下一篇/返回 MOC 的
   `[[双链]]` 导航（`COURSE_ORDER` 需按实际课程序列表填写）。
5. **归位**：放入 vault 对应 `02-Areas/…/课程/`，在 `_MOC.md` / 课程目录索引中补入口。
6. 若要删除源 HTML，先征得用户确认（属不可逆操作）。

## 转换映射

| HTML | Obsidian Markdown |
|---|---|
| `<h1>` | 由 frontmatter `title` + `# ` 替代（抑制重复） |
| `<h2>/<h3>` | `## ` / `### ` |
| `<b>/<strong>` | `**…**` |
| `<code>` | `` `…` `` |
| `<pre>` | ```` ``` ```` 代码块 |
| `<table>` | Markdown 表格（表头 + 分隔行） |
| `<div class="callout">` | `> [!note]`（`data-type`/`data-title` 映射） |
| `<div class="quiz">` | `> [!success]- 答案与解析` + 选项清单 + 正确答案标记 ✅ |
| `<a href>`（本地路径） | 只留锚文本（路径不解析，避免坏链接） |
| `<a href>`（http） | 普通 Markdown 链接 |

## Pitfalls

- 表格/quiz 内的 `<b>`/`<code>` 标记会泄漏成孤立的 `**`/`` ` ``，转换器需在表格与
  quiz 上下文中忽略行内标记（脚本已处理）。
- 有序列表计数若从 0 开始，需确保从 1 递增。
- `<head>`/`<title>`/`<script>` 内容要抑制，否则标题重复或脚本文本泄漏。
- 段落内硬换行要折叠为单个空格（`re.sub(r"\s+", " ", …)`），否则 Obsidian 出现断行。
- HTML 引用的 `../assets/*`（样式/脚本）在 vault 中若无 Markdown 等价物，要么一并迁移
  保持相对路径，要么在去掉 HTML 后清理（确认无其它文件引用再删）。

## Verification

- 输出 `.md` 有合法 frontmatter、标题、表格、代码块、callout、自测题。
- 无未配对标记；`git diff --check` 无空白错误。
- Obsidian 打开正常渲染，双链可跳转，quiz 折叠可展开。
