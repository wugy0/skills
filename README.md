# agent-skills

我的个人 AI agent skill 仓库，遵循 [Agent Skills](https://agentskills.io) 开放规范，
可用 [`npx skills`](https://github.com/vercel-labs/skills) 安装管理，兼容 pi、Claude Code、
Cursor、Codex 等 40+ agent。

## 安装

```bash
# 安装全部 skill（全局，进用户目录，跨项目可见）
npx skills add <github-user>/agent-skills -g

# 只装某一个
npx skills add <github-user>/agent-skills@cross-compile-dev-setup -g

# 升级已安装的
npx skills update
```

不加 `-g` 会装到当前项目的 `.agents/skills/`。

## Skill 列表

| Skill | 用途 |
|---|---|
| [`cross-compile-dev-setup`](skills/cross-compile-dev-setup/SKILL.md) | 嵌入式 Linux 交叉编译开发工作流：CMake preset + qemu-user 测试 + GoogleTest + compile_commands + .clangd |

## 目录约定

```
skills/
└── <skill-name>/
    ├── SKILL.md          # 必需：frontmatter(name/description) + 指令
    ├── references/       # 按需加载的深度文档
    └── assets/           # 模板、脚本等可拷贝资源
```

新增 skill：在 `skills/` 下建目录并放 `SKILL.md` 即可被 CLI 自动发现。

## 本地开发

本仓库即唯一真相源。本地 `~/.agents/skills/` 下的副本是安装产物，
改动请回到本仓库，push 后用 `npx skills update` 同步。
