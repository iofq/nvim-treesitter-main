{ inputs, ... }:
final: prev:
with prev;
let
  inherit (neovimUtils) grammarToPlugin;

  overrides = prev: {
  };

  generatedGrammars =
    let
      generated = callPackage ./generated.nix {
        inherit (tree-sitter) buildGrammar;
      };
    in
    lib.overrideExisting generated (overrides generated);

  generatedDerivations = lib.filterAttrs (_: lib.isDerivation) generatedGrammars;

  # add aliases so grammars from `tree-sitter` are overwritten in `withPlugins`
  # for example, for ocaml_interface, the following aliases will be added
  #   ocaml-interface
  #   tree-sitter-ocaml-interface
  #   tree-sitter-ocaml_interface
  builtGrammars =
    generatedGrammars
    // lib.concatMapAttrs (
      k: v:
      let
        replaced = lib.replaceStrings [ "_" ] [ "-" ] k;
      in
      {
        "tree-sitter-${k}" = v;
      }
      // lib.optionalAttrs (k != replaced) {
        ${replaced} = v;
        "tree-sitter-${replaced}" = v;
      }
    ) generatedDerivations;

  allGrammars = lib.attrValues generatedDerivations;

  # Usage:
  # pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [ p.c p.java ... ])
  # or for all grammars:
  # pkgs.vimPlugins.nvim-treesitter.withAllGrammars
  withPlugins =
    f:
    final.vimPlugins.nvim-treesitter.overrideAttrs {
      passthru.dependencies = map grammarToPlugin (f (tree-sitter.builtGrammars // builtGrammars));
    };

  withAllGrammars = withPlugins (_: allGrammars);
in
{
  vimPlugins = prev.vimPlugins.extend (
    final': prev': {
      nvim-treesitter = prev.vimPlugins.nvim-treesitter.overrideAttrs (old: rec {
        src = inputs.nvim-treesitter;
        name = "${old.pname}-${src.rev}";
        postPatch = "";
        # ensure runtime queries get linked to RTP (:TSInstall does this too)
        postInstall = "
          mkdir -p $out/queries
          cp -a $src/runtime/queries/* $out/queries
        ";
        passthru = (prev.nvim-treesitter.passthru or { }) // {
          inherit
            builtGrammars
            allGrammars
            grammarToPlugin
            withPlugins
            withAllGrammars
            ;

          grammarPlugins = lib.mapAttrs (_: grammarToPlugin) generatedDerivations;
        };
        nvimSkipModules = [ "nvim-treesitter._meta.parsers" ];
      });
      nvim-treesitter-textobjects = prev.vimPlugins.nvim-treesitter-textobjects.overrideAttrs (old: {
        version = inputs.nvim-treesitter-textobjects.rev;
        src = inputs.nvim-treesitter-textobjects;
      });
    }
  );

}
