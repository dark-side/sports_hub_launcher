#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Sports Hub Setup"
BUNDLE_ID="com.example.sportshub.setup"
ICON_ICNS="app.icns"

APP_BUNDLE="${APP_NAME}.app"
APP_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${APP_DIR}/MacOS"
RES_DIR="${APP_DIR}/Resources"

rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RES_DIR}"

if [ ! -f "./setup.sh" ]; then
  echo "[err ] Не знайдено ./setup.sh поруч зі скриптом пакування"; exit 1
fi

cp -f "./setup.sh" "${RES_DIR}/setup.sh"
chmod 755 "${RES_DIR}/setup.sh"

cat > "${RES_DIR}/run_setup.sh" <<'BASH'
#!/bin/bash
set -o pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/Library/Python/3.11/bin:$HOME/Library/Python/3.10/bin:$HOME/Library/Python/3.9/bin:$PATH"

cd "$(dirname "$0")" || cd .

APP_LOG="./setup-run.log"
USER_LOG_DIR="$HOME/Library/Logs/SportsHubSetup"
mkdir -p "$USER_LOG_DIR"
USER_LOG="$USER_LOG_DIR/setup-run.log"
exec > >(tee -a "$APP_LOG" | tee -a "$USER_LOG") 2>&1

say(){  printf "\033[34m[setup]\033[0m %s\n" "$*"; }
ok(){   printf "\033[32m[ ok ]\033[0m %s\n" "$*"; }
warn(){ printf "\033[33m[warn]\033[0m %s\n" "$*"; }
err(){  printf "\033[31m[err ]\033[0m %s\n" "$*"; }
have_cmd(){ command -v "$1" >/dev/null 2>&1; }

SAFE_TMP="$HOME/Library/Caches/SportsHubSetup/tmp"
mkdir -p "$SAFE_TMP"
chmod 700 "$SAFE_TMP"
export TMPDIR="$SAFE_TMP"

prompt_for_workspace_macos() {
    local chosen_dir
    chosen_dir=$(osascript -e 'try' \
      -e 'tell application (path to frontmost application as text)' \
      -e 'set chosen_folder to choose folder with prompt "Будь ласка, оберіть папку для проєктів (напр. IdeaProjects):"' \
      -e 'return POSIX path of chosen_folder' \
      -e 'end tell' \
      -e 'on error number -128' \
      -e 'return ""' \
      -e 'end try' 2>/dev/null)
    
    if [[ -z "$chosen_dir" ]]; then
      say "Папку не вибрано. Вихід."
      sleep 2
      exit 0
    fi
    echo "$chosen_dir"
}

ensure_podman(){
  if have_cmd podman; then return 0; fi
  say "Встановлюю Podman… (може знадобитися пароль)"
  if have_cmd brew; then
      brew install podman || { err "brew install podman не вдалось"; return 1; }
  else
      err "Homebrew не знайдено. Встановіть його з brew.sh, а потім Podman."
      return 1
  fi
  ok "Podman встановлено"
}

maybe_init_podman_machine(){
  if podman info >/dev/null 2>&1; then return 0; fi
  say "Ініціалізація podman machine… (це може зайняти кілька хвилин)"
  podman machine init || true
  podman machine start || true
}

set_podman_env(){
  if podman machine env --format sh >/dev/null 2>&1; then
    eval "$(podman machine env --format sh | grep -E '^(export DOCKER_HOST=|export CONTAINER_HOST=)')" || true
  else
    local sock; sock="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null | tr -d '\r')"
    if [ -n "$sock" ] && [ -S "$sock" ]; then export CONTAINER_HOST="unix://$sock"; fi
  fi
  if [ -n "${CONTAINER_HOST:-}" ]; then unset DOCKER_HOST; ok "Сокет podman налаштовано (CONTAINER_HOST)";
  elif [ -n "${DOCKER_HOST:-}" ]; then ok "Сокет podman налаштовано (DOCKER_HOST)";
  else warn "Не вдалося налаштувати podman socket автоматично."; fi
}

ensure_podman_compose(){
  if podman compose version >/dev/null 2>&1; then export COMPOSE_CMD="podman compose"; return 0; fi
  if have_cmd podman-compose; then export COMPOSE_CMD="podman-compose"; return 0; fi
  say "Встановлюю podman-compose…"
  if have_cmd brew; then brew install podman-compose || true; fi
  if podman compose version >/dev/null 2>&1; then export COMPOSE_CMD="podman compose";
  elif have_cmd podman-compose; then export COMPOSE_CMD="podman-compose";
  else warn "podman-compose не встановлено."; fi
}

main(){
  local FAILED=0
  
  WORKSPACE=$(prompt_for_workspace_macos)
  
  say "Перевіряю залежності (Podman/Compose)…"
  ensure_podman || FAILED=1
  if [ $FAILED -eq 0 ]; then
    maybe_init_podman_machine || true
    set_podman_env || true
  fi
  ensure_podman_compose || true

  export PODMAN_COMPOSE_PROVIDER=podman
  say "Встановлено PODMAN_COMPOSE_PROVIDER=podman"
  
  export COMPOSE_CMD

  if [ ${FAILED:-0} -eq 0 ]; then
    chmod +x ./setup.sh || true
    say "Запускаю головний скрипт у папці: $WORKSPACE"
    ./setup.sh --workspace "$WORKSPACE" || FAILED=$?
  fi

  echo
  if [ ${FAILED:-0} -eq 0 ]; then ok "Готово."; else err "Завершено з помилками (exit=${FAILED})."; fi
  echo "Логи збережено у: $USER_LOG"
  echo
  read -rp "Натисніть ENTER, щоб закрити вікно…" _
  exit ${FAILED:-0}
}

main
BASH
chmod 755 "${RES_DIR}/run_setup.sh"

cat > "${APP_DIR}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
  <key>CFBundleVersion</key><string>1.0.0</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>launcher</string>
  <key>LSMinimumSystemVersion</key><string>10.13</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
  <key>NSHighResolutionCapable</key><true/>
  $( [ -f "${ICON_ICNS}" ] && echo "<key>CFBundleIconFile</key><string>app</string>" )
</dict>
</plist>
PLIST

if [ -f "${ICON_ICNS}" ]; then
  cp -f "${ICON_ICNS}" "${RES_DIR}/app.icns"
fi

ABS_RES_DIR="$(cd "${RES_DIR}" && pwd)"
cat > "${MACOS_DIR}/launcher" <<LAUNCH
#!/bin/bash
set -euo pipefail
ABS_RES_DIR="${ABS_RES_DIR}"
/usr/bin/osascript <<OSA
set resDir to POSIX file "$ABS_RES_DIR"
tell application "Terminal"
  activate
  do script "cd " & quoted form of POSIX path of resDir & " && ./run_setup.sh"
end tell
OSA
LAUNCH
chmod 755 "${MACOS_DIR}/launcher"

xattr -dr com.apple.quarantine "${APP_BUNDLE}" || true

echo "[ ok ] Зібрано: ${APP_BUNDLE}"