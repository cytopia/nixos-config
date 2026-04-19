{
  rulePrefix,
  uid,
  ...
}:

let
  gitRemoteHttp = {
    name = "git-remote-http";
    regPath = "^/nix/store/[^/]+-git-.*/libexec/git-core/git-remote-http$";
    uid = "${toString uid}";
  };
  ssh = {
    name = "ssh";
    regPath = "^/nix/store/[^/]+-openssh-.*/bin/ssh$";
    uid = "${toString uid}";
  };


  ###
  ### git
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

  ###
  ### Git over SSH
  ###
  mkGitSsh = name: regexPath: uid: {
    "${rulePrefix}-${name}-${uid}-ssh-git" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "xxx      ${name} [${uid}] -> *:22 [TCP]  (SSH)";
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
            data = "22";
          }
        ];
      };
    };
  };


in
{
  rules = { }
    // mkGitRemoteHttps gitRemoteHttp.name gitRemoteHttp.regPath gitRemoteHttp.uid
    // mkGitSsh ssh.name ssh.regPath ssh.uid
  ;
}


