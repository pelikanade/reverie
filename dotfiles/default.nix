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
        for file in $plugin_dir/conf.d/*.fish
            source $file
        end
    end
  '';

  # The repository owns these files, so whatever is already there is replaced.
  file = type: target: source: {
    inherit type source;
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
