#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Error: missing required argument."
    echo "Usage: $0 <path/to/config.apc>"
    exit 1
fi

JSON_FILE="$1"
CREDS_FILE="$(basename "$JSON_FILE" .apc)-creds.txt"

# Output OVPN file
OUT="$(basename "$JSON_FILE" .apc).ovpn"

echo "Generating $OUT ..."

{
    echo "client"
    echo "dev tun"
    echo "proto $(jq -r '.protocol' "$JSON_FILE")"
    echo "remote $(jq -r '.server_address[0]' "$JSON_FILE") $(jq -r '.server_port' "$JSON_FILE")"
    echo "auth $(jq -r '.authentication_algorithm' "$JSON_FILE")"
    echo "cipher $(jq -r '.encryption_algorithm' "$JSON_FILE")"
    echo "remote-cert-tls server"

    echo
    SERVER_CN=$(jq -r '.server_dn' "$JSON_FILE" | sed -n 's/.*CN=\([^,]*\).*/\1/p')
    echo "setenv opt verify-x509-name $SERVER_CN name"
    echo

    echo "<ca>"
    jq -r '.ca_cert' "$JSON_FILE"
    echo "</ca>"
    echo
    echo "<cert>"
    jq -r '.certificate' "$JSON_FILE"
    echo "</cert>"
    echo
    echo "<key>"
    jq -r '.key' "$JSON_FILE"
    echo "</key>"

    echo "<connection>"
    echo "remote $(jq -r '.server_address[0]' "$JSON_FILE") $(jq -r '.server_port' "$JSON_FILE")"
    echo "</connection>"

    echo
    echo "auth-user-pass $CREDS_FILE"

    echo
    echo "resolv-retry infinite"
    echo "auth-retry nointeract"
    echo "keepalive 10 60"
    echo "pull-filter ignore \"redirect-gateway\""
    echo "persist-key"
    echo "persist-tun"
    echo "inactive 0"
} > "$OUT"

echo "Done: $OUT"

echo
echo "Generating $CREDS_FILE ..."
jq -r '"\(.username)\n\(.password)"' "$JSON_FILE" > "$CREDS_FILE"
echo "Done: $CREDS_FILE"

