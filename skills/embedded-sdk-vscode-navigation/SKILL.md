---
name: embedded-sdk-vscode-navigation
description: Configure a practical VS Code navigation environment for a large embedded Linux SDK, including Linux kernel, U-Boot, Buildroot, OpenWrt, Kconfig, Makefiles, shell build scripts, generated .config files, and DeviceTree sources. Use this skill whenever the user wants Ctrl+click/F12 navigation for CONFIG_* or Make variables, asks to configure Universal Ctags, Ctags Companion, ctagsx, VS Code DeviceTree support, Kconfig/Makefile navigation, or wants a maintainable .code-workspace setup for a vendor SoC Linux SDK — even if they do not mention this skill explicitly.
---

# Embedded SDK VS Code Navigation

Set up navigation for a vendor SDK without indexing generated output or making
project-private assumptions. The useful split is:

- **Ctags Companion + Universal Ctags**: Kconfig symbols, Make variables and
  targets, and shell functions.
- **DeviceTree extension**: DTS/DTSI syntax, includes, bindings, and semantic
  navigation. Prefer it over ctags for DeviceTree.
- **Language servers**: C/C++ and Python navigation. Do not try to replace
  clangd or a language server with ctags.

Ctags is a text index, not a build-system evaluator. It can take
`CONFIG_FOO` in `.config` to a `config FOO` definition, but it does not resolve
Kconfig dependencies, Make conditionals, shell expansion, or the active build
configuration.

## 1. Inspect before changing settings

Identify:

1. The SDK root and whether it is a Git repository.
2. Workspace layout: prefer one root workspace. Nested multi-root folders are
   useful for Explorer organization, but Ctags Companion executes `readtags`
   from the active folder, which complicates a shared tag-file path.
3. Source roots and generated directories. Never index build output, staging
   trees, downloads, prebuilt toolchains, or generated `.config` files.
4. The active architecture. Indexing every Linux/U-Boot architecture creates
   duplicate `CONFIG_*` symbols and makes navigation ambiguous.

Use `git rev-parse --show-toplevel` from the SDK root when available. Do not
hard-code a developer's home directory in a reusable workspace file.

## 2. Install and verify tools

Install these in the **same VS Code environment** that opens the remote SDK
(for example, the SSH remote extension host):

- Universal Ctags
- Ctags Companion (`gediminaszlatkus.ctags-companion`)
- a DeviceTree extension appropriate for the project

Verify both Ctags executables are on `PATH`:

```bash
ctags --version
readtags --version
```

`readtags` ships with Universal Ctags. Do not install Exuberant Ctags as a
substitute: it lacks the modern parser/features expected here. If `ctags` is
available but `readtags` is not, fix the installation or put the matching
Universal Ctags bin directory on `PATH` before configuring Companion.

Disable ctagsx or any other extension that registers a Definition Provider;
two providers produce duplicate or inconsistent Ctrl+click results.

## 3. Create a selective tag generator

Copy `assets/update-tags.sh` into the SDK as `.vscode-ctags/update-tags.sh`,
make it executable, and adapt only its source-root variables and active
architectures. It indexes:

- Makefiles (`Makefile`, `GNUmakefile`, `*.mk`, `*.mak`)
- shell scripts and shell functions
- Linux and U-Boot Kconfig files for one active architecture
- Buildroot/OpenWrt `Config.in*` and `Kconfig*`
- `.buildconfig`-style exported build variables using the Make parser

It excludes generated directories and writes a sorted `.tags` at the SDK root.
Run the generator manually after Kconfig/Makefile changes; do not enable a
watcher over a large vendor SDK.

Why the parser choices matter:

- Universal Ctags' Kconfig parser writes both `FOO` and `CONFIG_FOO` entries,
  enabling `.config` -> Kconfig navigation.
- Buildroot/OpenWrt call their Kconfig files `Config.in*`, so extend the
  Kconfig filename map.
- The shell parser tags functions but not exported variables. Parsing
  `.buildconfig` with the Make parser provides variable definitions while the
  VS Code language mode remains `shellscript` for editing.

## 4. Configure Ctags Companion

Ctags Companion uses `readtags` for F12/Ctrl+click, `Ctrl+T` workspace symbols,
and Ctags for the current-file Outline. It needs line numbers plus explicit,
long kind names:

