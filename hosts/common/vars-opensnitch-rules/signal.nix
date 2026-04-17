{
  rulePrefix,
  uid,
  ...
}:

let
  name = "Signal";
  regexPath = "^/nix/store/[^/]+-electron-unwrapped-.*/libexec/electron/electron$";

  ###
  ### Local DNS [UDP]
  ###
  mkLocalDns = name: regexPath: uid: {
    "${rulePrefix}-${name}-127_0_0_53-udp-53" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${name} [${toString uid}] -> 127.0.0.53:53 [UDP]  (DNS)";
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
            data = "UDP";
          }
          {
            type = "simple";
            operand = "dest.port";
            data = "53";
          }
          {
            type = "simple";
            operand = "dest.ip";
            data = "127.0.0.53";
          }
        ];
      };
    };
  };

  ###
  ### HTTPS-QUIC [TCP/UDP]
  ###
  mkInternetHttps = name: regexPath: uid: {
    "${rulePrefix}-${name}-internet-tcp-udp-443" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${name} [${toString uid}] -> *:443 [TCP|UDP]  (HTTPS-QUIC)";
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
            type = "regexp";
            operand = "protocol";
            data = "^(TCP|UDP)$";
          }
          {
            type = "simple";
            operand = "dest.port";
            data = "443";
          }
        ];
      };
    };
  };

in
{
  rules =
    { }
    // mkInternetHttps name regexPath uid
    // mkLocalDns name regexPath uid
  ;
}

