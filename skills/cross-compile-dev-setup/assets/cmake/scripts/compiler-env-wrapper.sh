#!/bin/sh
# Inject an environment variable into a compiler invocation.
#
# Some vendor toolchains ship compiler wrappers that abort unless a specific
# variable (e.g. OpenWrt's STAGING_DIR) is set. CMake's compiler launcher does
# not reliably propagate env to the link step, so we wrap the compiler itself.
#
# Usage: compiler-env-wrapper.sh <VAR=VALUE> <compiler> [args...]
VAR_ASSIGN="$1"
shift
export "$VAR_ASSIGN"
exec "$@"
