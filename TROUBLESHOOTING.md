# Troubleshooting


## Networking

### NTP
```bash
systemctl status chronyd
journalctl -u chronyd
sudo chronyc tracking
sudo chronyc sources -v
sudo chronyc sourcestats -v
sudo chronyc authdata
sudo chronyc serverstats
sudo chronyc activity
sudo chronyc ntpdata
```

### DNS
Check the Proxy Directly (Bypass resolved)
```bash
# Query your proxy directly on your custom port
dig @127.0.0.1 -p 5353 google.com

# Watch the proxy's live logs to see it calculate the fastest server
journalctl -u dnscrypt-proxy -f
```

Check Routing Engine
```bash
# View the active DNS routing table.
# Look for "Global" showing your 127.0.0.1:5353 IPs and the "~." domain.
resolvectl status

# Force a test query through the system routing engine.
# Look at the bottom of the output for "Server: 127.0.0.1#5353".
resolvectl query nixos.org
```

Specific Quad9 verification
```bash
curl https://on.quad9.net
```

Verif ECH (in browser)
* https://www.cloudflare.com/ssl/encrypted-sni/
* https://www.cloudflare.com/cdn-cgi/trace
* https://browserleaks.com/tls
* https://tls.browserleaks.com/

## Flush DNS
```bash
sudo resolvectl flush-caches
sudo systemctl restart dnscrypt-proxy.service
chrome://net-internals/#dns
```

## Check config
```
cat $(systemctl status dnscrypt-proxy | grep '\-config' | awk '{print $NF}')
cat /etc/systemd/resolved.conf
```


## GUI

### Logs
```bash
# Session
journalctl -u greetd
```
