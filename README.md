<div align="center">
  <br/>
  <br/>
  <h1>nvim-treesitter-main</h1>
  <p><strong>A Nixpkgs overlay for the nvim-treesitter plugin main branch rewrite</strong></p>
  <div>
    <img
      alt="License"
      src="https://img.shields.io/github/license/iofq/nvim-treesitter-main?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41"
    />
    <img
      alt="Stars"
      src="https://img.shields.io/github/stars/iofq/nvim-treesitter-main?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41"
    />
  </div>
</div>

## Overview
The [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter/tree/main) main branch is a full, incompatible rewrite of the project, and the existing `master` branch is all but abandoned.

The `nixpkgs` `nvim-treesitter` plugin is not well equipped to handle the migration today, nor would it be a good idea to switch everyone over given the still-nascent ecosystem around the rewrite. Regardless, you're here because you're both a Nix and Neovim user, and you like to live on the bleeding edge.

**nvim-treesitter-main** is a flake that builds the new `main` branch `nvim-treesitter`, along with all of the parser versions from the [`parsers.lua`](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/lua/nvim-treesitter/parsers.lua) file, as recommended by the project.

## Usage

In your flake.nix:

```nix
    inputs = {
        nvim-treesitter-main.url = "github:iofq/nvim-treesitter-main";
    };
    # ... and import the overlay
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        inputs.nvim-treesitter-main.overlays.default
      ];
    };

```

## Updating

To update the list of parsers in `generated.nix`:

```bash
nix flake update
nix develop --command "generate-parsers"
```

This runs a lua script similar to the old [update.py](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/utils/nvim-treesitter/update.py), but uses the `nvim-treesitter` as a source for version info instead of the NURR json file.
