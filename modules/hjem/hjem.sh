#!/usr/bin/env bash
set -euo pipefail

# The flake whose hjemConfigurations."<user>" holds each user's dotfiles and
# whose packages.<system>.hjem is the CLI that links them, for example
# `github:pelikanade/reverie`.
FLAKE=$(echo "$1" | jq -r 'try .["flake"]')
if [[ -z $FLAKE || $FLAKE == "null" ]]; then
  echo "ERROR: 'flake' must name a flake with hjemConfigurations"
  exit 1
fi

# Interval between switches, and the delay after boot before the first timed
# one, in systemd.time syntax. The switch also runs at every login.
RUN_EVERY=$(echo "$1" | jq -r 'try .["run-every"] // "1d"')
WAIT_AFTER_BOOT=$(echo "$1" | jq -r 'try .["wait-after-boot"] // "5m"')

# Enable the units for every user; otherwise a user enables them with
# `systemctl --user enable hjem-switch.service hjem-switch.timer`.
ALL_USERS=$(echo "$1" | jq -r 'if has("all-users") then .["all-users"] else true end')

cat >/usr/libexec/hjem-switch <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# hjem applies hjemConfigurations."$USER"; a user the flake has no
# configuration for is skipped. --refresh skips the cached flake tarball, so
# each run sees the latest revision, which the switch then reuses.
user="$(id -un)"
has_configuration="$(nix eval --refresh --raw "$1#hjemConfigurations" \
  --apply "configurations: if configurations ? \"$user\" then \"yes\" else \"no\"")"
if [[ $has_configuration != yes ]]; then
  echo "$1 has no hjem configuration for $user; skipping"
  exit 0
fi

exec nix run "$1#hjem" -- standalone switch --flake "$1"
EOF
chmod 0755 /usr/libexec/hjem-switch

cat >/usr/lib/systemd/user/hjem-switch.service <<EOF
[Unit]
Description=Link the hjem dotfiles

[Service]
Type=oneshot
ExecStart=/usr/libexec/hjem-switch ${FLAKE}

[Install]
WantedBy=default.target
EOF

cat >/usr/lib/systemd/user/hjem-switch.timer <<EOF
[Unit]
Description=Periodically link the hjem dotfiles

[Timer]
OnBootSec=${WAIT_AFTER_BOOT}
OnUnitInactiveSec=${RUN_EVERY}

[Install]
WantedBy=timers.target
EOF

if [[ $ALL_USERS == true ]]; then
  systemctl --global enable hjem-switch.service hjem-switch.timer
fi
