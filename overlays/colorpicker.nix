final: prev: {
  # Safely merge into the 'custom' namespace
  custom = (prev.custom or { }) // {
    # callPackage automatically passes dependencies. We use 'final' here
    # so that if you ever override a dependency globally.
    colorpicker = final.callPackage ../pkgs/colorpicker/default.nix { };
  };
}
