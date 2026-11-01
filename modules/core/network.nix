{ pkgs, ... }:

{
  networking.firewall.enable = true;
  networking.firewall.checkReversePath = false;  
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  # Encrypted DNS over TLS (DoT) with malware & tracker blocking (Quad9 + Cloudflare)
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = "allow-downgrade";
        DNSOverTLS = "true";
      };
    };
  };

  networking.nameservers = [
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
    "1.1.1.1#cloudflare-dns.com"
  ];
}
