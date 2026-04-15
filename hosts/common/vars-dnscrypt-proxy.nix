{
  dnscryptQuery,
  dnscryptLocalDoh,
  ...
}:

let

  ###
  ### DNS Query Settings
  ###
  query = {
    #protocol = "dnscrypt-ecs";
    #protocol = "doh";
    protocol = dnscryptQuery.protocol;
    http3 = true;
    ipv6 = false;
    viaProxy = dnscryptQuery.viaProxy;
  };

  ###
  ### Local DNS over HTTPS Settings
  ###
  certs = {
    caCertPath = "/run/local-doh-ca/rootCA.pem";
  };

  # Enable local DoH server (see let..in for options)
  localDoh = {
    enable = dnscryptLocalDoh.enable;
    port = dnscryptLocalDoh.port;
    path = dnscryptLocalDoh.path;

  };

  localBlockList = {
    enable = true;
    urls = [
      # Info at https://firebog.net/
      "https://download.dnscrypt.info/blacklists/domains/mybase.txt"
      "https://v.firebog.net/hosts/AdguardDNS.txt"
      "https://v.firebog.net/hosts/Admiral.txt"
      "https://v.firebog.net/hosts/Easylist.txt"
      "https://v.firebog.net/hosts/Easyprivacy.txt"
      "https://v.firebog.net/hosts/Prigent-Ads.txt"
      "https://v.firebog.net/hosts/static/w3kbl.txt"
      "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
      "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
      "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
      "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
      "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
      "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
      "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
      "https://adaway.org/hosts.txt"
      "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
      "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
    ];
  };
  whitelist = [
    "ip-api.com"
    "ogads-pa.clients6.google.com"
    "csi.gstatic.com"
    "mail-ads.google.com"
  ];
  localMonitoring = {
    enable = true;
    port = 4400;
  };

in
{
  settings = {
    inherit query;
    inherit certs;
    inherit localDoh;
    inherit localMonitoring;
    inherit localBlockList;
    inherit whitelist;
  };
}
