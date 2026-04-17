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
  dnsRules =
    (import ./vars-opensnitch-rules/dns.nix {
      inherit rulePrefix;
      inherit uid;
    }).rules;

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

  signalRules =
    (import ./vars-opensnitch-rules/signal.nix {
      inherit rulePrefix;
      inherit uid;
    }).rules;

  telegramRules =
    (import ./vars-opensnitch-rules/telegram.nix {
      inherit rulePrefix;
      inherit uid;
    }).rules;

  slackRules =
    (import ./vars-opensnitch-rules/slack.nix {
      inherit rulePrefix;
      inherit uid;
    }).rules;

  awsVpnClientRules =
    (import ./vars-opensnitch-rules/awsvpnclient.nix {
      inherit rulePrefix;
      inherit uid;
    }).rules;

in
{
  rules = { }
    // dnsRules
    // browserRules
    // thunderbirdRules
    // signalRules
    // telegramRules
    // slackRules
    // awsVpnClientRules
    ;
}
