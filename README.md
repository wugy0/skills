# Skills

可复用的 [Agent Skills](https://agentskills.io) 集合，遵循开放的 `SKILL.md` 格式。
每个 skill 都可以包含工作流、脚本、模板与按需加载的参考资料，可由
[`npx skills`](https://github.com/vercel-labs/skills) 安装到 pi、Claude Code、Codex、
Cursor 等兼容的 agent。

## 安装

```bash
# 全局安装仓库中的全部 skill
npx skills add wugy0/skills -g

# 只安装一个 skill
npx skills add wugy0/skills@cross-compile-dev-setup -g

# 更新已安装的 skill
npx skills update cross-compile-dev-setup -g -y
```

省略 `-g` 会将 skill 安装到当前项目，适合将工作流与项目配置一起管理。

## 可用 Skill

| Skill | 说明 |
| --- | --- |
| [`cross-compile-dev-setup`](skills/cross-compile-dev-setup/SKILL.md) | 为嵌入式 Linux 应用建立 CMake 交叉编译开发流程：preset、qemu-user 测试、GoogleTest、`compile_commands.json` 与 `.clangd`。 |
| [`embedded-sdk-vscode-navigation`](skills/embedded-sdk-vscode-navigation/SKILL.md) | 为大型嵌入式 Linux SDK 配置 VS Code 导航：Universal Ctags/Ctags Companion、Kconfig、Makefile、Shell、`.config` 与 DeviceTree。 |
| [`obsidian-knowledge-base`](skills/obsidian-knowledge-base/SKILL.md) | 管理 Git 同步的 Obsidian 知识库：PARA 结构、frontmatter/双链/MOC 规范、中文 Conventional Commits + push 工作流。 |
| [`obsidian-learning`](skills/obsidian-learning/SKILL.md) | 在 Obsidian 知识库内执行学习闭环：目标→采集→研究→课程→练习→复习，Markdown 原生笔记 + MOC + 间隔排期，Excalidraw 图示可选，独立运行、不依赖其他学习类 skill。 |

## 目录结构

```text
skills/
└── <skill-name>/
    ├── SKILL.md          # 必需：frontmatter 与工作流说明
    ├── references/       # 按需加载的详细资料
    └── assets/           # 脚本、模板或其他可复用资源
```

新增 skill 时，在 `skills/` 下建立目录并提供有效的 `SKILL.md`。提交前应确认
frontmatter 至少包含 `name` 与 `description`，并验证所附脚本和模板可用。

## 贡献

欢迎通过 issue 或 pull request 提交改进。请保持 skill 聚焦于可复用能力，避免加入
特定机器路径、凭据、个人配置或项目私有流程。
