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

## 3. Generate a selective tag script for this SDK

Do **not** copy a fixed script from this skill. First inspect the SDK's actual
source roots, generated directories, active architectures, and configuration
file conventions. Then create a project-local generator only for the useful
kinds of navigation the user requested.

Common candidates are:

- Makefiles (`Makefile`, `GNUmakefile`, `*.mk`, `*.mak`)
- shell scripts, when shell-function navigation is useful
- Linux and U-Boot Kconfig files for one active architecture
- Buildroot/OpenWrt `Config.in*` and `Kconfig*`, when those trees are present
- a `.buildconfig`-style file only when it exists and its exported variables
  need navigation

Exclude generated outputs, staging trees, downloads, and prebuilt toolchains.
Write a sorted `.tags` at the SDK root and run the generator manually after
Kconfig/Makefile changes; do not enable a watcher over a large vendor SDK.

Why the parser choices matter:

- Universal Ctags' Kconfig parser writes both `FOO` and `CONFIG_FOO` entries,
  enabling `.config` -> Kconfig navigation.
- Buildroot/OpenWrt call their Kconfig files `Config.in*`, so extend the
  Kconfig filename map only when those trees are indexed.
- The shell parser tags functions but not exported variables. If a
  `.buildconfig` file needs variable navigation, parse that one file with the
  Make parser while keeping its VS Code language mode as `shellscript`.

Build the script incrementally. First benchmark each source category using a
temporary tag file. If `ctags` consumes CPU without updating the final tags
file, it may be stuck in a parser: bisect the input list, exclude the exact
third-party file, document the reason in the project script, and preserve all
other inputs. Add a `TAGS_FILE` override so full verification can write a
temporary output instead of replacing the working `.tags`.

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

## 5. Keep unrelated editor policy out of this skill

This skill configures code navigation only. Do not add generic JSON/JSONC
formatting, Prettier, whitespace, theme, or unrelated workspace preferences
unless the user explicitly asks for them. File associations are optional and
should be added only when they materially improve the requested navigation or
readability.

## 6. DeviceTree

Use a dedicated DeviceTree extension instead of ctags for DTS/DTSI. For
`andy9a9.vscode-devicetree`, install it in the same local or remote VS Code
environment as the SDK; no generic workspace configuration is required. Add
extension-specific settings only after verifying that a particular SDK's include
or binding lookup fails.

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
