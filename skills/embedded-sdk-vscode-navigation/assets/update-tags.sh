#!/usr/bin/env bash
# Generate a selective Universal Ctags index for a large embedded Linux SDK.
# Run from the SDK root. Adapt source roots and active architectures below.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

file_list=$(mktemp)
trap 'rm -f "$file_list"' EXIT

# Update these paths for the SDK. Empty/nonexistent roots are skipped.
kernel_root=${KERNEL_ROOT:-kernel}
uboot_root=${UBOOT_ROOT:-u-boot}
buildroot_root=${BUILDROOT_ROOT:-buildroot}
openwrt_root=${OPENWRT_ROOT:-openwrt}
kernel_arch=${KERNEL_ARCH:-arm}
uboot_arch=${UBOOT_ARCH:-arm}

{
  # Makefiles and shell scripts, skipping generated/prebuilt trees.
  find . \
    \( -type d \( -name .git -o -name out -o -name output -o -name build_dir \
                    -o -name staging_dir -o -name tmp -o -name dl -o -name prebuilt \) -prune \) -o \
    \( -type f \( -name Makefile -o -name GNUmakefile -o -name '*.mk' -o -name '*.mak' \
                    -o -name '*.sh' -o -name '*.SH' -o -name '*.bash' -o -name '*.bsh' \
                    -o -name '*.ksh' -o -name '*.ash' -o -name .buildconfig \) -print \)

  # Linux/U-Boot common Kconfig files plus exactly one active architecture.
  # Other architecture trees often define the same CONFIG_* symbol.
  for root_arch in "$kernel_root:$kernel_arch" "$uboot_root:$uboot_arch"; do
    root=${root_arch%%:*}
    arch=${root_arch#*:}
    [ -d "$root" ] || continue
    find "$root" -type f -name 'Kconfig*' ! -path "$root/arch/*" -print
    [ -f "$root/arch/Kconfig" ] && printf '%s\n' "$root/arch/Kconfig"
    [ -d "$root/arch/$arch" ] && find "$root/arch/$arch" -type f -name 'Kconfig*' -print
  done

  # Buildroot/OpenWrt commonly name Kconfig files Config.in*.
  for root in "$buildroot_root" "$openwrt_root"; do
    [ -d "$root" ] || continue
    find "$root" \
      \( -type d \( -name output -o -name build_dir -o -name staging_dir -o -name tmp \) -prune \) -o \
      \( -type f \( -name 'Kconfig*' -o -name 'Config.in*' \) -print \)
  done
} > "$file_list"

sort -u -o "$file_list" "$file_list"

# The Make parser supplies tags for exported .buildconfig variables; the shell
# parser supplies shell functions. Kconfig covers Kconfig and Config.in*.
ctags --tag-relative=yes \
  --languages=Kconfig,Make,Sh \
  --map-Kconfig=+'(Config.in*)' \
  --map-Make=+'(.buildconfig)' \
  --fields=+nKz \
  --sort=yes \
  -L "$file_list" \
  -f .tags

printf 'Generated %s (%s entries)\n' \
  "$(du -h .tags | cut -f1)" \
  "$(grep -vc '^!' .tags)"