```jsonc
{
  "ctags-companion.command": "bash .vscode-ctags/update-tags.sh",
  "ctags-companion.documentSelector": {
    "scheme": "file",
    "pattern": "**/{Makefile,GNUmakefile,*.mk,*.mak,Kconfig,Kconfig.*,Config.in,Config.in.*,*.sh,*.SH,*.bash,*.bsh,*.ksh,*.ash,.buildconfig,.config,*defconfig}"
  },
  "ctags-companion.readtagsGoToDefinitionCommand": "readtags -t .tags -A -en",
  "ctags-companion.readtagsGoToSymbolInWorkspaceCommand": "readtags -t .tags -A -enpi",
  "ctags-companion.ctagsGoToSymbolInEditorCommand": "ctags --fields=+nKz -f -"
}
```

This configuration assumes a **single SDK-root workspace folder**, so `.tags`
is found from Companion's current working directory. `-A` returns absolute
paths and prevents duplicated paths while opening definitions.

### Nested multi-root workspaces

Ctags Companion does not expand VS Code variables such as `${workspaceFolder}`
in its command strings; it passes the configured command to the shell. For a
multi-root workspace, choose one of these approaches:

1. Preferably, retain only the SDK root as a workspace folder; use Explorer
   favourites or file nesting instead of nested workspace roots.
2. Create a `tags`/`.tags` symlink in every nested workspace root pointing to
   the SDK-root tag file, then use `readtags -t .tags ...`.
3. Use a project-specific wrapper that locates a root marker before invoking
   `readtags`. Keep the wrapper in the SDK rather than embedding an absolute
   path in the shared skill.

After modifying settings, reload the VS Code window. Test all three surfaces:

- F12/Ctrl+click on `CONFIG_FOO` in C, `.config`, or a defconfig
- `Ctrl+Shift+O` for current-file symbols
- `Ctrl+T` for workspace symbols

## 5. Workspace file associations and JSONC formatting

Associate generated configuration files only for readable editing; this does
not change how Ctags Companion resolves definitions:

```jsonc
{
  "files.associations": {
    "**/.buildconfig": "shellscript",
    "**/.config": "properties",
    "**/*defconfig": "properties"
  },
  "files.exclude": { "**/.tags": true },
  "files.watcherExclude": { "**/.tags": true },
  "search.exclude": { "**/.tags": true }
}
```

`properties` is VS Code's simple `KEY=value` language mode. It gives `.config`
files basic highlighting but does not understand Kconfig.

A `.code-workspace` file is JSONC, not strict JSON: comments are allowed.
Prefer VS Code's built-in formatter for hand-maintained JSONC and preserve
compact existing arrays/objects:

```jsonc
{
  "json.format.keepLines": true,
  "[json]": {
    "editor.defaultFormatter": "vscode.json-language-features",
    "editor.formatOnSave": false,
    "editor.tabSize": 2
  },
  "[jsonc]": {
    "editor.defaultFormatter": "vscode.json-language-features",
    "editor.formatOnSave": false,
    "editor.tabSize": 2
  }
}
```

Prettier is useful when a repository mandates it, but `printWidth` is only a
soft target and it may expand short JSON structures. Do not add Prettier merely
to obtain compact JSONC.

## 6. Configure DeviceTree separately

Use the DeviceTree extension's workspace configuration to point at the kernel
and bootloader headers/bindings. Typical settings have this shape:

```jsonc
{
  "devicetree.cwd": "${workspaceFolder}",
  "devicetree.defaultIncludePaths": [
    "kernel/include",
    "bootloader/include"
  ],
  "devicetree.defaultBindingType": "DevicetreeOrg",
  "devicetree.defaultDeviceOrgTreeBindings": [
    "kernel/Documentation/devicetree/bindings",
    "bootloader/Documentation/devicetree/bindings"
  ]
}
```

Check the installed extension's setting names rather than blindly copying the
example: vendor forks and extension versions differ. Do not add DTS/DTSI to the
ctags generator unless the DeviceTree extension is unavailable.

## 7. Verify and maintain

Before calling the setup complete:

```bash
bash -n .vscode-ctags/update-tags.sh
shellcheck .vscode-ctags/update-tags.sh
ctags --version
readtags --version
```

Generate tags once manually, then verify representative entries without relying
on the editor:

```bash
readtags -t .tags -A -en CONFIG_FOO
readtags -t .tags -A -en A_MAKE_VARIABLE
readtags -t .tags -A -en shell_function_name
```

Keep `.tags` and any `tags` symlinks Git-ignored. Commit the generator and
workspace configuration only if the project wants team-shared editor setup.
Never commit generated tags, build outputs, active `.config` files, paths to a
specific developer home directory, credentials, or toolchain artifacts.
