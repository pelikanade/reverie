{ pkgs, lib }:
let
  home = "/home/pelikanade";

  # Fish plugins are plain scripts, so they are loaded from their nixpkgs
  # sources instead of being installed.
  fishPlugins = with pkgs.fishPlugins; [
    plugin-git
    fzf-fish
    puffer
  ];
  fishPluginLoader = pkgs.writeText "plugins.fish" ''
    for plugin_dir in ${lib.concatMapStringsSep " " (plugin: "${plugin.src}") fishPlugins}
        if test -d $plugin_dir/functions
            set fish_function_path $fish_function_path[1] $plugin_dir/functions $fish_function_path[2..-1]
        end
        if test -d $plugin_dir/completions
            set fish_complete_path $fish_complete_path[1] $plugin_dir/completions $fish_complete_path[2..-1]
        end
        # Some plugins install their abbreviations from init.fish alone; their
        # conf.d entry point only runs the fisher bootstrap, which finds
        # nothing here because the functions come from fish_function_path.
        if test -f $plugin_dir/init.fish
            source $plugin_dir/init.fish
        end
        if test -d $plugin_dir/conf.d
            # An unmatched glob stays literal, so filter before sourcing.
            for file in $plugin_dir/conf.d/*.fish
                test -f $file; and source $file
            end
        end
    end
  '';

  # hjem links $HOME at the paths the manifest names, so they have to exist. A
  # path from this repository is copied into a store path of its own: a path
  # inside the flake tree only exists once Nix has materialised that tree, which
  # it does lazily, and hjem then fails to activate every file with ENOENT.
  # Anything that is already in the store, such as the writeText result above,
  # is left alone.
  selfContained =
    source:
    if builtins.isPath source then
      builtins.toFile (baseNameOf (toString source)) (builtins.readFile source)
    else
      source;

  # The repository owns these files, so whatever is already there is replaced.
  file = type: target: source: {
    inherit type;
    source = selfContained source;
    target = "${home}/${target}";
    clobber = true;
  };
  link = file "symlink";
  # A copy keeps the store's read-only mode unless it is given one.
  copy = target: source: file "copy" target source // { permissions = "644"; };
in
{
  version = 3;
  files = [
    (link ".config/fish/config.fish" ./fish/config.fish)
    (link ".config/fish/conf.d/plugins.fish" fishPluginLoader)
    (link ".config/starship.toml" ./starship.toml)
    (link ".config/ghostty/config" ./ghostty/config)
    # Zed writes its settings back from the UI, so they are copies, not links.
    (copy ".config/zed/settings.json" ./zed/settings.json)
    (copy ".config/zed/keymap.json" ./zed/keymap.json)
    (link ".config/git/config" ./git/config)
    (link ".ssh/config" ./ssh/config)
    (link ".config/gh/config.yml" ./gh/config.yml)
    (link ".config/lazygit/config.yml" ./lazygit/config.yml)
    (link ".config/atuin/config.toml" ./atuin/config.toml)
    (link ".config/nvim/init.lua" ./nvim/init.lua)
  ];
}
