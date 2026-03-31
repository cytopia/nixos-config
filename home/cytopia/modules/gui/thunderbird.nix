{
  pkgs-unstable,
  ...
}:

{
  programs.thunderbird = {
    enable = true;
    package = pkgs-unstable.thunderbird-latest;
    # settings applied to ALL profiles (optional)
    settings = {
      "privacy.donottrackheader.enabled" = true;
      #"general.useragent.override" = "";
    };
    profiles = { };
  };
}
