{
  rulePrefix,
  ...
}:

let
  name = "chrony";
  regexPath = "^/nix/store/[^/]+-chrony.*/bin/chronyd$";
  svc_uid = 61;


  ###
  ### NTS Key Exchange
  ###
  mkInternetNtsKe = name: regexPath: uid: {
    "${rulePrefix}-${name}-nts-ke" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "002      ${name} [${toString uid}] -> *:4460 [TCP]  (NTS-KE)";
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
            data = "4460";
          }
        ];
      };
    };
  };

  ###
  ### NTP
  ###
  mkInternetNtp = name: regexPath : uid: {
    "${rulePrefix}-${name}-ntp" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "002      ${name} [${toString uid}] -> *:123|4123 [UDP]  (NTP)";
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
            data = "udp";
          }
          {
            type = "regexp";
            operand = "dest.port";
            data = "^(123|4123)$";
          }
        ];
      };
    };
  };

in
{
  rules = { }
    // mkInternetNtsKe name regexPath svc_uid
    // mkInternetNtp name regexPath svc_uid
  ;
}


