{
  config,
  lib,
  ...
}:
let
  cfg = config.cytopia.service.dns;

  # https://dnscrypt.info/public-servers/
  ###
  ### Available DNS servers (IPv4)
  ###
  ipv4Servers =
    if cfg.query.protocol == "doh" then
      [
        "quad9-doh-ip4-port443-filter-pri"
        "quad9-doh-ip4-port443-filter-alt"
        "quad9-doh-ip4-port443-filter-alt2"
      ]
    else if cfg.query.protocol == "doh-ecs" then
      [
        "quad9-doh-ip4-port443-filter-ecs-pri"
        "quad9-doh-ip4-port443-filter-ecs-alt"
        "quad9-doh-ip4-port443-filter-ecs-alt2"
      ]
    else if cfg.query.protocol == "dnscrypt" then
      [
        "quad9-dnscrypt-ip4-filter-pri"
        "quad9-dnscrypt-ip4-filter-alt"
        "quad9-dnscrypt-ip4-filter-alt2"
      ]
    else if cfg.query.protocol == "dnscrypt-ecs" then
      [
        "quad9-dnscrypt-ip4-filter-ecs-pri"
        "quad9-dnscrypt-ip4-filter-ecs-alt"
        "quad9-dnscrypt-ip4-filter-ecs-alt2"
      ]
    else if cfg.query.protocol == "odoh" then
      [ "odoh-cloudflare" ] # Quad9 does not natively support ODoH yet
    else
      [ ];

  ###
  ### Available DNS servers (IPv6)
  ###
  ipv6Servers =
    if cfg.query.protocol == "doh" then
      [
        "quad9-doh-ip6-port443-filter-pri"
        "quad9-doh-ip6-port443-filter-alt"
        "quad9-doh-ip6-port443-filter-alt2"
      ]
    else if cfg.query.protocol == "doh-ecs" then
      [
        "quad9-doh-ip6-port443-filter-ecs-pri"
        "quad9-doh-ip6-port443-filter-ecs-alt"
        "quad9-doh-ip6-port443-filter-ecs-alt2"
      ]
    else if cfg.query.protocol == "dnscrypt" then
      [
        "quad9-dnscrypt-ip6-filter-pri"
        "quad9-dnscrypt-ip6-filter-alt"
        "quad9-dnscrypt-ip6-filter-alt2"
      ]
    else if cfg.query.protocol == "dnscrypt-ecs" then
      [
        "quad9-dnscrypt-ip6-filter-ecs-pri"
        "quad9-dnscrypt-ip6-filter-ecs-alt"
        "quad9-dnscrypt-ip6-filter-ecs-alt2"
      ]
    else if cfg.query.protocol == "odoh" then
      [ ] # TODO: Nothing available
    else
      [ ];

  ###
  ### Available Relays
  ###
  ### https://status.dnscrypt.info/?type=relay
  ipv4Relays = [
    { server_name = "quad9-dnscrypt-ip4-filter-ecs-pri"; via = [ "anon-cs-berlin" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-ecs-alt"; via = [ "anon-cs-berlin" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-ecs-alt2"; via = [ "anon-cs-berlin" ]; }

    { server_name = "quad9-dnscrypt-ip4-filter-pri"; via = [ "dnscry.pt-anon-jena-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-alt"; via = [ "dnscry.pt-anon-jena-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip4-filter-alt2"; via = [ "dnscry.pt-anon-jena-ipv4" ]; }

    { server_name = "quad9-dnscrypt-ip6-filter-ecs-pri"; via = [ "anon-cs-berlin" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-ecs-alt"; via = [ "anon-cs-berlin" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-ecs-alt2"; via = [ "anon-cs-berlin" ]; }

    { server_name = "quad9-dnscrypt-ip6-filter-pri"; via = [ "anon-cs-dus" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-alt"; via = [ "dnscry.pt-anon-bremen-ipv4" ]; }
    { server_name = "quad9-dnscrypt-ip6-filter-alt2"; via = [ "dnscry.pt-anon-dusseldorf-ipv4" ]; }

    { server_name = "cs-de"; via = [ "dnscry.pt-anon-dusseldorf03-ipv4" ]; }
    { server_name = "ffmuc.net"; via = [ "dnscry.pt-anon-frankfurt02-ipv4" ]; }
    { server_name = "ffmuc.net-v6"; via = [ "dnscry.pt-anon-jena-ipv4" ]; }
    { server_name = "dnscry.pt-frankfurt02-ipv4"; via = [ "dnscry.pt-anon-munich-ipv4" ]; }
    { server_name = "dnscry.pt-frankfurt02-ipv6"; via = [ "dnscry.pt-anon-nuremberg-ipv4" ]; }
    { server_name = "*"; via = [ "anon-cs-berlin" ]; }
  ];
  # TODO:
  # High timeout relays:
  # * dnscry.pt-anon-dusseldorf02-ipv4
  # * anon-cs-de
  # Stable relays:
  # * anon-cs-berlin
  # * dnscry.pt-anon-frankfurt02-ipv4
  # * dnscry.pt-anon-bremen-ipv4

  relayedServer = builtins.map (x: x.server_name) ipv4Relays;

  ###
  ### Final DNS Server list
  ###
  activeServerNames = if cfg.query.viaProxy then
    # Filter out "*" from server_names. If "*" is present in this list, the proxy
    # connects to ANY server in the sources, breaking the "Strict Control" logic.
    builtins.filter (n: n != "*") relayedServer
  else
    ipv4Servers ++ (lib.optionals cfg.query.ipv6 ipv6Servers);

in
{
  config = lib.mkIf cfg.enable {

   assertions = [
      {
        assertion = cfg.query.viaProxy -> (cfg.query.protocol == "dnscrypt" || cfg.query.protocol == "dnscrypt-ecs");
        message = ''
          [DNS Module Error]: 'viaProxy' (Relays) requires the 'dnscrypt' protocol.
          It is not compatible with 'doh' or 'odoh'.
        '';
      }
    ];


    services.dnscrypt-proxy.settings = {

      # (OPTION-B): Static Server List
      # By defining an exact list of servers, we enforce strict control over
      # where our traffic goes.
      server_names = activeServerNames;

    } // lib.optionalAttrs cfg.query.viaProxy {

      # ==========================================================
      # ANONYMIZER / PROXIES
      # ==========================================================
      anonymized_dns = {
        # if a server cannot accept traffic through a relay, do not bypass the relay.
        # Drop that server entirely and pretend it doesn't exist.
        skip_incompatible = true;
        routes = ipv4Relays;
      };

    };

  };
}
