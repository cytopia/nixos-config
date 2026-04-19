{
  rulePrefix,
  uid,
  ...
}:

let
  devbox = {
    name = "devbox";
    regPath = "^/nix/store/[^/]+devbox-.*/bin/devbox$";
    uid_user = "${toString uid}";
  };


  ###
  ### Devbox
  ###
  mkBinutilsUserHttps = name: regexPath: uid: {
    "${rulePrefix}-${name}-${uid}-binutils-user-https" = {
      action = "allow";
      precedence = true;
      created = "2025-01-01T00:00:00+00:00";
      updated = "2025-01-01T00:00:00+00:00";
      name = "yyy      ${name} [${uid}] -> *:443 [TCP]  (HTTPS)";
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
    // mkBinutilsUserHttps devbox.name devbox.regPath devbox.uid_user
  ;
}
