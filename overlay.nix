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
    let
      grammars = (f (tree-sitter.builtGrammars // builtGrammars));

      # Grammars that are required by a provided grammar
      required = lib.unique (lib.concatLists (map (g: g.requires or [ ]) grammars));

      # Append grammars from required that exist in builtGrammars (they actually have a parser)
      # Need to split these out as some "requires" elements from parsers.lua are just queries
      # from nvim-treesitter/runtime/queries
      finalGrammars =
        grammars
        ++ map (name: builtGrammars.${name}) (
          builtins.filter (name: builtins.hasAttr name builtGrammars) required
        );

      runtimeQueries = lib.concatStringsSep " " ((map (g: g.passthru.name) grammars) ++ required);

      bundle = pkgs.symlinkJoin {
        name = "nvim-treesitter-bundle";
        paths = map grammarToPlugin finalGrammars;
      };
    in
    final.vimPlugins.nvim-treesitter-unwrapped.overrideAttrs (old: {
      postInstall = old.postInstall + ''
        # ensure runtime queries get linked to RTP (:TSInstall does this too)
        mkdir -p $out/queries
        for grammar in ${runtimeQueries}; do
            ln -sfT $src/runtime/queries/$grammar $out/queries/$grammar
        done

        # patch nvim-treesitter with parser bundle path
        ln -sfT ${bundle}/parser $out/parser
        substituteInPlace $out/lua/nvim-treesitter/config.lua \
          --replace-fail "install_dir = vim.fs.joinpath(vim.fn.stdpath('data') --[[@as string]], 'site')," \
          "install_dir = '$out'"
      '';
    });

  withAllGrammars = withPlugins (_: allGrammars);
in
{
  vimPlugins = prev.vimPlugins.extend (
    final': prev': rec {
      nvim-treesitter-unwrapped = (
        prev'.nvim-treesitter.overrideAttrs (old: rec {
          src = inputs.nvim-treesitter;
          name = "${old.pname}-${src.rev}";
          postPatch = "";
          # ensure runtime queries get linked to RTP (:TSInstall does this too)
          passthru = (prev'.nvim-treesitter.passthru or { }) // {
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
        })
      );
      nvim-treesitter = nvim-treesitter-unwrapped;

      nvim-treesitter-textobjects = prev'.nvim-treesitter-textobjects.overrideAttrs (old: {
        version = inputs.nvim-treesitter-textobjects.rev;
        src = inputs.nvim-treesitter-textobjects;
        dependencies = [ final'.nvim-treesitter ];
      });
    }
  );

}
