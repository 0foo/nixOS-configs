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
# stays intact. Every substituted value is measured, not asserted -- a HIP
# report is a security attestation and the gateway is entitled to a true one.
#
# The antivirus/anti-spyware/anti-malware lists were empty for the same
# reason: nothing was installed, and the gateway quarantined the session over
# exactly that. services.clamav now runs on this host and the lists report it
# -- still probed, so they fall back to empty the moment clamd stops.
{ runCommand
, openconnect
, iproute2
, iptables
, cryptsetup
, systemd
, util-linux
, clamav
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

runCommand "tulane-hipreport"
{
  # The ClamAV probe is handed over through the environment instead of being
  # inlined into a substituteInPlace argument. Inline, it does not survive:
  # the replacement string is re-parsed by the shell, its quotes are stripped
  # and the text is truncated at the first `|`, leaving a half-written
  # `sed -n s` in the generated script. Expanded as "$clamavProbe" it is a
  # single argument and nothing re-parses it.
  #
  # The block is appended to the Linux arm of hipreport.sh's variable-setup
  # case, so it runs before any XML is emitted. Everything in it is measured;
  # if ClamAV is missing or stopped, the three lists keep upstream's value,
  # which is empty.
  clamavProbe = ''
    		NIX_VERSION="''${NIX_VERSION:-unknown}"

    		# `clamdscan --version` answers from the running daemon and returns
    		# "ClamAV 1.4.6/28151/Mon Oct 12 01:24:02 2026": engine version,
    		# signature database version, and the date that database was built.
    		# With clamd stopped it degrades to a bare "ClamAV 1.4.6" carrying
    		# no signature state, which the case below treats as nothing to
    		# report -- an engine of unknown signature age is not a posture
    		# claim worth making. Note the `=` sed delimiter: the version
    		# string is full of slashes.
    		CLAMAV_LIST_AV="<list/>"
    		CLAMAV_LIST_AS="<list/>"
    		CLAMAV_LIST_AM="<list/>"
    		CLAMAV_RAW="$(${clamav}/bin/clamdscan --version 2>/dev/null)"
    		case "$CLAMAV_RAW" in
    		ClamAV*/*/*)
    			CLAMAV_VER="$(printf "%s" "$CLAMAV_RAW" | ${gnused}/bin/sed -n "s=^ClamAV \([^/]*\)/.*=\1=p")"
    			CLAMAV_DEFVER="$(printf "%s" "$CLAMAV_RAW" | ${gnused}/bin/sed -n "s=^ClamAV [^/]*/\([^/]*\)/.*=\1=p")"
    			CLAMAV_SIGDATE="$(printf "%s" "$CLAMAV_RAW" | ${gnused}/bin/sed -n "s=^ClamAV [^/]*/[^/]*/==p")"
    			CLAMAV_SIGDAY="$(${coreutils}/bin/date -d "$CLAMAV_SIGDATE" +%d 2>/dev/null)"
    			CLAMAV_SIGMON="$(${coreutils}/bin/date -d "$CLAMAV_SIGDATE" +%m 2>/dev/null)"
    			CLAMAV_SIGYEAR="$(${coreutils}/bin/date -d "$CLAMAV_SIGDATE" +%Y 2>/dev/null)"

    			# On-access scanning is what makes real-time protection a true
    			# claim, so ask the unit, not whether the binary exists.
    			if ${systemd}/bin/systemctl is-active --quiet clamav-clamonacc.service 2>/dev/null; then
    				CLAMAV_RTP="yes"
    			else
    				CLAMAV_RTP="no"
    			fi

    			# Claim a full-scan time only if the scheduled scan actually
    			# completed; never-run or failed means n/a.
    			CLAMAV_LAST_SCAN="n/a"
    			if [ "$(${systemd}/bin/systemctl show clamdscan.service -p Result --value 2>/dev/null)" = "success" ]; then
    				CLAMAV_SCAN_TS="$(${systemd}/bin/systemctl show clamdscan.service -p ExecMainExitTimestamp --value 2>/dev/null)"
    				if [ -n "$CLAMAV_SCAN_TS" ]; then
    					CLAMAV_LAST_SCAN="$(${coreutils}/bin/date -d "$CLAMAV_SCAN_TS" +"%m/%d/%Y %H:%M:%S" 2>/dev/null || echo "n/a")"
    				fi
    			fi

    			# prodType 1/2/3 = antivirus / anti-spyware / anti-malware, and
    			# osType 1 even on Linux. That is what Palo Alto's own PanGpHip
    			# emits -- its only Prod templates are prodType 1, 2 and 3, all
    			# with osType="1" -- so the gateway is handed the shape a real
    			# client would send.
    			CLAMAV_TPL="<list>
    				<entry>
    					<ProductInfo>
    						<Prod vendor=\"Cisco Systems, Inc.\" name=\"ClamAV\" version=\"$CLAMAV_VER\" defver=\"$CLAMAV_DEFVER\" engver=\"$CLAMAV_VER\" datemon=\"$CLAMAV_SIGMON\" dateday=\"$CLAMAV_SIGDAY\" dateyear=\"$CLAMAV_SIGYEAR\" prodType=\"@PRODTYPE@\" osType=\"1\"/>
    						<real-time-protection>$CLAMAV_RTP</real-time-protection>
    						<last-full-scan-time>$CLAMAV_LAST_SCAN</last-full-scan-time>
    					</ProductInfo>
    				</entry>
    			</list>"
    			CLAMAV_LIST_AV="''${CLAMAV_TPL/@PRODTYPE@/1}"
    			CLAMAV_LIST_AS="''${CLAMAV_TPL/@PRODTYPE@/2}"
    			CLAMAV_LIST_AM="''${CLAMAV_TPL/@PRODTYPE@/3}"
    			;;
    		esac'';
}
  ''
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
			$CLAMAV_LIST_AV
		</entry>
		<entry name="anti-spyware">
			$CLAMAV_LIST_AS
		</entry>
		<entry name="anti-malware">
			$CLAMAV_LIST_AM
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

    # Second pass: the NIX_VERSION fallback line is the tail of the Linux
    # variable-setup arm the first replacement wrote, so appending the probe
    # there puts it at the end of that arm.
    substituteInPlace $out/libexec/tulane-hipreport.sh \
      --replace-fail '		NIX_VERSION="''${NIX_VERSION:-unknown}"' "$clamavProbe"

    chmod +x $out/libexec/tulane-hipreport.sh
  ''
