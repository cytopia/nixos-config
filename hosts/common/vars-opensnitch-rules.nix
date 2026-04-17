{
  lib,
  rulePrefix,
  enableBrave,
  enableChrome,
  enableChromium,
  uid,
  ...
}:

let
  browserRules =
    (import ./vars-opensnitch-rules/browsers.nix {
      inherit lib;
      inherit rulePrefix;
      inherit enableBrave;
      inherit enableChrome;
      inherit enableChromium;
      inherit uid;
    }).rules;

  thunderbirdRules =
    (import ./vars-opensnitch-rules/thunderbird.nix {
      inherit rulePrefix;
      inherit uid;
    }).rules;

  dnsRules =
    (import ./vars-opensnitch-rules/dns.nix {
      inherit rulePrefix;
      inherit uid;
    }).rules;
in
{
  rules = { }
    // browserRules
    // thunderbirdRules
    // dnsRules
    ;
}
