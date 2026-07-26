# Cross toolchain template (project-agnostic).
#
# Adapt the three "EDIT ME" blocks to your SDK, then drop this file at
# <project>/cmake/toolchains/<name>.cmake. Paths default from env vars so the
# same file works across machines and CI.
#
# Env vars (all optional if you hardcode defaults below):
#   CROSS_CC / CROSS_CXX         absolute compiler paths
#   CROSS_STAGING_DIR            SDK staging dir (exported as STAGING_DIR)
#   CROSS_TARGET_ROOT            target rootfs used by qemu -L
#   CROSS_QEMU                   qemu-user binary (default qemu-<arch>)

# --- EDIT ME: defaults for your toolchain -----------------------------------
set(_arch "arm")                          # CMAKE_SYSTEM_PROCESSOR
set(_qemu_default "qemu-arm")             # qemu-user binary for this arch
set(_cc_default "")                       # e.g. <sdk>/.../bin/arm-...-gcc
set(_cxx_default "")                      # e.g. <sdk>/.../bin/arm-...-g++
set(_staging_default "")                  # e.g. <sdk>/out/<board>/.../staging_dir
set(_target_root_default "")              # e.g. ${_staging_default}/target/root-<board>
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
set(_qemu "$ENV{CROSS_QEMU}")
if(_qemu STREQUAL "")
    set(_qemu "${_qemu_default}")
endif()

foreach(_required IN ITEMS _cc _cxx _staging _target_root)
    if(NOT EXISTS "${${_required}}")
        message(FATAL_ERROR
            "Cross toolchain path not found: ${${_required}}\n"
            "Build the target once, or set CROSS_CC / CROSS_CXX / "
            "CROSS_STAGING_DIR / CROSS_TARGET_ROOT.")
    endif()
endforeach()

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR "${_arch}")

# --- EDIT ME: env your vendor wrapper needs (delete if none) ----------------
# OpenWrt wrappers abort unless STAGING_DIR is set and exec unqualified tool
# names, so export it and put the toolchain bin dir on PATH, then wrap the
# compiler so the env survives into the link step.
get_filename_component(_tc_bin "${_cc}" DIRECTORY)
set(ENV{STAGING_DIR} "${_staging}")
set(ENV{PATH} "${_tc_bin}:$ENV{PATH}")
set(_wrapper "${CMAKE_CURRENT_LIST_DIR}/../scripts/compiler-env-wrapper.sh")
set(CMAKE_C_COMPILER "${_wrapper}" "STAGING_DIR=${_staging}" "${_cc}" CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER "${_wrapper}" "STAGING_DIR=${_staging}" "${_cxx}" CACHE STRING "" FORCE)
# If your toolchain needs no wrapper, use these two lines instead:
# set(CMAKE_C_COMPILER "${_cc}")
# set(CMAKE_CXX_COMPILER "${_cxx}")
# ----------------------------------------------------------------------------

# Run test binaries under qemu-user against the target rootfs.
set(CMAKE_CROSSCOMPILING_EMULATOR "${_qemu};-L;${_target_root}" CACHE STRING "" FORCE)

# Consumed by the .clangd generator.
execute_process(
    COMMAND "${_cxx}" -dumpmachine
    OUTPUT_VARIABLE _triple
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
set(CROSS_TARGET_TRIPLE "${_triple}" CACHE STRING "" FORCE)
set(CROSS_TARGET_ROOTFS "${_target_root}" CACHE STRING "" FORCE)
set(CROSS_COMPILER "${_cxx}" CACHE STRING "" FORCE)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
