{ inputs }:

final: prev: {
  custom = (prev.custom or { }) // {
    # Always use prev.system to avoid infinite recursion loops!
	neovim-nightly = inputs.neovim-nightly.packages.${prev.stdenv.hostPlatform.system}.default;
  };
}
