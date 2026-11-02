{
  description = "reverie's dotfiles, linked into $HOME by hjem";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, hjem, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.hjem = hjem.packages.${system}.hjem;

      hjemConfigurations.nvirellia.manifest = import ./dotfiles {
        inherit pkgs;
        inherit (nixpkgs) lib;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nixfmt
          yaml-language-server
          yamlfmt
        ];
      };
    };
}
