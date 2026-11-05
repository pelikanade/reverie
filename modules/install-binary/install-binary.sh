#!/usr/bin/env bash
set -euo pipefail

# Installs programs no rpm carries: the recipe names a download URL per
# command, this module puts the artifact in /usr/bin. The image builds daily,
# so a .../releases/latest/download/... URL follows upstream without a version
# here; a versioned URL pins it. What a program needs besides the binary (a
# desktop entry, say) belongs in files/system, which the files module copies.
#
# DESTDIR is honoured for every path, the usual packaging convention.

BINARIES=$(echo "$1" | jq -c 'try .["binaries"] // {}')
if [[ $BINARIES == '{}' ]]; then
  echo "ERROR: 'binaries' must map each command name to its download URL" >&2
  exit 1
fi

# Anything but an ELF for this machine -- an HTML error page from a dead URL,
# the artifact of another architecture -- has to break the build, not the image.
case "$(uname -m)" in
  x86_64) elf_arch=x86-64 ;;
  aarch64) elf_arch=aarch64 ;;
  *) elf_arch="$(uname -m)" ;;
esac

dest="${DESTDIR:-}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

while IFS=$'\x1f' read -r name url icon; do
  if [[ -z $url ]]; then
    echo "ERROR: $name has no url" >&2
    exit 1
  fi

  echo "install-binary: $name <- $url"
  curl -fsSL "$url" -o "$tmp/$name"
  if ! file -b "$tmp/$name" | grep -q "ELF 64-bit.*$elf_arch"; then
    echo "ERROR: $url is not a 64-bit $elf_arch ELF: $(file -b "$tmp/$name")" >&2
    exit 1
  fi
  install -Dm755 "$tmp/$name" "$dest/usr/bin/$name"

  if [[ -n $icon ]]; then
    echo "install-binary: $name icon <- $icon"
    curl -fsSL "$icon" -o "$tmp/$name.png"
    install -Dm644 "$tmp/$name.png" "$dest/usr/share/icons/hicolor/256x256/apps/$name.png"
  fi
done < <(
  # Unit separator, not tabs: an empty field (a binary with no icon) must not
  # collapse into the next one when bash splits the line.
  echo "$BINARIES" | jq -r '
    to_entries[]
    | [
        .key,
        (.value | if type == "string" then . else (.url // "") end),
        (.value | if type == "object" then (.icon // "") else "" end)
      ]
    | join("\u001f")
  '
)

# Desktop entries and icons are in place by now -- from this module and from
# files/system -- so refresh what a package would have refreshed in its %post.
if command -v update-desktop-database >/dev/null && [[ -d $dest/usr/share/applications ]]; then
  update-desktop-database -q "$dest/usr/share/applications"
fi
if command -v gtk-update-icon-cache >/dev/null && [[ -d $dest/usr/share/icons/hicolor ]]; then
  gtk-update-icon-cache -qtf "$dest/usr/share/icons/hicolor"
fi