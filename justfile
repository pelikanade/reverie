# vim: set ft=make :

# The flake that carries hjemConfigurations and the hjem CLI. It defaults to
# this checkout, so what lands in $HOME is the working tree, uncommitted edits
# included; name another flake, for example
# `just hjem github:pelikanade/reverie`, to link a pushed revision instead.
checkout := "path:" + justfile_directory()

# Link the dotfiles into $HOME from this checkout.
hjem ref=checkout:
    nix run --refresh {{quote(ref)}}#hjem -- standalone switch --flake {{quote(ref)}}
