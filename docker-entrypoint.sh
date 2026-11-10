#!/bin/sh
set -eu

CONFIG_DIR=/etc/sing-box
CONFIG_FILE="${CONFIG_DIR}/config.json"
CREDENTIALS_FILE="${CONFIG_DIR}/credentials.txt"
SING_BOX=/usr/local/bin/sing-box

# VLESS + XTLS-Vision + REALITY.
# PORT is the in-container listen port; PUBLIC_PORT is what clients dial and
# only differs when the container port is mapped elsewhere (e.g. -p 8443:443).
PORT="${PORT:-443}"
PUBLIC_PORT="${PUBLIC_PORT:-${PORT}}"
REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"
SERVER_ADDR="${SERVER_ADDR:-<server-ip>}"

mkdir -p "${CONFIG_DIR}" /var/lib/sing-box

if [ ! -s "${CONFIG_FILE}" ]; then
  umask 077
  VLESS_UUID="$("${SING_BOX}" generate uuid)"
  REALITY_KEYS="$("${SING_BOX}" generate reality-keypair)"
  REALITY_PRIVATE_KEY="$(printf '%s\n' "${REALITY_KEYS}" | tr -d '\r' | sed -n 's/^PrivateKey: //p')"
  REALITY_PUBLIC_KEY="$(printf '%s\n' "${REALITY_KEYS}" | tr -d '\r' | sed -n 's/^PublicKey: //p')"
  REALITY_SHORT_ID="$("${SING_BOX}" generate rand 4 --hex)"

  if [ -z "${REALITY_PRIVATE_KEY}" ] || [ -z "${REALITY_PUBLIC_KEY}" ]; then
    echo "[sing-box] Failed to generate REALITY key pair." >&2
    exit 1
  fi

  cat > "${CONFIG_FILE}" <<EOF
{
  "log": {"level": "info", "timestamp": true},
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "0.0.0.0",
      "listen_port": ${PORT},
      "users": [{"uuid": "${VLESS_UUID}", "flow": "xtls-rprx-vision"}],
      "tls": {
        "enabled": true,
        "server_name": "${REALITY_SNI}",
        "reality": {
          "enabled": true,
          "handshake": {"server": "${REALITY_SNI}", "server_port": 443},
          "private_key": "${REALITY_PRIVATE_KEY}",
          "short_id": ["${REALITY_SHORT_ID}"]
        }
      }
    }
  ],
  "outbounds": [{"type": "direct", "tag": "direct"}],
  "route": {"final": "direct"}
}
EOF

  VLESS_URL="vless://${VLESS_UUID}@${SERVER_ADDR}:${PUBLIC_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp#sing-box-reality"

  {
    printf 'vless_uuid=%s\n' "${VLESS_UUID}"
    printf 'vless_port=%s\n' "${PUBLIC_PORT}"
    printf 'vless_sni=%s\n' "${REALITY_SNI}"
    printf 'vless_public_key=%s\n' "${REALITY_PUBLIC_KEY}"
    printf 'vless_short_id=%s\n' "${REALITY_SHORT_ID}"
    printf 'vless_url=%s\n' "${VLESS_URL}"
  } > "${CREDENTIALS_FILE}"
  chmod 600 "${CONFIG_FILE}" "${CREDENTIALS_FILE}"

  echo "[sing-box] Generated VLESS REALITY inbound on port ${PORT}."
  echo "[sing-box] vless uuid: ${VLESS_UUID}"
  echo "[sing-box] vless share link: ${VLESS_URL}"
else
  echo "[sing-box] Existing config found; keeping it unchanged."
  if ! grep -q '"vless"' "${CONFIG_FILE}"; then
    echo "[sing-box] This config has no VLESS REALITY inbound. Remove ${CONFIG_FILE} and restart to regenerate it."
  fi
fi

"${SING_BOX}" check -c "${CONFIG_FILE}"
exec "${SING_BOX}" -D /var/lib/sing-box run -c "${CONFIG_FILE}"
