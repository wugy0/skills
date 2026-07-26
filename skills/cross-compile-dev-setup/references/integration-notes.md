# Integration Notes

Deeper rationale for the cross-compile dev workflow. Read this when adapting the
skill to an unfamiliar SDK or debugging why a piece isn't behaving.

## The two-build split

There are genuinely two builds, and conflating them causes most of the pain:

| | Dev preset | Production package build |
|---|---|---|
| Driver | `cmake --preset cross` | vendor build system (e.g. OpenWrt `make`) |
| Compiler | prebuilt cross toolchain (via toolchain file) | vendor's `TARGET_CC`/`TARGET_CXX` |
| Generator | Ninja | whatever the vendor uses (often Makefiles) |
| Tests | ON (GoogleTest + qemu) | OFF |
| Dev tooling | ON (.clangd, compile_commands) | OFF |
| Purpose | fast iteration, logic verification | shippable `.ipk` matching firmware ABI |

The production build **must** use the vendor's `TARGET_CC` because that carries
the exact sysroot, optimization, and hardening flags that every other library in
the rootfs was built with. The dev preset uses the raw prebuilt compiler for
speed and standalone operation. Same ABI family, different flag provenance —
deliberately not unified.

A concrete blocker reinforces this: vendor SDKs often bundle an old CMake (e.g.
3.19) that cannot read preset `version: 3` (needs 3.21+). So the production build
*can't* use the dev preset even in principle. Keep the package Makefile invoking
CMake directly with `-D` overrides.

## qemu-user via CMAKE_CROSSCOMPILING_EMULATOR

Setting `CMAKE_CROSSCOMPILING_EMULATOR` to `qemu-arm;-L;<target_root>` (a CMake
list: command + args) makes CTest prefix every test command with the emulator.
The `-L <target_root>` flag tells qemu to resolve the dynamic linker and shared
libraries (libc, libstdc++, ld-musl-*) from the target rootfs — without it,
dynamically-linked binaries fail to start.

The generated `run-<name>.sh` scripts replicate this for direct invocation,
useful when debugging a single failing test with gdb-under-qemu or extra flags.

## Why wrap the compiler for STAGING_DIR

OpenWrt's compiler is itself a shell wrapper that `exec`s unqualified tool names
and aborts if `STAGING_DIR` is unset. Two consequences:

1. The toolchain's bin dir must be on `PATH` (the wrapper execs `arm-...-g++` by
   name).
2. `STAGING_DIR` must be present for **every** invocation, including links.
   `CMAKE_<LANG>_COMPILER_LAUNCHER` does not reliably propagate environment into
   the link step, so we wrap the compiler with `compiler-env-wrapper.sh` that
   exports the variable then `exec`s the real compiler.

Toolchains without this quirk should skip the wrapper entirely.

## .clangd and the query-driver limitation

clangd parses with its own clang frontend, so GCC-only flags (`-mfloat-abi=`,
`-mfpu=`) appear as "unsupported option" errors. `gen_clangd.py` removes those
and adds `--sysroot=<target_root>` so clang can find headers.

But full fidelity (correct builtin macros, exact system include paths) requires
clangd to *ask the cross compiler* via `--query-driver`. That is a clangd
**launch flag**, not a `.clangd` option, so it can't be generated into the config
file. The script prints the recommended `--query-driver=<glob>` for the user to
add to their editor's clangd arguments.

## compile_commands.json symlink

`CMAKE_EXPORT_COMPILE_COMMANDS=ON` writes `compile_commands.json` into the build
dir. clangd looks for it at the project root (or wherever `.clangd`'s
`CompilationDatabase` points). A custom `ALL` target re-creates the root symlink
on every build, so whichever preset was built last is always what clangd sees.
For a single active dev preset this is exactly right.

## GoogleTest standard mismatch

GoogleTest ≥1.13 requires C++14. The app may target C++11 to match the firmware.
The resolution: set `cxx_std_14` only on test executables. C++11 and C++14 object
files are ABI-compatible within the same libstdc++, so linking a C++11 app lib
into a C++14 test is safe.
