{ inputs, pkgs, ... }:
with pkgs;
stdenv.mkDerivation {
  pname = "generate-parsers";
  version = "1.0";

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  src = ./generate-parsers.lua;

  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    echo "#!${pkgs.luajit}/bin/luajit" > $out/bin/generate-parsers
    cat $src >> $out/bin/generate-parsers
    chmod +x $out/bin/generate-parsers

    wrapProgram $out/bin/generate-parsers \
      --add-flag ${inputs.nvim-treesitter}/lua/nvim-treesitter/parsers.lua \
      --add-flag "generated.nix" \
      --prefix PATH : "${
        pkgs.lib.makeBinPath [
          pkgs.nurl
          pkgs.nixfmt
        ]
      }"
  '';
}
