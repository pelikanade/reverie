#!/usr/bin/env bash
set -euo pipefail

# /nix cannot live on the read-only root, so the store is kept under /var/nix
# and bind-mounted onto an empty /nix before the daemon starts.
mkdir -p /nix
chmod 0755 /nix

dnf -y install nix nix-daemon

cat >/usr/lib/tmpfiles.d/nix-store.conf <<'EOF'
d /var/nix 0755 root root -
EOF

cat >/usr/lib/systemd/system/nix.mount <<'EOF'
[Unit]
Description=Bind Mount for Nix Package Manager
DefaultDependencies=no
Before=sockets.target nix-daemon.service
After=ostree-remount.service
BindsTo=var.mount

[Mount]
What=/var/nix
Where=/nix
Options=bind
Type=none

[Install]
WantedBy=local-fs.target
EOF

systemctl enable nix.mount nix-daemon.service

# nix-core ships /etc/nix/nix.conf as a noreplace config file without an
# include, so settings are appended to it. A list value is joined with spaces,
# which is how nix.conf spells lists.
echo "$1" | jq -r '
  try .["settings"] // {}
  | to_entries[]
  | "\(.key) = \(.value | if type == "array" then join(" ") else tostring end)"
' >>/etc/nix/nix.conf
