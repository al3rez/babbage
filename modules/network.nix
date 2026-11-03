{ lib, pkgs, ... }:

let
  # Cloudflare first: Thai ISP resolvers (203.144.207.x) poison/block some domains via
  # 125.26.170.3; Tailscale MagicDNS forwards to NM upstreams in order.
  v4 = "1.1.1.1,1.0.0.1";
  v6 = "2606:4700:4700::1111,2606:4700:4700::1001";
  applyDns = ''
    for id in $(nmcli -t -f UUID,TYPE connection show | awk -F: '$2 == "802-11-wireless" { print $1 }'); do
      nmcli connection modify "$id" \
        ipv4.dns "${v4}" ipv4.ignore-auto-dns yes \
        ipv6.dns "${v6}" ipv6.ignore-auto-dns yes
    done
    active=$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2 == "802-11-wireless" { print $1; exit }')
    if [ -n "$active" ]; then
      nmcli connection up "$active" >/dev/null 2>&1 || true
    fi
  '';
in
{
  home.activation.wifiDns = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v nmcli >/dev/null 2>&1; then
      ${applyDns}
    fi
  '';
}
