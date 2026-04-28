{
  lib,
  rulePrefix,
  enableBrave,
  enableChrome,
  enableChromium,
  uid,
  ...
}:

let
  name = {
    brave = "Brave";
    chrome = "Google Chrome";
    chromium = "Chromium";
  };
  procRegex = {
    brave = "^/nix/store/[^/]+-brave-.*/opt/brave.com/brave/brave$";
    chrome = "^/nix/store/[^/]+-google-chrome-.*/share/google/chrome/chrome$";
    chromium = "^/nix/store/[^/]+-chromium-unwrapped-.*/libexec/chromium/chromium$";
  };


  ###
  ### Deny: TCP 5228
  ###
  mkDenyTcp5288 = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-deny-tcp-5228" = {
      action = "reject";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "100      ${browserName} [${toString uid}] -> *:5228 [TCP]";
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
            data = "5228";
          }
        ];
      };
    };
  };

  ###
  ### Deny: firebaseremoteconfig.googleapis.com
  ###
  mkDeny_firebaseRemoteConfig = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-deny-firebaseremoteconfig-tcp-443" = {
      action = "reject";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "100      ${browserName} [${toString uid}] -> firebaseremoteconfig.googleapis.com:80|443 [TCP|UDP]";
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
            operand = "dest.host";
            data = "firebaseremoteconfig.googleapis.com";
          }
          {
            type = "regexp";
            operand = "dest.port";
            data = "^(80|443)$";
          }
        ];
      };
    };
  };




  ###
  ### localhost connection
  ###
  mkLocalhost = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-localhost" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> localhost:*";
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
            operand = "dest.ip";
            data = "^(::1|127\\.0\\.0\\.1)$";
          }
        ];
      };
    };
  };

  ###
  ### HTTP [TCP]
  ###
  mkInternetHttpTcp = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-internet-80-tcp-http" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> *:80 [TCP]  (HTTP)";
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
            data = "80";
          }
        ];
      };
    };
  };

  ###
  ### HTTPS [TCP/UDP]
  ###
  mkInternetHttps = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-internet-443-https" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> *:443 [TCP-UDP]  (HTTPS-QUIC)";
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

  ###
  ### WebRTC STUN-TURN
  ###
  ### Standard NAT traversal. Allows WebRTC to discover your public IP (STUN) or relay media
  ### in plaintext (TURN) when direct P2P fails.
  mkInternetWebRcStunTurn = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-internet-3478-3479-webrtc-stun-turn" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> *:3478|3479 [TCP|UDP]  (WebRTC - STUN-TURN)";
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
            type = "regexp";
            operand = "dest.port";
            data = "^(3478|3479)$";
          }
        ];
      };
    };
  };
  ###
  ### WebRTC STUN-TURN (Secure)
  ###
  ### SSL variants of STUN/TURN
  mkInternetWebRcStunTurnSecure = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-internet-5349-webrtc-stun-turn-secure" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> *:5349 [TCP|UDP]  (WebRTC - STUN-TURN SSL)";
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
            data = "5349";
          }
        ];
      };
    };
  };
  ###
  ### WebRTC Google Fallback STUN
  ###
  mkInternetWebRcGoogleFallbackStun = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-internet-udp-webrtc-google-fallback-stun" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> *:1930[2-9] [TCP|UDP]  (WebRTC - Google Fallback STUN)";
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
            type = "regexp";
            operand = "dest.port";
            data = "^(1930[2-9])$";
          }
        ];
      };
    };
  };

  ###
  ### WebRTC Jitsi [UDP]
  ###
  mkInternetWebRcJitsiUdp = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-internet-3478-5349-udp-webrtc-jitsi" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> *:10000 [UDP]  (WebRTC - Jitsi)";
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
            type = "simple";
            operand = "dest.port";
            data = "10000";
          }
        ];
      };
    };
  };
  ###
  ### WebRTC Ephemeral (P2P)
  ###
  mkInternetWebRcEphemeral = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-internet-webrtc-ephemeral-p2p" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> *:10000-65535 [UDP]  (WebRTC - Ephemeral|P2P)";
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
            # Matches exactly 10000 through 65535
            # TODO: Update to 'range' once using OpenSnitch > v1.90
            data = "^(1[0-9]{4}|[2-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$";
          }
        ];
      };
    };
  };

  ###
  ### WhatsApp TCP 5222
  ###
  mkAllowWhatsApp5222 = browserName: regexPath: uid: {
    "${rulePrefix}-${browserName}-allow-whatsapp-5222-tcp" = {
      action = "allow";
      precedence = true;
      created = "2026-01-01T00:00:00+00:00";
      updated = "2026-01-01T00:00:00+00:00";
      name = "${browserName} [${toString uid}] -> *:5222 [TCP] (WhatsApp)";
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
            data = "5222";
          }
        ];
      };
    };
  };



in
{
  rules =
    { }
    # Deny
    // lib.optionalAttrs enableChrome (mkDenyTcp5288 name.brave procRegex.brave uid)
    // lib.optionalAttrs enableChrome (mkDenyTcp5288 name.chrome procRegex.chrome uid)
    // lib.optionalAttrs enableChrome (mkDenyTcp5288 name.chromium procRegex.chromium uid)

    // lib.optionalAttrs enableBrave (mkDeny_firebaseRemoteConfig name.brave procRegex.brave uid)
    // lib.optionalAttrs enableChromium (mkDeny_firebaseRemoteConfig name.chromium procRegex.chromium uid)

    # Localhost
    // lib.optionalAttrs enableBrave (mkLocalhost name.brave procRegex.brave uid)
    // lib.optionalAttrs enableChrome (mkLocalhost name.chrome procRegex.chrome uid)
    // lib.optionalAttrs enableChromium (mkLocalhost name.chromium procRegex.chromium uid)

    # HTTP
    // lib.optionalAttrs enableBrave (mkInternetHttpTcp name.brave procRegex.brave uid)
    // lib.optionalAttrs enableChrome (mkInternetHttpTcp name.chrome procRegex.chrome uid)
    // lib.optionalAttrs enableChromium (mkInternetHttpTcp name.chromium procRegex.chromium uid)

    # HTTPS-QUIC
    // lib.optionalAttrs enableBrave (mkInternetHttps name.brave procRegex.brave uid)
    // lib.optionalAttrs enableChrome (mkInternetHttps name.chrome procRegex.chrome uid)
    // lib.optionalAttrs enableChromium (mkInternetHttps name.chromium procRegex.chromium uid)

    # WebRTC
    // lib.optionalAttrs enableChrome (mkInternetWebRcStunTurn name.chrome procRegex.chrome uid)
    // lib.optionalAttrs enableChrome (mkInternetWebRcStunTurnSecure name.chrome procRegex.chrome uid)
    // lib.optionalAttrs enableChrome (mkInternetWebRcGoogleFallbackStun name.chrome procRegex.chrome uid)
    // lib.optionalAttrs enableChrome (mkInternetWebRcJitsiUdp name.chrome procRegex.chrome uid)
    // lib.optionalAttrs enableChrome (mkInternetWebRcEphemeral name.chrome procRegex.chrome uid)

    # WhatsApp
    // lib.optionalAttrs enableChromium (mkAllowWhatsApp5222 name.chromium procRegex.chromium uid)

  ;
}
