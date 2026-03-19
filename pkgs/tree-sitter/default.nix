{ stdenv, fetchurl, gzip, patchelf }:

stdenv.mkDerivation rec {
  pname = "tree-sitter";
  version = "0.26.7";

  src = fetchurl {
    name = "tree-sitter-${version}-linux-x64.gz";
    url = "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-linux-x64.gz";
    hash = "sha256-Q2eka8iru4Mo1u++sm6GgHrwo6fkYlSKOST4conuHpw=";
  };

  nativeBuildInputs = [ gzip patchelf ];

  unpackPhase = ''
    gunzip -c $src > tree-sitter
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp tree-sitter $out/bin/
    chmod +x $out/bin/tree-sitter
  '';

  postFixup = ''
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/tree-sitter
  '';

  meta = {
    description = "Pre-compiled tree-sitter binary";
    homepage = "https://github.com/tree-sitter/tree-sitter";
    mainProgram = "tree-sitter";
  };
}
