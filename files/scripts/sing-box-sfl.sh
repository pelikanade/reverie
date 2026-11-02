#!/usr/bin/env bash
set -euo pipefail

# SFL assets carry the version in their file name, so releases/latest/download
# cannot address them; resolve the latest stable tag from the redirect instead.
latest="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/SagerNet/sing-box/releases/latest)"
tag="${latest##*/}"

dnf -y install "https://github.com/SagerNet/sing-box/releases/download/${tag}/SFL-${tag#v}-x86_64.rpm"
