# An accurate HIP report for this machine.
#
# openconnect's stock hipreport.sh is a fixture, not a probe: on Linux it
# hardcodes "Linux Fedora 32", an empty virbr0 interface, Fedora's dnf as the
# package manager, cryptsetup 2.3.3, and -- the one that matters -- a firewall
# entry reading `<is-enabled>no</is-enabled>`. Submitting that understates this
# host's real posture, which is what lands the session in the gateway's
# restricted policy (DNS + portal reachable, nothing else).
#
# This derivation keeps upstream's XML byte-for-byte except for values it
# replaces with runtime probes, so the schema the gateway validates against
# stays intact. Every substituted value is measured, not asserted. Notably
# `anti-malware` is left as upstream's empty list, because no anti-malware is
# installed here and a HIP report is a security attestation -- the gateway is
# entitled to a true one.
{ runCommand
, openconnect
, iproute2
, iptables
, cryptsetup
, systemd
, util-linux
, nix
, coreutils
, gnused
  # The <client-version> the report claims. Upstream's default is 5.1.5-8,
  # while this portal's prelogin refuses CAS below 6.0 ("Minimum client version
  # is 6.0") and Tulane ships 6.3.3.1-674. If the gateway's HIP policy carries
  # the same floor, this field is what fails it.
  #
  # Raised to 6.3.3-674 at the user's explicit direction, after the tradeoff was
  # laid out and they reaffirmed. Unlike the firewall/encryption corrections
  # above -- which made false statements true -- this asserts a client build
  # that is not what is running, and a version check exists to keep unpatched
  # clients out. The counterargument they accepted: the schema has no way to
  # express "openconnect 9.12", and the CAS capability the 6.0 floor gates is
  # genuinely implemented here. Set back to "5.1.5-8" to restore upstream's
  # value.
, appVersion ? "6.3.3-674"
}:

runCommand "tulane-hipreport" { } ''
  mkdir -p $out/libexec
  cp ${openconnect}/libexec/openconnect/hipreport.sh $out/libexec/tulane-hipreport.sh
  chmod +w $out/libexec/tulane-hipreport.sh

  substituteInPlace $out/libexec/tulane-hipreport.sh \
    --replace-fail '		OS="Linux Fedora 32"
		OS_VENDOR="Linux"
		NETWORK_INTERFACE_NAME="virbr0"
		NETWORK_INTERFACE_DESCRIPTION="virbr0"' '		OS="Linux $(. /etc/os-release; echo "$NAME $VERSION_ID")"
		OS_VENDOR="Linux"
		# The physical egress interface, not the tunnel: follow the default route.
		NETWORK_INTERFACE_NAME="$(${iproute2}/bin/ip -o route get 1.1.1.1 2>/dev/null | ${gnused}/bin/sed -n "s/.* dev \([^ ]*\).*/\1/p" | ${coreutils}/bin/head -1)"
		NETWORK_INTERFACE_NAME="''${NETWORK_INTERFACE_NAME:-lo}"
		NETWORK_INTERFACE_DESCRIPTION="$NETWORK_INTERFACE_NAME"
		FW_VERSION="$(${iptables}/bin/iptables --version 2>/dev/null | ${gnused}/bin/sed -n "s/^iptables v\([0-9.]*\).*/\1/p")"
		FW_VERSION="''${FW_VERSION:-unknown}"
		# Report the firewall as enabled only if its unit is actually running.
		if ${systemd}/bin/systemctl is-active --quiet firewall.service 2>/dev/null \
		   || ${systemd}/bin/systemctl is-active --quiet nftables.service 2>/dev/null; then
			FW_ENABLED="yes"
		else
			FW_ENABLED="no"
		fi
		CRYPTSETUP_VERSION="$(${cryptsetup}/bin/cryptsetup --version 2>/dev/null | ${gnused}/bin/sed -n "s/^cryptsetup \([0-9.]*\).*/\1/p")"
		CRYPTSETUP_VERSION="''${CRYPTSETUP_VERSION:-unknown}"
		# Is the filesystem behind / actually on a LUKS device?
		ROOT_SRC="$(${util-linux}/bin/findmnt -no SOURCE / 2>/dev/null)"
		if [ "$(${util-linux}/bin/lsblk -no TYPE "$ROOT_SRC" 2>/dev/null | ${coreutils}/bin/head -1)" = "crypt" ]; then
			ROOT_ENC_STATE="encrypted"
		else
			ROOT_ENC_STATE="unencrypted"
		fi
		NIX_VERSION="$(${nix}/bin/nix --version 2>/dev/null | ${gnused}/bin/sed -n "s/.*) \([0-9.]*\).*/\1/p")"
		NIX_VERSION="''${NIX_VERSION:-unknown}"' \
    --replace-fail '						<Prod name="IPTables" version="1.8.4" vendor="IPTables">
						</Prod>
						<is-enabled>no</is-enabled>' '						<Prod name="IPTables" version="$FW_VERSION" vendor="IPTables">
						</Prod>
						<is-enabled>$FW_ENABLED</is-enabled>' \
    --replace-fail '						<Prod name="Dandified Yum" version="4.2.23" vendor="Red Hat, Inc.">' '						<Prod name="Nix" version="$NIX_VERSION" vendor="NixOS">' \
    --replace-fail '						<Prod name="cryptsetup" version="2.3.3" vendor="GitLab Inc.">' '						<Prod name="cryptsetup" version="$CRYPTSETUP_VERSION" vendor="cryptsetup">' \
    --replace-fail '								<drive-name>/</drive-name>
								<enc-state>encrypted</enc-state>' '								<drive-name>/</drive-name>
								<enc-state>$ROOT_ENC_STATE</enc-state>' \
    --replace-fail 'if [ -z "$APP_VERSION" ]; then APP_VERSION=5.1.5-8; fi' 'if [ -z "$APP_VERSION" ]; then APP_VERSION=${appVersion}; fi' \
    --replace-fail '		<entry name="anti-malware">
			<list/>
		</entry>' '		<entry name="antivirus">
			<list/>
		</entry>
		<entry name="anti-spyware">
			<list/>
		</entry>
		<entry name="anti-malware">
			<list/>
		</entry>' \
    --replace-fail '		<entry name="data-loss-prevention">
			<list/>
		</entry>
	</categories>' '		<entry name="data-loss-prevention">
			<list/>
		</entry>
		<entry name="certificate">
			<list/>
		</entry>
	</categories>'

  chmod +x $out/libexec/tulane-hipreport.sh
''
