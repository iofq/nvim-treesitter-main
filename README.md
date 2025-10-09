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

** See below if you also plan to install tree-sitter grammars **

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

## Parsers (withPlugins, withAllGrammars)

`nvim-treesitter` expects all of the parsers and queries to be installed in a single directory (in a non-nix setting this would be done imperatively via `:TSInstall` into `~/.local`). To pacify it in a nix setting, `withPlugins` and `withAllGrammars` have been extended to bundle all defined parsers into a single path, and patch the nvim-treesitter `config.lua` `install_dir` setting to point directly at the bundle in the nix store.

A few other neovim plugins define `nvim-treesitter` as a dependency, meaning we run the risk of having two separate copies of `nvim-treesitter` presented to Neovim which can cause issues because one copy will not be aware of your installed parsers. To fix, create an overlay like below to redefine `nvim-treesitter` and any dependent plugins in your nixpkgs set.

*If you are not using any other plugins that depend on `nvim-treesitter`, you may skip this step, but it's still recommended.*

```nix
overlays = [
  inputs.nvim-treesitter-main.overlays.default
  (final: prev: {
    vimPlugins = prev.vimPlugins.extend (
      f: p: {
        nvim-treesitter = p.nvim-treesitter.withAllGrammars; # or withPlugins...
        # also redefine nvim-treesitter-textobjects (any other plugins that depend on nvim-treesitter)
        nvim-treesitter-textobjects = p.nvim-treesitter-textobjects.override {
          dependencies = [ f.nvim-treesitter ];
        };
      }
    );
  })
];
```

If you need the unpatched `nvim-treesitter` plugin without any parsers/queries bundled, even after you overlay it, you can use the `nvim-treesitter-unwrapped` output of this overlay.

## Updating

To update the list of parsers in `generated.nix`:

```bash
nix flake update
nix develop --command "generate-parsers"
```

This runs a lua script similar to the old [update.py](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/utils/nvim-treesitter/update.py), but uses the `nvim-treesitter` as a source for version info instead of the NURR json file.
