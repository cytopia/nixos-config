{ config, pkgs, ... }:

{
  programs.thunderbird = {
    enable = true;

    # settings applied to ALL profiles (optional)
    settings = {
      "privacy.donottrackheader.enabled" = true;
	  #"general.useragent.override" = "";
    };
  };
}

