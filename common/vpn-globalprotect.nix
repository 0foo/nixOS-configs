{ config, pkgs, lib, ... }:

let
  # vpn.tulane.edu authenticates via Palo Alto's Cloud Authentication Service
  # (CAS) -> Entra ID, and enforces a HIP posture check. Satisfying both at
  # once is the whole problem:
  #
  #   * CAS ends the SAML flow at a custom-scheme URL,
  #     `globalprotectcallback:cas-as=1&un=<user>&token=<JWT>`. openconnect
  #     only consumes that when the frontend supplies a webview; the bare CLI
  #     reports "No SSO handler" (library.c) and quits.
  #
  #   * HIP needs openconnect's --csd-wrapper to answer the gateway's
  #     hipreportcheck.esp. Without it openconnect only warns and connects
  #     anyway -- which is exactly the "authenticates but no traffic" symptom,
  #     because the gateway quarantines a client that owes it a HIP report.
  #
  # NetworkManager cannot do the second one: nm-openconnect-service.c gates the
  # --csd-wrapper branch behind `if (FALSE && priv->tun_name)`, hard-disabled
  # upstream pending a sandboxing story, so it always logs "won't call
  # csd-wrapper script" and skips HIP. No amount of configuration reaches it.
  #
  # So the two phases are split: gp-saml-gui supplies the webview and converts
  # the CAS callback into a login.esp `token` field, then hands off to the
  # openconnect CLI, which does the HIP submission.
  gp-saml-gui-cas = pkgs.gp-saml-gui.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./pkgs/gp-saml-gui-cas.patch ];
  });

  # Submitting a HIP report is necessary but not sufficient: the gateway also
  # evaluates its contents. openconnect's stock report claims the firewall is
  # disabled and the host is Fedora 32, which fails Tulane's posture policy and
  # leaves the session able to reach only DNS and the portal itself. This one
  # reports what the machine actually is. See the derivation for what it does
  # and deliberately does not claim.
  tulane-hipreport = pkgs.callPackage ./pkgs/tulane-hipreport.nix { };

  # The CAS token is single-use and expires in ~60s, so the browser handoff and
  # the connect have to happen in one shot -- hence --sudo-openconnect rather
  # than printing a command to paste.
  #
  # The bare `--` is required: openconnect_extra is an argparse positional
  # (nargs='*'), so a `--`-prefixed token lands in it only after an explicit
  # end-of-options marker. Without it argparse rejects --csd-wrapper outright
  # instead of forwarding it.
  gp-tulane = pkgs.writeShellScriptBin "gp-tulane" ''
    exec ${gp-saml-gui-cas}/bin/gp-saml-gui \
      --gateway \
      -f cas-support=yes \
      --sudo-openconnect \
      vpn.tulane.edu \
      -- \
      --csd-wrapper=${tulane-hipreport}/libexec/tulane-hipreport.sh \
      "$@"
  '';
in
{
  # Kept for the GNOME network panel, which handles CAS fine on its own but
  # cannot submit the HIP report -- useful for diagnosis, not for daily use.
  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

  # NetworkManager-openconnect's D-Bus policy references this account; nixpkgs
  # creates nm-openvpn and nm-iodine but not this one, so dbus-broker logs
  # "Invalid user-name in ... nm-openconnect-service.conf" on every start.
  users.users.nm-openconnect = {
    isSystemUser = true;
    group = "nm-openconnect";
    description = "NetworkManager OpenConnect VPN service";
  };
  users.groups.nm-openconnect = { };

  networking.networkmanager.ensureProfiles.profiles."Tulane VPN" = {
    connection = {
      id = "Tulane VPN";
      type = "vpn";
      uuid = "7c4f2e18-9b3a-4d61-8e52-1a0f6d3b9c40";
      autoconnect = false;
      permissions = "user:nick:;";
    };
    vpn = {
      service-type = "org.freedesktop.NetworkManager.openconnect";
      gateway = "vpn.tulane.edu";
      protocol = "gp";
      # Secret flag 2 = not-saved, re-ask each time. Correct here: the CAS
      # token is single-use and short-lived, so caching it is useless.
      gwcert-flags = "2";
      cookie-flags = "2";
      gateway-flags = "2";
      resolve-flags = "2";
    };
    ipv4.method = "auto";
    ipv6.method = "auto";
  };

  environment.systemPackages = [
    pkgs.openconnect
    gp-saml-gui-cas
    gp-tulane
  ];
}
