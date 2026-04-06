# DNS

## General

### Query DNS
```bash
# Query systemd-resolve
dig @127.0.0.53 -p 53 nixos.org

# Query dnscrypt-proxy
dig @127.0.0.1 -p 5353 nixos.org

# Query through system routing engine
resolvectl query nixos.org
```

### Flush DNS
```bash
sudo resolvectl flush-caches
sudo systemctl restart dnscrypt-proxy.service
chrome://net-internals/#dns
```

### View Logs

```bash
# View the active DNS routing table.
# Look for "Global" showing your 127.0.0.1:5353 IPs and the "~." domain.
resolvectl status

journalctl -u dnscrypt-proxy -fn200
journalctl -u systemd-resolved -fn200

# Firewall logs
journalctl -k -fn200
```

### View Config
```bash
# DNSCrypt config
cat $(systemctl status dnscrypt-proxy | grep '\-config' | awk '{print $NF}')

# systemd-resolved
cat /etc/systemd/resolved.conf

# Unit Files
systemctl cat dnscrypt-proxy.service
systemctl cat dnscrypt-proxy-update-blocklist.service
systemctl cat dnscrypt-proxy-update-blocklist.timer

# Firewall
sudo nft list ruleset
```

## DNSCrypt

### Update block list
```bash
sudo systemctl start dnscrypt-proxy-update-blocklist.service
```

## DNS verification

### Specific Quad9 verification
```bash
curl https://on.quad9.net
```

### Verif ECH (in browser)
* https://www.cloudflare.com/ssl/encrypted-sni/
* https://www.cloudflare.com/cdn-cgi/trace
* https://browserleaks.com/tls
* https://tls.browserleaks.com/
