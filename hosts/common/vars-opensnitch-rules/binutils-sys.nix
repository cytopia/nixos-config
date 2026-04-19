{
  rulePrefix,
  uid,
  ...
}:

let
  gitRemoteHttp = {
    name = "git-remote-http";
    regPath = "^/nix/store/[^/]+-git-.*/libexec/git-core/git-remote-http$";
    uid = uid;
  };


  ###
  ### nix flake update
  ###
  mkGitRemoteHttps = name: regexPath: uid: {
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
    // mkGitRemoteHttps gitRemoteHttp.name gitRemoteHttp.regPath "${toString gitRemoteHttp.uid}"
  ;
}


