#!/bin/sh
set -eu

CONFIG_DIR=/etc/sing-box
CONFIG_FILE="${CONFIG_DIR}/config.json"
CREDENTIALS_FILE="${CONFIG_DIR}/credentials.txt"

mkdir -p "${CONFIG_DIR}" /var/lib/sing-box

if [ ! -s "${CONFIG_FILE}" ]; then
  umask 077
  USERNAME="sb$(openssl rand -hex 4)"
  PASSWORD="$(openssl rand -hex 24)"
  cat > "${CONFIG_FILE}" <<EOF
{
  "log": {"level": "info", "timestamp": true},
  "inbounds": [{
    "type": "mixed",
    "tag": "mixed-in",
    "listen": "0.0.0.0",
    "listen_port": 2080,
    "users": [{"username": "${USERNAME}", "password": "${PASSWORD}"}]
  }],
  "outbounds": [{"type": "direct", "tag": "direct"}],
  "route": {"final": "direct"}
}
EOF
  {
    printf 'username=%s\n' "${USERNAME}"
    printf 'password=%s\n' "${PASSWORD}"
  } > "${CREDENTIALS_FILE}"
  chmod 600 "${CONFIG_FILE}" "${CREDENTIALS_FILE}"
  echo "[sing-box] Generated authenticated Mixed proxy on port 2080."
  echo "[sing-box] username: ${USERNAME}"
  echo "[sing-box] password: ${PASSWORD}"
else
  echo "[sing-box] Existing config found; keeping it unchanged."
fi

/usr/local/bin/sing-box check -c "${CONFIG_FILE}"
exec /usr/local/bin/sing-box -D /var/lib/sing-box run -c "${CONFIG_FILE}"
