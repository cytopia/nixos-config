{
  rulePrefix,
  uid,
  ...
}:

let
  name = {
    dnscrypt = "dnscrypt-proxy";
    resolved = "systemd-resolved";
  };
  procRegex = {
    dnscrypt = "^/nix/store/[^/]+-dnscrypt-proxy.*/bin/dnscrypt-proxy$";
    resolved = "^/nix/store/[^/]+-systemd-.*/lib/systemd/systemd-resolved$";
  };
  svc_uid = {
    resolved = "153";
  };


  ###
  ### DNSCrypt Proxy
  ###
  mkDnscryptDnscrypt = name: regexPath: {
    "${rulePrefix}-${name}-dnscrypt" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "000      ${name} -> *:8443 [UDP]  (DNSCrypt)";
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
            operand = "protocol";
            data = "udp";
          }
          {
            type = "simple";
            operand = "dest.port";
            data = "8443";
          }
        ];
      };
    };
  };
  mkDnscryptHttps = name: regexPath: {
    "${rulePrefix}-${name}-https" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "000      ${name} -> *:443 [TCP-UDP]  (HTTPS-QUIC)";
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

  ###
  ### SystemdResolved
  ###
  mkResolvedDns = name: regexPath: uid: {
    "${rulePrefix}-${name}-localhost-5353" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "000      ${name} [${toString uid}] -> localhost:5353 [TCP]  (DNS)";
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
            operand = "dest.port";
            data = "5353";
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
  ### Denies
  ###
  mkDenyCloudflare = name: uid: {
    "${rulePrefix}-${name}-cloudflare" = {
      action = "deny";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "001      [${toString uid}] -> 1.1.1.1|1.0.0.1";
      enabled = true;
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = [
          {
            type = "simple";
            operand = "user.id";
            data = uid;
          }
          {
            type = "regexp";
            operand = "dest.ip";
            data = "^(1\\.1\\.1\\.1|1\\.0\\.0\\.1)$";
          }
        ];
      };
    };
  };
  mkDenyGoogle = name: uid: {
    "${rulePrefix}-${name}-google" = {
      action = "deny";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "001      [${toString uid}] -> 8.8.8.8|8.8.4.4";
      enabled = true;
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = [
          {
            type = "simple";
            operand = "user.id";
            data = uid;
          }
          {
            type = "regexp";
            operand = "dest.ip";
            data = "^(8\\.8\\.8\\.8|8\\.8\\.4\\.4)$";
          }
        ];
      };
    };
  };




in
{
  rules = { }
    // mkDnscryptDnscrypt name.dnscrypt procRegex.dnscrypt
    // mkDnscryptHttps name.dnscrypt procRegex.dnscrypt
    // mkResolvedDns name.resolved procRegex.resolved svc_uid.resolved
    // mkDenyCloudflare "dns" "${toString uid}"
    // mkDenyGoogle "dns" "${toString uid}"
  ;
}


