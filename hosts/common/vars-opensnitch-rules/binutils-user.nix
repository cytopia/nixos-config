{
  rulePrefix,
  uid,
  ...
}:

let
  devbox = {
    name = "devbox";
    regPath = "^/nix/store/[^/]+devbox-.*/bin/devbox$";
    uidUser = "${toString uid}";
  };
  podman = {
    name = "podman";
    regPath = "^/nix/store/[^/]+podman-.*/bin/.podman-wrapped$";
    uidUser = "${toString uid}";
  };
  saml2aws = {
    name = "saml2aws";
    regPath = "^/nix/store/[^/]+saml2aws-.*/bin/saml2aws$";
    uidUser = "${toString uid}";
  };
  awscli = {
    name = "awscli";
    regPath = "^/nix/store/[^/]+python3-.*/bin/python3.*$";
    uidUser = "${toString uid}";
    destHost = "^(.*\\.)?amazonaws\\.com$";
  };
  terraform = {
    name = "terraform";
    regPath = "^/nix/store/[^/]+terraform-.*/bin/terraform$";
    uidUser = "${toString uid}";
  };
  terraformProvider = {
    name = "terraform-provider";
    regPath = "^.*/\\.terraform/providers/.*/terraform-provider-[a-zA-Z0-9\\-]+_v[0-9\\.]+$";
    uidUser = "${toString uid}";
  };
  terragrunt = {
    name = "terragrunt";
    regPath = "^/nix/store/[^/]+terragrunt-.*/bin/terragrunt$";
    uidUser = "${toString uid}";
    destHost = "^(.*\\.)?amazonaws\\.com$";
  };

  ###
  ### Generic HTTPS
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
  ###
  ### Generic HTTPS to *.amazon.com
  ###
  mkBinutilsUserHttpsDestHost = name: regexPath: uid: destHost: {
    "${rulePrefix}-${name}-${uid}-binutils-user-https-${destHost}" = {
      action = "allow";
      precedence = true;
      created = "2025-01-01T00:00:00+00:00";
      updated = "2025-01-01T00:00:00+00:00";
      name = "yyy      ${name} [${uid}] -> *.amazon.com:443 [TCP]  (HTTPS)";
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
          {
            type = "regexp";
            operand = "dest.host";
            data = destHost;
          }
        ];
      };
    };
  };
  mkBinutilsAwsLinkLocal = name: regexPath: uid: {
    "${rulePrefix}-${name}-${uid}-aws-link-local" = {
      action = "allow";
      precedence = true;
      created = "2025-01-01T00:00:00+00:00";
      updated = "2025-01-01T00:00:00+00:00";
      name = "yyy      ${name} [${uid}] -> LINKLOCAL-RFC3927:80 [TCP]  (HTTP)";
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
            data = "80";
          }
          {
            type = "simple";
            operand = "dest.ip";
            data = "169.254.169.254";
          }
        ];
      };
    };
  };

in
{
  rules =
    { }
    // mkBinutilsUserHttps devbox.name devbox.regPath devbox.uidUser
    // mkBinutilsUserHttps podman.name podman.regPath podman.uidUser
    // mkBinutilsUserHttps saml2aws.name saml2aws.regPath saml2aws.uidUser

    // mkBinutilsUserHttps terraform.name terraform.regPath terraform.uidUser
    // mkBinutilsUserHttps terraformProvider.name terraformProvider.regPath terraformProvider.uidUser

    // mkBinutilsUserHttpsDestHost terragrunt.name terragrunt.regPath terragrunt.uidUser terragrunt.destHost

    // mkBinutilsAwsLinkLocal awscli.name awscli.regPath awscli.uidUser
    // mkBinutilsUserHttpsDestHost awscli.name awscli.regPath awscli.uidUser awscli.destHost
    ;
}
