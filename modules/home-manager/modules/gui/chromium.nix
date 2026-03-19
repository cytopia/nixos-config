{ config, lib, pkgs, ... }:

let
  # Specific version of chromium requested
  chromiumPkg = pkgs.ungoogled-chromium;
  
  # Toggle for the custom extension-loading logic
  installExtensions = true; 

  # Extension IDs extracted from your original config
  extensionIds = [
    #"ajopnjidmegmdimjlfnijceegpefgped" # BetterTTV
    #"djdmadneanknadilpjiknlnanaolmbfk" # Copy All Urls
    #"lajiknjoinemadijnpdnjjdmpmpigmge" # Disable YouTube Number Keyboard Shortcuts
    #"kfghpdldaipanmkhfpdcjglncmilendn" # Get RSS Feed URL
    #"oejjgapcbhmlhkiijmadcofhmmfebmec" # Insecure Links Highlighter
    #"edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
    #"cdglnehniifkbagbbombnjghhcihifij" # Kagi Search
    #"oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
    #"mphdppdgoagghpmmhodmfajjlloijnbd" # Pinboard Plus
    #"pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
    #"hdhinadidafjejdhmfkjgnolgimiaplp" # Read Aloud
    #"hlepfoohegkhhmjieoechaddaejaokhf" # Refined GitHub
    #"ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
    #"fpnmgdkabkmnadcjpehmlllkndpkmiak" # Wayback Machine
  ];
in
{
  # 1. Chromium Configuration
  programs.chromium = {
    enable = true;
    package = chromiumPkg;

    # Spellcheck dictionaries
    dictionaries = [
      pkgs.hunspellDictsChromium.de_DE
      pkgs.hunspellDictsChromium.en_GB
      pkgs.hunspellDictsChromium.fr_FR
    ];

    # Extension declarations
    extensions = map (id: { inherit id; }) extensionIds;

    # Command line arguments logic
    commandLineArgs = [
      "--extension-mime-request-handling=always-prompt-for-install"
    ] ++ lib.optionals installExtensions (
      [ "https://github.com/NeverDecaf/chromium-web-store/releases/latest/download/Chromium.Web.Store.crx" ]
      ++ map (id: 
        "https://clients2.google.com/service/update2/crx?response=redirect\\&acceptformat=crx2,crx3\\&prodversion=${chromiumPkg.version}\\&x=id%3D${id}%26uc"
      ) extensionIds
    );
  };

}
