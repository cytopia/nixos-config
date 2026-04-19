{
  rulePrefix,
  uid,
  ...
}:

let
  name = {
    nix = "nix";
  };
  procRegex = {
    nix = "^/nix/store/[^/]+-nix-.*/bin/nix$";
  };
  svc_uid = {
    nix_root = 0;
    nix_user = uid;
  };


  ###
  ### nix flake update
  ###
  mkNixUserFetch = name: regexPath: uid: {
    "${rulePrefix}-${name}-${uid}-fetch-https" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "xxx      ${name} [${uid}] -> *:443 [TCP]  (HTTPS)";
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
            data = "TCP";
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
  rules = { }
    // mkNixUserFetch name.nix procRegex.nix "${toString svc_uid.nix_user}"
    // mkNixUserFetch name.nix procRegex.nix "${toString svc_uid.nix_root}"
  ;
}


