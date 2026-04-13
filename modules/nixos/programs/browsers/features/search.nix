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
              type = lib.types.nullOr (
                lib.types.enum [
                  "duckduckgo"
                  "brave"
                  "startpage"
                  "ecosia"
                  "google"
                ]
              );
              default = null;
              description = "Force a specific default search provider via policy.";
            };
            disableSearchSuggestions = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disables live search suggestions in the omnibox.
                Stops the browser from sending every single keystroke you type to your default
                search engine before you press Enter.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = lib.mkIf (cfg.provider != null) {
            internal.policies = lib.mkMerge [
              (lib.mkIf (cfg.provider != null) {
                "DefaultSearchProviderEnabled" = true;

                "DefaultSearchProviderSearchURL" =
                  if cfg.provider == "duckduckgo" then
                    "https://duckduckgo.com/?q={searchTerms}"
                  else if cfg.provider == "brave" then
                    "https://search.brave.com/search?q={searchTerms}"
                  else if cfg.provider == "startpage" then
                    "https://www.startpage.com/sp/search?q={searchTerms}"
                  else if cfg.provider == "ecosia" then
                    "https://www.ecosia.org/search?q={searchTerms}"
                  else
                    "{google:baseURL}search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}{google:contextualSearchVersion}ie={inputEncoding}";

                "DefaultSearchProviderSuggestURL" =
                  if cfg.provider == "duckduckgo" then
                    "https://duckduckgo.com/ac/?q={searchTerms}&type=list"
                  else if cfg.provider == "brave" then
                    "https://search.brave.com/api/suggest?q={searchTerms}"
                  else if cfg.provider == "startpage" then
                    "https://www.startpage.com/cgi-bin/csuggest?query={searchTerms}"
                  else if cfg.provider == "ecosia" then
                    "https://ac.ecosia.org/autocomplete?q={searchTerms}"
                  else
                    "{google:baseURL}complete/search?output=chrome&q={searchTerms}";
              })

              (lib.mkIf cfg.disableSearchSuggestions {
                "SearchSuggestEnabled" = false;
              })
            ];
          };
        }
      )
    );
  };
}
