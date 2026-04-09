{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.search;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.search = {
            provider = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "duckduckgo" ]);
              default = null;
              description = "Force a specific default search provider via policy.";
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = lib.mkIf (cfg.provider != null) {
            internal.policies = lib.mkMerge [
              (lib.mkIf (cfg.provider == "duckduckgo") {
                "DefaultSearchProviderEnabled" = true;
                "DefaultSearchProviderSearchURL" = "https://duckduckgo.com/?q={searchTerms}";
                "DefaultSearchProviderSuggestURL" = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
                "SearchSuggestEnabled" = false;
              })
            ];
          };
        }
      )
    );
  };
}
