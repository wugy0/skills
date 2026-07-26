# Cross toolchain template (project-agnostic).
#
# Adapt the "EDIT ME" blocks to your SDK, then drop this file at
# <project>/cmake/toolchains/<name>.cmake. Paths default from env vars so the
# same file works across machines and CI.
#
# Env vars (all optional if you hardcode defaults below):
#   CROSS_CC / CROSS_CXX         absolute compiler paths
#   CROSS_STAGING_DIR            optional vendor staging dir (exported as STAGING_DIR)
#   CROSS_TARGET_ROOT            target rootfs used by qemu -L
#   CROSS_CLANG_TARGET_TRIPLE    Clang-compatible target triple for clangd
#   CROSS_QEMU                   qemu-user binary (default qemu-<arch>)

# --- EDIT ME: defaults for your toolchain -----------------------------------
set(_arch "arm")                          # CMAKE_SYSTEM_PROCESSOR
set(_qemu_default "qemu-arm")             # qemu-user binary for this arch
set(_cc_default "")                       # e.g. <sdk>/.../bin/arm-...-gcc
set(_cxx_default "")                      # e.g. <sdk>/.../bin/arm-...-g++
set(_staging_default "")                  # e.g. <sdk>/out/<board>/.../staging_dir
set(_target_root_default "")              # e.g. ${_staging_default}/target/root-<board>
set(_clang_target_triple_default "")      # e.g. armv7-unknown-linux-musleabihf
# ----------------------------------------------------------------------------

set(_cc "$ENV{CROSS_CC}")
if(_cc STREQUAL "")
    set(_cc "${_cc_default}")
endif()
set(_cxx "$ENV{CROSS_CXX}")
if(_cxx STREQUAL "")
    set(_cxx "${_cxx_default}")
endif()
set(_staging "$ENV{CROSS_STAGING_DIR}")
if(_staging STREQUAL "")
    set(_staging "${_staging_default}")
endif()
set(_target_root "$ENV{CROSS_TARGET_ROOT}")
if(_target_root STREQUAL "")
    set(_target_root "${_target_root_default}")
endif()
set(_clang_target_triple "$ENV{CROSS_CLANG_TARGET_TRIPLE}")
if(_clang_target_triple STREQUAL "")
    set(_clang_target_triple "${_clang_target_triple_default}")
endif()
set(_qemu "$ENV{CROSS_QEMU}")
if(_qemu STREQUAL "")
    set(_qemu "${_qemu_default}")
endif()

foreach(_required IN ITEMS _cc _cxx _target_root)
    if(NOT EXISTS "${${_required}}")
        message(FATAL_ERROR
            "Cross toolchain path not found: ${${_required}}\n"
            "Build the target once, or set CROSS_CC / CROSS_CXX / CROSS_TARGET_ROOT.")
    endif()
endforeach()
if(NOT _staging STREQUAL "" AND NOT EXISTS "${_staging}")
    message(FATAL_ERROR "Cross staging dir not found: ${_staging}")
endif()
if(_clang_target_triple STREQUAL "")
    message(FATAL_ERROR
        "Set CROSS_CLANG_TARGET_TRIPLE or _clang_target_triple_default "
        "to a Clang-compatible target triple.")
endif()

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR "${_arch}")

# OpenWrt/Tina-style vendor compilers may read STAGING_DIR from GCC specs to
# find target package headers and libraries. This is an optional execution
# requirement, not compiler lookup: use the absolute compiler paths below and
# do not add their bin directory to PATH. When configured, ensure the build
# command also inherits STAGING_DIR.
if(NOT _staging STREQUAL "")
    set(ENV{STAGING_DIR} "${_staging}")
endif()
set(CMAKE_C_COMPILER "${_cc}" CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER "${_cxx}" CACHE STRING "" FORCE)

# Run test binaries under qemu-user against the target rootfs.
set(CMAKE_CROSSCOMPILING_EMULATOR "${_qemu};-L;${_target_root}" CACHE STRING "" FORCE)

# Consumed by the .clangd generator.
set(CROSS_CLANG_TARGET_TRIPLE "${_clang_target_triple}" CACHE STRING "" FORCE)
set(CROSS_TARGET_ROOTFS "${_target_root}" CACHE STRING "" FORCE)
set(CROSS_COMPILER "${_cxx}" CACHE STRING "" FORCE)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
