{
  description = "nvim-treesitter main branch overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter/main";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
            };
          }
        );
    in
    {
      overlays = {
        default = (import ./overlay.nix { inherit inputs; });
      };
      devShells = forEachSupportedSystem (
        { pkgs, ... }:
        {
          default = pkgs.mkShell {
            packages = [
              (import ./generate-parsers { inherit inputs pkgs; })
            ];
          };
        }
      );
      packages = forEachSupportedSystem (
        { pkgs, ... }:
        let
          pkgs' = import inputs.nixpkgs {
            inherit (pkgs) system;
            overlays = (pkgs.overlays or [ ]) ++ [
              (import ./overlay.nix { inherit inputs; })
            ];
          };
        in
        rec {
          nvim-treesitter = pkgs'.vimPlugins.nvim-treesitter.withAllGrammars;
          default = nvim-treesitter;
        }
      );
    };
}
