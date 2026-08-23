---
name: obsidian-knowledge-base
description: Manage a Git-synced Obsidian knowledge base — PARA vault structure, note frontmatter (tags/title/aliases), wiki links ([[...]]), Map-of-Content (_MOC.md) hubs, and a Git+GitHub commit/push workflow. Use whenever the user wants to add or organize a note, create an area/project/MOC/index note, apply an Obsidian template, review vault structure, or commit & sync the vault — even if they don't name the skill explicitly.
---

# Obsidian 知识库管理

管理一个「Obsidian + Git + GitHub」的知识库：结构（PARA）、笔记规范（frontmatter / 双链 / MOC）、
以及同步工作流（中文 Conventional Commits + push）。本 skill 面向可复用的知识库管理，
vault 路径作为参数传入（默认示例为 `~/knowledge`）。

## When to Use

- 用户要新增/整理/归位一条笔记
- 用户要新建领域（Area）、项目（Project）、MOC、索引或模板
- 用户要回顾或调整 vault 结构
- 用户要提交并推送知识库（commit + push 到 GitHub）
- 用户问 Obsidian 的命名/双链/frontmatter 约定

## Vault 结构（PARA 变体）

```
00-Home.md          # 首页 / MOC 枢纽
01-Inbox/           # 临时收集，未整理
02-Areas/           # 长期领域（嵌入式、Linux、V4L2…）
03-Projects/        # 按项目组织的笔记
04-Resources/       # 参考资料、链接、术语
05-Archive/         # 归档
99-Templates/       # Obsidian 模板
```

原则：新想法先进 `01-Inbox`，整理后归入 Areas/Projects/Resources；宁可晚归档，
不可随手乱放。

## 笔记规范

> Obsidian 标记语法（双链、嵌入、Callout、属性等）的详细规则见独立安装的 `obsidian-markdown` skill 与官方文档（help.obsidian.md）；本 skill 只约定结构、元数据与同步流程。

- **YAML frontmatter**（每条笔记顶部）：

  ```yaml
  ---
  tags: [v4l2, course, learning]
  title: 第 1 课 · …
  aliases: [别名…]
  ---
  ```

- **双链**：用 `[[笔记名]]` 或 `[[路径/笔记|显示名]]` 关联；领域内固定用 `[[../_MOC|返回地图]]`。
- **MOC**（Map of Content）：每个 Area 建 `_MOC.md` 作为入口，汇总该领域索引与关键链接。
- **分类索引**：一个领域的多条记录，建一个「索引」笔记用双链列出全部（如 `学习记录.md`、`课程目录.md`）。
- **模板**：放 `99-Templates/`，Obsidian「模板」插件指向该目录；模板用 `{{title}}`/`{{date}}` 占位。

## 新增 / 整理笔记流程

1. 判断归属：新想法 → `01-Inbox`；已有归属 → 对应 Areas/Projects/Resources。
2. 按模板新建笔记，填 frontmatter 与正文，用双链关联相关笔记。
3. 整理时更新对应 `_MOC.md` / 分类索引（增补入口）。
4. 提交前检查，再 `commit` + `push`（见下）。

## Git 同步工作流

- 提交信息用**中文 Conventional Commits**：`feat:` / `fix:` / `docs:` / `chore:` 等 + 中文摘要。
- 提交前必须：`git status`、`git diff`、`git diff --check`（无空白错误）。
- **未经用户明确确认，不得** `git add` / `commit` / `push` 或删除文件；展示改动后等确认。
- 推送：`git push` 到 GitHub 私有仓库做异地备份 / 多机同步。

## 注意事项 / Pitfalls

- `.obsidian/workspace.json` / `workspace-mobile.json` 是机器相关的窗口布局，**不入库**（已在 `.gitignore`）；其余 `.obsidian` 配置（app/core-plugins/plugins）可入库以多机同步。
- 删除文件或清空目录属不可逆操作，先询问用户。
- 空目录 git 不跟踪：若要保留结构，用 `.gitkeep`。
- HTML 课程/讲义要进知识库时，先转成 Obsidian 友好的 Markdown 再放入，不要直接塞 HTML。
- 交互式 HTML quiz 无法在 Obsidian 运行，需转成可折叠自测题（`> [!success]`）或静态问答。

## Verification

- 新笔记有合法 frontmatter、标题层级、双链能解析到目标。
- MOC / 索引把新内容纳入了对应入口。
- `git status` 干净、`git diff --check` 无输出、`git push` 成功且远端包含改动。
- 用 Obsidian 打开 vault 无 frontmatter 报错，graph view 能看到新节点与连线。
