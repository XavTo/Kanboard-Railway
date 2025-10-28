#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/var/www/app/data"
PERSIST_PLUGINS="${DATA_DIR}/plugins"      # persistent (Railway volume)
WEB_PLUGINS="/var/www/app/plugins"         # served by Nginx/PHP
CONFIG_FILE="${DATA_DIR}/config.php"
SENTINEL="${DATA_DIR}/BOOT_OK.txt"

mkdir -p "${PERSIST_PLUGINS}" "${WEB_PLUGINS}"

# --- Minimal config.php in the official persistent location ---
# Keep default PLUGINS_DIR = /var/www/app/plugins so the UI installs there instantly.
cat > "${CONFIG_FILE}" <<'PHP'
<?php
define('PLUGIN_INSTALLER', true);
// Do not define PLUGINS_DIR: keep the default ("plugins") so the UI writes to /var/www/app/plugins
PHP

# Permissions on the persistent volume
chown -R nginx:nginx "${DATA_DIR}" || true
chmod -R 775 "${DATA_DIR}" || true

# --- Restore on startup: if container's web dir is empty but persisted data exists, restore data -> web ---
if [ -z "$(ls -A "${WEB_PLUGINS}" 2>/dev/null || true)" ] && [ -n "$(ls -A "${PERSIST_PLUGINS}" 2>/dev/null || true)" ]; then
  echo "[docker-start] Restore: data -> web"
  cp -a "${PERSIST_PLUGINS}/." "${WEB_PLUGINS}/" || true
fi

ASSETS_CSS_DIR="/var/www/app/assets/css"
if [ -d "${ASSETS_CSS_DIR}" ] && [ ! -f "${ASSETS_CSS_DIR}/app.min.css" ]; then
  if [ -f "${ASSETS_CSS_DIR}/auto.min.css" ]; then
    ln -s "${ASSETS_CSS_DIR}/auto.min.css" "${ASSETS_CSS_DIR}/app.min.css"
    echo "[docker-start] Created symlink app.min.css → auto.min.css"
  elif [ -f "${ASSETS_CSS_DIR}/light.min.css" ]; then
    ln -s "${ASSETS_CSS_DIR}/light.min.css" "${ASSETS_CSS_DIR}/app.min.css"
    echo "[docker-start] Created symlink app.min.css → light.min.css"
  fi
fi

# --- Reconcile function: mirror WEB -> DATA exactly (create/update/delete) ---
mirror_web_to_data() {
  # Remove plugins in DATA that no longer exist in WEB
  for d in "${PERSIST_PLUGINS}"/*; do
    [ -e "$d" ] || continue
    name="$(basename "$d")"
    if [ ! -e "${WEB_PLUGINS}/${name}" ]; then
      rm -rf "${PERSIST_PLUGINS:?}/${name}"
    fi
  done

  # Copy/replace plugins from WEB to DATA
  for d in "${WEB_PLUGINS}"/*; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    rm -rf "${PERSIST_PLUGINS:?}/${name}"
    cp -a "$d" "${PERSIST_PLUGINS}/"
  done
}

# Initial reconciliation (in case web already contains plugins)
mirror_web_to_data

# --- Event-driven persistence: watch WEB_PLUGINS and mirror changes to DATA immediately ---
# inotifywait blocks efficiently until create/move/modify/delete events occur.
# It then triggers a full mirror to keep DATA consistent and durable.
inotifywait -m -r -e create,move,modify,delete --format '%e %w%f' "${WEB_PLUGINS}" \
  | while read -r _event _path; do
      mirror_web_to_data
    done &

echo "[docker-start] config.php ready, event-driven plugin persistence active" | tee "${SENTINEL}"

# Start Kanboard (official image entrypoint)
exec /usr/local/bin/entrypoint.sh
