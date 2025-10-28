#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/var/www/app/data"
PERSIST_PLUGINS="${DATA_DIR}/plugins"      # Persistent plugins (Railway volume)
WEB_PLUGINS="/var/www/app/plugins"         # "Web" path served by Nginx/PHP
CONFIG_FILE="${DATA_DIR}/config.php"
SENTINEL="${DATA_DIR}/BOOT_OK.txt"

mkdir -p "${PERSIST_PLUGINS}" "${WEB_PLUGINS}"

# --- config.php inside the persistent volume (official location) ---
# NOTE: Do NOT define PLUGINS_DIR here; keep the default = /var/www/app/plugins
cat > "${CONFIG_FILE}" <<'PHP'
<?php
define('PLUGIN_INSTALLER', true);
// Do not define PLUGINS_DIR: keep the default "plugins" so that the UI installs into /var/www/app/plugins
PHP

# Volume permissions
chown -R nginx:nginx "${DATA_DIR}" || true
chmod -R 775 "${DATA_DIR}" || true

# --- Restore on startup (if the container is empty but persistent data exists) ---
if [ -z "$(ls -A "${WEB_PLUGINS}" 2>/dev/null || true)" ] && [ -n "$(ls -A "${PERSIST_PLUGINS}" 2>/dev/null || true)" ]; then
  echo "[docker-start] Restore: data -> web"
  cp -a "${PERSIST_PLUGINS}/." "${WEB_PLUGINS}/" || true
fi

# --- Continuous persistence loop (web -> data) ---
sync_web_to_data() {
  # Copy any new or updated plugin from /var/www/app/plugins to /var/www/app/data/plugins
  for d in "${WEB_PLUGINS}"/*; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    # Copy if missing on the persistent side; for simple updates, this is generally sufficient
    if [ ! -e "${PERSIST_PLUGINS}/${name}" ]; then
      cp -a "$d" "${PERSIST_PLUGINS}/" || true
    fi
  done
}
# Initial sync, then a lightweight loop
sync_web_to_data
(
  while true; do
    sync_web_to_data
    sleep 2
  done
) &

echo "[docker-start] config.php ready, plugin persistence web→data active" | tee "${SENTINEL}"

# Start Kanboard (official image entrypoint)
exec /usr/local/bin/entrypoint.sh
