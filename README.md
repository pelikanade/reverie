# reverie &nbsp; [![bluebuild build badge](https://github.com/asterismono/reverie/actions/workflows/build.yml/badge.svg)](https://github.com/asterismono/reverie/actions/workflows/build.yml)

the quiet workstation for the distro-housekeeping-exhausted.

[create an installation ISO](https://blue-build.org/how-to/generate-iso/#_top)

## dotfiles

the image's RPMs carry every program; `dotfiles/` carries only their configuration. [hjem](https://github.com/feel-co/hjem) links it into `$HOME` from `hjemConfigurations.<user>` in `flake.nix`.

the local `hjem` module (`modules/hjem/`) runs `hjem standalone switch --flake github:pelikanade/reverie` at login and daily for every user that has a configuration there, and skips everyone else. to switch by hand:

```sh
systemctl --user start hjem-switch.service
```

the local `nix` module (`modules/nix/`) installs nix with its daemon and appends its `settings:` map to `/etc/nix/nix.conf`.
