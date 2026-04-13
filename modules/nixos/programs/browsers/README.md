# NixOS Browser module


## Policies
* https://chromeenterprise.google/policies/
* https://chromeenterprise.google/policies/atomic-groups/


## Systemd services

| Name                              | Description                       |
|-----------------------------------|-----------------------------------|
| sync-nssdb-dnscrypt-proxy.path    | The certificate file watcher      |
| sync-nssdb-dnscrypt-proxy.service | The certificate injection script  |
| cleanup-nssdb-certs.service       | The certificate garbage collector |

```bash
# Show status
systemctl --user status sync-nssdb-dnscrypt-proxy.path
systemctl --user status sync-nssdb-dnscrypt-proxy.service
systemctl --user status cleanup-nssdb-certs.service

# Show logs
journalctl --user -u sync-nssdb-dnscrypt-proxy.path
journalctl --user -u sync-nssdb-dnscrypt-proxy.service
journalctl --user -u cleanup-nssdb-certs.service
```

Example to trust a certificate created in a path by dnscrypt-proxy:
```nix
 cytopia.programs.browsers.brave = {
    enable = true;
    features.certificates.customCaCerts = [
      {
        name = "dnscrypt-proxy";
        path = "/run/local-doh-ca/rootCA.pem";
      }
    ];
};
```
