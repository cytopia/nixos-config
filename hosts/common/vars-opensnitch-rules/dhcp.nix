{
  rulePrefix,
  ...
}:

let
  name = {
    nm = "NetworkManager";
  };
  procRegex = {
    nm = "^/nix/store/[^/]+-networkmanager-.*/bin/NetworkManager$";
  };
  svc_uid = {
    nm = "0";
  };


  ###
  ### DNSCrypt Proxy
  ###
  mkDhcp = name: regexPath: uid: {
    "${rulePrefix}-${name}-dhcp" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "002      ${name} [${uid}] -> *:67 [UDP]  (DHCP)";
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
            data = uid;
          }
          {
            type = "simple";
            operand = "protocol";
            data = "UDP";
          }
          {
            type = "simple";
            operand = "dest.port";
            data = "67";
          }
        ];
      };
    };
  };


in
{
  rules = { }
    // mkDhcp name.nm procRegex.nm svc_uid.nm
  ;
}


