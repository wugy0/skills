---
name: embedded-sdk-vscode-navigation
description: Configure a practical VS Code navigation environment for a large embedded Linux SDK, including Linux kernel, U-Boot, Buildroot, OpenWrt, Kconfig, Makefiles, shell build scripts, generated .config files, and DeviceTree sources. Use this skill whenever the user wants Ctrl+click/F12 navigation for CONFIG_* or Make variables, asks to configure Universal Ctags, Ctags Companion, ctagsx, VS Code DeviceTree support (dts-lsp / KyleMicallefBonnici.dts-lsp), Kconfig/Makefile navigation, or wants a maintainable .code-workspace setup for a vendor SoC Linux SDK — even if they do not mention this skill explicitly.
---

# Embedded SDK VS Code Navigation

Set up navigation for a vendor SDK without indexing generated output or making
project-private assumptions. The useful split is:

- **Ctags Companion + Universal Ctags**: Kconfig symbols, Make variables and
  targets, and shell functions.
- **dts-lsp** (`KyleMicallefBonnici.dts-lsp`): DTS/DTSI syntax, includes,
  bindings, and semantic navigation. Prefer it over ctags for DeviceTree.
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
  (prefer `KyleMicallefBonnici.dts-lsp`; see §6)

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

Use a dedicated DeviceTree language server instead of ctags for DTS/DTSI.
Prefer **`KyleMicallefBonnici.dts-lsp`** (a full LSP with go-to-definition/
references, hover, diagnostics, completions, formatting). Plain syntax-only
alternatives such as `andy9a9.vscode-devicetree` are acceptable when you only
need highlighting and no semantic navigation, but dts-lsp is the better default
for navigation and validation.

### Configuration keys

dts-lsp is configured under the `devicetree.*` keys (dotted, flat in `settings`):

- `devicetree.cwd` — base directory; most other paths are resolved against it.
  In a multi-root workspace use `${workspaceFolder:<folderName>}` variables
  (they work and keep the config portable — no hardcoded home paths).
- `devicetree.defaultIncludePaths` — directories searched for `#include` of
  `.dtsi` and `dt-bindings/*.h`/C headers.
- `devicetree.defaultBindingType` — `Zephyr` (default) or `DevicetreeOrg`
  (experimental; for Linux kernels).
- `devicetree.defaultZephyrBindings` — Zephyr binding YAML dirs.
- `devicetree.defaultDeviceOrgTreeBindings` — Devicetree.org binding schema
  dirs (e.g. the kernel's `Documentation/devicetree/bindings`).
- `devicetree.defaultDeviceOrgBindingsMetaSchema` — optional dt-schema
  `meta-schemas` dir (usually empty; dt-schema is a separate checkout).
- `devicetree.contexts` / `preferredContext` — explicit contexts (see below).

### Linux kernel example

```jsonc
// ${workspaceFolder:kernel} expands to the kernel workspace-root path;
// verified to work in dts-lsp and keeps the config portable
"devicetree.cwd": "${workspaceFolder:kernel}",
"devicetree.defaultIncludePaths": [
    "${workspaceFolder:kernel}/arch/arm/boot/dts",
    "${workspaceFolder:kernel}/arch/arm64/boot/dts/rockchip",
    "${workspaceFolder:kernel}/include"          // for dt-bindings/*.h
],
"devicetree.defaultBindingType": "DevicetreeOrg",
"devicetree.defaultDeviceOrgTreeBindings": [
    "${workspaceFolder:kernel}/Documentation/devicetree/bindings"
],
"devicetree.defaultDeviceOrgBindingsMetaSchema": []
```

Include paths must cover where the actual dtsi files live and where the
`dt-bindings/*.h` headers are. For a Rockchip board the active arch matters:
check `RK_ARCH` / `RK_KERNEL_DTS` in the SDK `BoardConfig*.mk` to pick
`arch/arm*/boot/dts/...` correctly.

### Multi-root workspace gotcha (important)

In a **multi-root `.code-workspace`**, dts-lsp does **not** reliably resolve
devicetree settings from a per-folder `kernel/.vscode/settings.json`; the
server log shows the cwd falling back to the main workspace root and
`includePaths` coming back empty (default `Zephyr` binding). Put the
`devicetree.*` settings in the **workspace file's top-level `settings`** block
(global, folder-independent), not in a sub-folder `.vscode/settings.json`.

### Multiple SDKs (kernel + uboot) with explicit contexts

The global `devicetree.defaultIncludePaths`/`cwd` are a **single** set, so they
cannot serve two SDKs with different dts layouts at once (e.g. kernel and
U-Boot). Define one explicit context per SDK: each context carries its own
`cwd`, `dtsFile`, `includePaths`, and `bindingType`, and the server picks the
context whose `dtsFile` include-graph matches the opened file (`allowAdhocContexts`
stays true as a fallback). `dtsFile` is relative to the context `cwd`.

```jsonc
"devicetree.contexts": [
    {   // kernel
        "ctxName": "kernel",
        "cwd": "${workspaceFolder:kernel}",
        "dtsFile": "arch/arm64/boot/dts/rockchip/rv1126b-xiaoyu-50ipc-v10.dts",
        "includePaths": [
            "${workspaceFolder:kernel}/arch/arm64/boot/dts/rockchip",
            "${workspaceFolder:kernel}/arch/arm/boot/dts",
            "${workspaceFolder:kernel}/include"
        ],
        "bindingType": "DevicetreeOrg",
        "deviceOrgTreeBindings": [
            "${workspaceFolder:kernel}/Documentation/devicetree/bindings"
        ],
        "deviceOrgBindingsMetaSchema": []
    },
    {   // U-Boot: dtsi under u-boot/arch/arm/dts, dt-bindings under u-boot/include
        "ctxName": "uboot",
        "cwd": "${workspaceFolder:uboot}/u-boot",
        "dtsFile": "arch/arm/dts/rv1126b-evb.dts",   // CONFIG_DEFAULT_DEVICE_TREE
        "includePaths": [
            "${workspaceFolder:uboot}/u-boot/arch/arm/dts",
            "${workspaceFolder:uboot}/u-boot/include"
        ],
        "bindingType": "DevicetreeOrg",
        "deviceOrgTreeBindings": [
            "${workspaceFolder:kernel}/Documentation/devicetree/bindings"
        ],
        "deviceOrgBindingsMetaSchema": []
    }
]
```

Tips:
- U-Boot has no bindings docs of its own; point its `deviceOrgTreeBindings` at
the kernel's `Documentation/devicetree/bindings`.
- Find the U-Boot anchor dts from `CONFIG_DEFAULT_DEVICE_TREE` in the uboot
`configs/*defconfig` (e.g. `rv1126b-evb` -> `arch/arm/dts/rv1126b-evb.dts`).
- Keep the global defaults as a kernel fallback for ad-hoc contexts.

### Diagnose when it does not work

- After editing settings, **reload the window** (`Developer: Reload Window`).
- Open the **Output** panel (`Ctrl+Shift+U`) and pick the **DTS Language
  Server** channel. The `Resolved settings` / context block shows exactly which
  `cwd`, `includePaths`, and `bindingType` the server actually used — if they
  are defaults/empty, the config is not being read (see the multi-root gotcha
  above). Confirm the `${workspaceFolder:<name>}` variables resolved to real
  paths, and that the opened file matched the intended context's include
  graph.
- `DevicetreeOrg` bindings are experimental; if the diagnostics noise outweighs
  the value, drop `defaultBindingType` and the bindings dirs to keep only
  syntax/node/label navigation.

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
