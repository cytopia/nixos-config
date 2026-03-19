{ inputs }:

final: prev: {
  custom = (prev.custom or { }) // {
    neovim-nightly = inputs.neovim-nightly.packages.${prev.stdenv.hostPlatform.system}.default;
  };
}
