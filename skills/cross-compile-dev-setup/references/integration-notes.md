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

## STAGING_DIR is a compiler runtime requirement

Some OpenWrt GCC distributions encode target package paths in their GCC
`specs` file, for example `-idirafter %:getenv(STAGING_DIR /usr/include)` and
`-L %:getenv(STAGING_DIR /usr/lib)`. In that case `STAGING_DIR` is required for
preprocessing, compiling, and linking even when invoking the compiler by its
absolute path.

Keep `CMAKE_C_COMPILER` / `CMAKE_CXX_COMPILER` set to those absolute paths so
`compile_commands.json` stays truthful. Do not add the compiler directory to
`PATH` just to locate it. `set(ENV{STAGING_DIR} ...)` covers CMake configure
and compiler discovery; make the variable available separately to the build
process (via its caller environment or a build preset) because configure and
build are distinct processes.

## .clangd: Clang target and queried system headers

clangd parses with its own Clang frontend, so GCC-only flags (`-mfloat-abi=`,
`-mfpu=`) appear as unsupported-option errors and are removed. It must also
receive a Clang-compatible `--target` triple: do not assume a vendor GCC triple
will parse or encode the target ABI correctly.

`gen_clangd.py` invokes the real cross C++ compiler with `-E -x c++ -v -`, then
extracts the reported C++ system include search directories. It writes those as
`-isystem` entries together with `--target` and `--sysroot=<target_root>`. This
keeps the real compiler in `compile_commands.json` while giving clangd the
headers and ABI semantics it cannot reliably infer from a vendor driver name.

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
