# vim: set ft=make :

# Link the hjem dotfiles into $HOME now, instead of waiting for the timer
[group("system")]
hjem:
    #!/usr/bin/bash
    set -euo pipefail
    systemctl --user start hjem-switch.service
