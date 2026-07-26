---
name: cross-compile-dev-setup
description: Set up a CMake cross-compilation developer workflow for embedded Linux projects — CMake presets driving a vendor cross toolchain, GoogleTest unit tests executed on the host via qemu-user, per-test and aggregate runner scripts, a root compile_commands.json symlink, and a generated .clangd for clangd/LSP. Use this skill whenever the user wants to cross-compile an embedded app, run device tests without flashing hardware, set up CMake presets for a cross toolchain, wire qemu-user into CTest, get clangd working on cross-compiled code, or asks about compile_commands.json / .clangd / GoogleTest / CMAKE_CROSSCOMPILING_EMULATOR for ARM/RISC-V Linux targets — even if they don't name this skill explicitly.
---

# Cross-Compile Dev Setup

Build a repeatable developer workflow for an embedded Linux app that must be
cross-compiled but should still be fast to test and navigate on a dev machine.
The core idea: **one CMake preset drives the real vendor cross toolchain**, and
everything else (tests, LSP, runner scripts) hangs off that single source of
truth.

## Why this shape

Embedded teams often hit the same wall: the only "real" build is a slow
full-firmware image, so every logic change means flash-and-reboot. This workflow
breaks that loop without lying about the target:

- **Cross-compilation is the source of truth.** Binaries are always built for the
  real target ABI (e.g. ARM musl hard-float). No host build that pretends to be
  the device.
- **qemu-user runs those real binaries on the host.** Logic tests execute in
  seconds, no hardware, no flashing. `CMAKE_CROSSCOMPILING_EMULATOR` makes CTest
  do this automatically.
- **clangd understands the cross code.** A generated `.clangd` plus a
  `compile_commands.json` symlink means navigation and diagnostics work instead
  of choking on GCC-only flags like `-mfloat-abi=`.

Keep these two builds separate by design: the **dev preset** (fast iteration +
qemu tests) and the **production package build** (the vendor's build system,
e.g. OpenWrt `make package/.../compile`, using its own `TARGET_CC`). They use
different compilers on purpose — the production build must match the rest of the
firmware's ABI. Do not try to unify them through one preset.

## Naming discipline

Name modules and functions by **capability, not by project**. These are reusable
tools:

- ✓ `CrossCompileTesting.cmake`, `ClangdIntegration.cmake`, `cross_test_add()`
- ✗ `MyProjectTesting.cmake`, `myproject_add_test()`

Project-specific glue may carry a project prefix; generic machinery should not.

## Workflow

### 1. Locate the real cross toolchain

Before writing anything, find the vendor's actual compiler and target rootfs.
For an OpenWrt/Tina SDK this is typically under the build output, **not** the
BSP toolchain:

```bash
# OpenWrt cross compiler (mind: musl target, matches the firmware ABI)
find out -path '*staging_dir*' -name '*-g++' 2>/dev/null
# target rootfs for qemu -L (has ld-musl-*.so, libc.so, libstdc++.so)
find out -path '*staging_dir/target*' -name 'ld-musl-*' 2>/dev/null
```

Verify the pipeline end-to-end with a throwaway program before wiring CMake:

```bash
echo 'int main(){return 0;}' > /tmp/t.cpp
STAGING_DIR=<staging_dir> <cross-g++> -o /tmp/t /tmp/t.cpp
file /tmp/t                 # expect: ELF 32-bit ... ARM ... musl
qemu-arm -L <target_root> /tmp/t && echo OK
```

If this doesn't run under qemu, stop and fix the toolchain/rootfs pairing first
— nothing downstream will work.

### 2. Drop in the assets

Copy from this skill's `assets/` into the project, preserving layout:

```
<project>/
├── CMakePresets.json                          <- assets/CMakePresets.json
└── cmake/
    ├── modules/
    │   ├── CrossCompileTesting.cmake          <- assets/cmake/modules/
    │   └── ClangdIntegration.cmake
    ├── scripts/
    │   ├── gen_clangd.py                      <- assets/cmake/scripts/
    │   └── compiler-env-wrapper.sh            (chmod +x)
    └── toolchains/
        └── cross-toolchain.cmake              <- assets/cmake/toolchains/
```

### 3. Adapt the toolchain file

Edit the `EDIT ME` blocks in `cross-toolchain.cmake`: set the compiler defaults,
staging dir, target rootfs, arch, and qemu binary. If the vendor compiler needs
no env wrapper (most don't), swap the wrapper lines for plain
`set(CMAKE_C_COMPILER ...)` / `set(CMAKE_CXX_COMPILER ...)`. OpenWrt's wrapper
aborts without `STAGING_DIR`, which is why the template wraps the compiler —
CMake's compiler launcher does not reliably propagate env into the link step.

### 4. Wire the root CMakeLists

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
include(CrossCompileTesting)
include(ClangdIntegration)

option(BUILD_TESTING "Build tests (needs network for GoogleTest)" OFF)
option(DEV_TOOLING "Generate .clangd and compile_commands symlink" ON)

# ... your targets ...

dev_tooling_enable()

if(BUILD_TESTING)
    cross_test_setup_gtest()
    enable_testing()
    add_subdirectory(tests)
endif()
```

In `tests/CMakeLists.txt`:

```cmake
cross_test_add(my_logic_test my_logic_test.cpp LINK my_logic_lib)
cross_test_generate_runner()   # emits build/run-tests.sh
```

### 5. Verify

```bash
cmake --preset cross
cmake --build --preset cross
ctest --preset cross                       # runs under qemu automatically
./build/cross/run-tests.sh                 # or the generated scripts directly
cat .clangd && ls -l compile_commands.json # dev tooling present
```

## Gotchas worth knowing

- **GoogleTest 1.14 needs C++14.** `cross_test_add` sets `cxx_std_14` on test
  targets only; the app itself can stay at an older standard.
- **`file(GENERATE)` scripts are not executable.** `chmod +x build/*/run-*.sh`
  after building, or run them via `sh`.
- **`.clangd` alone can't set `--query-driver`** — that's a clangd launch flag.
  `gen_clangd.py` prints the exact `--query-driver=<glob>` to add to the editor's
  clangd arguments for full header resolution.
- **SDK CMake may be old.** A vendor SDK's bundled CMake (e.g. 3.19) can't read
  preset `version: 3`. That's fine — presets are dev-only; the production package
  build invokes CMake directly with the vendor's `TARGET_CC` and no presets.
- **Gate dev tooling for production.** Pass `-DDEV_TOOLING=OFF -DBUILD_TESTING=OFF`
  in the package build so it doesn't fetch GoogleTest or generate `.clangd`.

## Reference

- `references/integration-notes.md` — deeper rationale, the dev-vs-production
  split, and how each piece maps to CMake/clangd/qemu internals.
