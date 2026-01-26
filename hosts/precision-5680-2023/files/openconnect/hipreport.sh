#!/nix/store/j8645yndikbrvn292zgvyv64xrrmwdcb-bash-5.3p3/bin/sh

COOKIE=
IP=
IPV6=
MD5=
CLIENTOS=Windows

while [ "$1" ]; do
    if [ "$1" = "--cookie" ];      then shift; COOKIE="$1"; fi
    if [ "$1" = "--client-ip" ];   then shift; IP="$1"; fi
    if [ "$1" = "--client-ipv6" ]; then shift; IPV6="$1"; fi
    if [ "$1" = "--md5" ];         then shift; MD5="$1"; fi
    if [ "$1" = "--client-os" ];   then shift; CLIENTOS="$1"; fi
    shift
done

if [ -z "$COOKIE" ] || [ -z "$MD5" ] || [ -z "$IP$IPV6" ]; then
    echo "Required parameters missing" >&2
    exit 1
fi

USER=$(echo "$COOKIE" | sed -rn 's/(.+&|^)user=([^&]+).*/\2/p')
DOMAIN=$(echo "$COOKIE" | sed -rn 's/(.+&|^)domain=([^&]+).*/\2/p')
COMPUTER=$(echo "$COOKIE" | sed -rn 's/(.+&|^)computer=([^&]+).*/\2/p')

case $CLIENTOS in
	Linux)
		OS="Linux Fedora 32"
		OS_VENDOR="Linux"
		NETWORK_INTERFACE_NAME="virbr0"
		NETWORK_INTERFACE_DESCRIPTION="virbr0"
		ENCDRIVE='/'
	;;
	Mac)
		OS_VERSION=$(sw_vers --productVersion 2>/dev/null || echo 10.16.0)
		OS="Apple Mac OS X ${OS_VERSION}"
		OS_VENDOR="Apple"
		NETWORK_INTERFACE_NAME="en0"
		NETWORK_INTERFACE_DESCRIPTION="en0"
		ENCDRIVE='/'
	;;
	*)
		OS="Microsoft Windows 10 Pro , 64-bit"
		OS_VENDOR="Microsoft"
		NETWORK_INTERFACE_NAME="{DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF}"
		NETWORK_INTERFACE_DESCRIPTION="PANGP Virtual Ethernet Adapter #2"
		ENCDRIVE='C:\\'
	;;
esac

HOST_ID="deadbeef-dead-beef-dead-beefdeadbeef"
APP_VERSION=${APP_VERSION:-5.1.5-8}

NOW=$(date +'%m/%d/%Y %H:%M:%S')
DAY=$(date +'%d')
MONTH=$(date +'%m')
YEAR=$(date +'%Y')

cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<hip-report name="hip-report">
	<md5-sum>$MD5</md5-sum>
	<user-name>$USER</user-name>
	<domain>$DOMAIN</domain>
	<host-name>$COMPUTER</host-name>
	<host-id>$HOST_ID</host-id>
	<ip-address>$IP</ip-address>
	<ipv6-address>$IPV6</ipv6-address>
	<generate-time>$NOW</generate-time>
	<hip-report-version>4</hip-report-version>
	<categories>
		<entry name="host-info">
			<client-version>$APP_VERSION</client-version>
			<os>$OS</os>
			<os-vendor>$OS_VENDOR</os-vendor>
			<domain>$DOMAIN.internal</domain>
			<host-name>$COMPUTER</host-name>
			<host-id>$HOST_ID</host-id>
		</entry>
EOF

# ---------- Linux anti-malware (ClamAV 1.4.3) ----------
case $CLIENTOS in
	Linux) cat <<EOF
		<entry name="anti-malware">
			<list>
				<entry>
					<ProductInfo>
						<Prod name="ClamAV" version="1.4.3" vendor="Cisco"/>
						<real-time-protection>yes</real-time-protection>
						<last-full-scan-time>$NOW</last-full-scan-time>
					</ProductInfo>
				</entry>
			</list>
		</entry>
EOF
	;;
esac

cat <<EOF
		<entry name="disk-encryption">
			<list>
				<entry>
					<ProductInfo>
						<Prod name="cryptsetup" version="2.3.3" vendor="GitLab Inc."/>
						<drives>
							<entry>
								<drive-name>/</drive-name>
								<enc-state>encrypted</enc-state>
							</entry>
						</drives>
					</ProductInfo>
				</entry>
			</list>
		</entry>

		<entry name="firewall">
			<list>
				<entry>
					<ProductInfo>
						<Prod name="nftables" version="0.9.3" vendor="The Netfilter Project"/>
						<is-enabled>yes</is-enabled>
					</ProductInfo>
				</entry>
			</list>
		</entry>

		<entry name="patch-management">
			<list>
				<entry>
					<ProductInfo>
						<Prod name="NixOS" version="current" vendor="NixOS"/>
						<is-enabled>yes</is-enabled>
					</ProductInfo>
				</entry>
			</list>
			<missing-patches/>
		</entry>

		<entry name="data-loss-prevention">
			<list/>
		</entry>
	</categories>
</hip-report>
EOF
