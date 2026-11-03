#!/usr/bin/env bash
set -euo pipefail

# magpie publishes no rpm: its Linux desktop app is one binary per release.
# Wrap that binary in a package here, so the image owns it and magpie leaves
# updating to the image, instead of trying to replace a file on the read-only
# /usr. The image builds daily, so the package follows the newest release.
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "magpie: unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac
asset="magpie-linux-$arch"

# The site's feed names the newest release, its files and their SHA-256; the
# official installer checks against the same values.
feed="$(curl -fsSL https://usemagpie.ai/api/latest)"
entry="$(printf '%s' "$feed" | sed -n "s/.*\"$asset\":{\([^}]*\)}.*/\1/p")"
url="$(printf '%s' "$entry" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')"
sum="$(printf '%s' "$entry" | sed -n 's/.*"sha256":"\([^"]*\)".*/\1/p')"
version="$(printf '%s' "$feed" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')"
if [[ -z $url || -z $sum || -z $version ]]; then
  echo "magpie: the release feed has no $asset" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$url" -o "$tmp/magpie"
printf '%s  %s\n' "$sum" "$tmp/magpie" | sha256sum -c -
curl -fsSL https://usemagpie.ai/img/icon-256.png -o "$tmp/magpie.png"

# What the package holds: the places the official installer writes to, minus
# the ones that belong to a user (~/.local/bin, autostart).
mkdir -p "$tmp/tree/usr/bin" \
  "$tmp/tree/usr/share/applications" \
  "$tmp/tree/usr/share/icons/hicolor/256x256/apps"
install -m755 "$tmp/magpie" "$tmp/tree/usr/bin/magpie"
install -m644 "$tmp/magpie.png" "$tmp/tree/usr/share/icons/hicolor/256x256/apps/magpie.png"
cat >"$tmp/tree/usr/share/applications/magpie.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=magpie
Comment=Every agent's model. One place.
Exec=/usr/bin/magpie %u
Icon=magpie
StartupWMClass=magpie
Categories=Development;Utility;
MimeType=x-scheme-handler/magpie;
Terminal=false
EOF

# magpie-ai, because Fedora's own magpie is the Budgie window manager. The
# libraries the binary links are named by hand: nothing on the build host
# carries them, so they cannot be read off the file.
cat >"$tmp/magpie.spec" <<'EOF'
Name: magpie-ai
Version: %{_magpie_version}
Release: 1
Summary: One place to pick every AI coding agent's model
License: MIT
URL: https://usemagpie.ai
AutoReqProv: no
Requires: webkit2gtk4.1

%description
magpie runs a local gateway that speaks the OpenAI, Anthropic and Gemini APIs
to each other, so every agent can use every provider's models.

%install
cp -a %{_magpie_tree}/. %{buildroot}/

%files
/usr/bin/magpie
/usr/share/applications/magpie.desktop
/usr/share/icons/hicolor/256x256/apps/magpie.png

%post
# Both are skipped where the build host carries neither: a missing cache only
# costs a lookup, the files themselves are what the desktop reads.
command -v update-desktop-database >/dev/null && update-desktop-database -q /usr/share/applications
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -qtf /usr/share/icons/hicolor
EOF

# rpmbuild only makes the package; the package is what the image carries
# afterwards, so the tool and its build tree go again.
dnf -y install --setopt=install_weak_deps=False rpm-build

rpmbuild -bb "$tmp/magpie.spec" \
  --define "_topdir $tmp/rpm" \
  --define "_magpie_version $version" \
  --define "_magpie_tree $tmp/tree" \
  --define "debug_package %{nil}"

dnf -y install --setopt=install_weak_deps=False "$tmp"/rpm/RPMS/*/magpie-ai-*.rpm
dnf -y remove rpm-build