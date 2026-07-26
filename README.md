# agent-skills

我的个人 AI agent skill 仓库，遵循 [Agent Skills](https://agentskills.io) 开放规范，
可用 [`npx skills`](https://github.com/vercel-labs/skills) 安装管理，兼容 pi、Claude Code、
Cursor、Codex 等 40+ agent。

## 安装

```bash
# 安装全部 skill（全局，进用户目录，跨项目可见）
npx skills add wugy0/skills -g

# 只装某一个
npx skills add wugy0/skills@cross-compile-dev-setup -g

# 升级指定 skill
npx skills update cross-compile-dev-setup -g -y
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

本仓库是唯一真相源。维护本仓库的开发机上，Pi 的全局 skill 目录应软链接至
本仓库，因此改动立即对 Pi 生效：

```bash
ln -sfn ~/work/skills/skills/cross-compile-dev-setup \
  ~/.pi/agent/skills/cross-compile-dev-setup
```

在其他机器上，`npx skills` 会按 agent 选择用户级安装目录；对 Pi，安装目标是
`~/.pi/agent/skills/`。此类消费端在 pull 新版本后执行：

```bash
npx skills update cross-compile-dev-setup -g -y
```

维护机不要执行该更新命令，以免它将软链接替换为独立副本。
