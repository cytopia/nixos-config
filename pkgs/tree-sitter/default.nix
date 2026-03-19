{ stdenv, fetchurl, gzip, patchelf }:

stdenv.mkDerivation rec {
  pname = "tree-sitter";
  version = "0.26.7";

  src = fetchurl {
    url = "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-linux-x64.gz";
    hash = "sha256-4367a46bc8abbb8328d6efbeb26e86807af0a3a7e462548a3924f87289ee1e9c";
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
