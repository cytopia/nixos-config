{
  rulePrefix,
  uid,
  ...
}:

let
  name = "Thunderbird";
  regexPath = "^/nix/store/[^/]+-thunderbird-.*/lib/thunderbird/thunderbird$";

  ###
  ### localhost connection
  ###
  mkLocalhostDnsOverHttps = name: regexPath: uid: {
    "${rulePrefix}-${name}-localhost-dns-over-https" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${name} [${toString uid}] -> 127.0.0.1:3000 [TCP]  (DNS over HTTPS)";
      enabled = true;
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = [
          {
            type = "regexp";
            operand = "process.path";
            data = regexPath;
          }
          {
            type = "simple";
            operand = "user.id";
            data = "${toString uid}";
          }
          {
            type = "simple";
            operand = "protocol";
            data = "tcp";
          }
          {
            type = "simple";
            operand = "dest.port";
            data = "3000";
          }
          {
            type = "regexp";
            operand = "dest.ip";
            data = "^(::1|127\\.0\\.0\\.1)$";
          }
        ];
      };
    };
  };

  ###
  ### HTTPS/SMPTS/IMAPS [TCP]
  ###
  mkInternetMailTcp = name: regexPath: uid: {
    "${rulePrefix}-${name}-internet-tcp-443-587-993" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${name} [${toString uid}] -> *:(443|587|993) [TCP]  (HTTPS-SMTPS-IMAPS)";
      enabled = true;
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = [
          {
            type = "regexp";
            operand = "process.path";
            data = regexPath;
          }
          {
            type = "simple";
            operand = "user.id";
            data = "${toString uid}";
          }
          {
            type = "simple";
            operand = "protocol";
            data = "tcp";
          }
          {
            type = "regexp";
            operand = "dest.port";
            data = "^(443|587|993)$";
          }
        ];
      };
    };
  };

in
{
  rules =
    { }
    // mkLocalhostDnsOverHttps name regexPath uid
    // mkInternetMailTcp name regexPath uid
  ;
}

