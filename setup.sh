#!/usr/bin/env bash
# setup.sh — Universal interactive menu for multi-stack app (backend + frontend)
# Engine: Podman (no Docker). macOS / Linux / Windows(Git Bash) supported.

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
set -E

# ==================== Defaults / Globals ====================
CONFIG_DIR="$HOME/.config/sportshub-setup"
mkdir -p "$CONFIG_DIR"

ENGINE="podman"
COMPOSE_CMD="${COMPOSE_CMD:-}"
OPEN_BROWSER=${OPEN_BROWSER:-1}
WAIT_URL="${WAIT_URL:-http://localhost:3000/}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180}"
LOG_FILE="$CONFIG_DIR/setup.log"
TECH_FILE="$CONFIG_DIR/tech"
FRONTEND_FILE="$CONFIG_DIR/frontend"

# ==================== Tech Catalog (compatible with old Bash) ====================
TECHS=("Java" "Python" "Ruby" "Go" "C++" "PHP" "Node.js" ".NET" "Rust")
TECH_KEYS=("java" "python" "ruby" "go" "cpp" "php" "node" "net" "rust")

BACKEND_URLS=(
  "https://github.com/dark-side/sports_hub_java_skeleton.git"     # java
  "https://github.com/dark-side/sports_hub_python_skeleton.git"   # python
  "https://github.com/dark-side/sports_hub_ruby_skeleton.git"     # ruby
  "https://github.com/dark-side/sports_hub_go_skeleton.git"       # go
  "https://github.com/dark-side/sports_hub_cpp_skeleton.git"      # cpp
  "https://github.com/dark-side/sports_hub_php_skeleton.git"      # php
  "https://github.com/dark-side/sports_hub_nodejs_skeleton.git"   # node
  "https://github.com/dark-side/sports_hub_net_skeleton.git"      # net
  "https://github.com/dark-side/sports_hub_rust_skeleton.git"     # rust
)

# default frontend per backend
DEFAULT_FES=("React" "React" "React" "Angular" "React" "React" "Angular" "Angular" "React")

FRONTEND_NAMES=("React" "Angular")
FRONTEND_URLS=(
  "https://github.com/dark-side/sports_hub_react_skeleton.git"
  "https://github.com/dark-side/sports_hub_angular_skeleton.git"
)

# optional extra repos per backend (space-separated per item; empty if none)
EXTRA_REPOS=(
  ""                                                    # java
  "https://github.com/dark-side/api_docs_genai_playground.git"  # python
  "https://github.com/dark-side/api_docs_genai_playground.git"  # ruby
  ""                                                    # go
  ""                                                    # cpp
  ""                                                    # php
  ""                                                    # node
  ""                                                    # net
  ""                                                    # rust
)

DOCS_REPO_URL="https://github.com/dark-side/api_docs_genai_playground.git"
DOCS_DIR_NAME="api_docs_genai_playground"
DOCS_URL="http://localhost:5173"

# post-clone hooks (per-backend)
post_clone_java()  { :; }
post_clone_python(){ [ -f ".env.example" ] && cp -n .env.example .env || true; }
post_clone_ruby()  { :; }
post_clone_go()    { [ -f ".example.env" ] && cp -n .example.env .env || true; }
post_clone_cpp()   { [ -f ".env.example" ] && cp -n .env.example .env || true; }
post_clone_php()   { :; }
post_clone_node()  { :; }
post_clone_net()   { :; }
post_clone_rust()  { [ -f ".env.example" ] && cp -n .env.example .env || true; }

# ==================== i18n ====================
set_lang_uk(){
  MSG_LOGS_SAVED="Логи збережено в:"; PROMPT_PRESS_ENTER="Натисніть Enter..."; PROMPT_CHOICE="> Ваш вибір:"; WARN_UNKNOWN_CHOICE="Невідомий вибір";
  MENU_TITLE="Оберіть дію:"; MENU_1_FULL_START="Повний запуск (інсталяція → клон/оновлення → запуск)";
  MENU_2_ENSURE_ENGINE="Перевірка/інсталяція Podman"; MENU_3_CLONE_UPDATE="Клонувати/оновити репозиторії";
  MENU_4_UP="Запустити stack"; MENU_5_DOWN="Зупинити stack"; MENU_6_BUILD="Перезібрати сервіси"; MENU_7_PULL="Pull образів";
  MENU_8_LOGS="Меню логів"; MENU_L_LOGS_SNAPSHOT="Логи (останні 200)"; MENU_9_STATUS="Статус (ps)";
  MENU_T_CHOOSE_TECH="Змінити технологію"; MENU_F_CHOOSE_FRONTEND="Змінити фронтенд"; MENU_M_CHOOSE_LANG="Змінити мову";
  MENU_D_VIEW_DOCS="Відкрити документацію"; MENU_0_OPEN="Відкрити у браузері"; MENU_Q_QUIT="Вихід";
  FRONTEND_BANNER_TITLE="Фронтенд"; FRONTEND_CURRENT="поточний:"; FRONTEND_PROMPT="Оберіть фронтенд:";
  TECH_BANNER_TITLE="Технологія"; TECH_CURRENT="поточна:"; TECH_PROMPT="Оберіть технологію (бекенд):";
  MSG_FRONTEND_SET="Фронтенд встановлено:"; MSG_TECH_SET="Технологію встановлено:"; MSG_ACTION_FAILED="Дія завершилась з кодом";
  WARN_NO_COMPOSE="Не знайдено 'podman compose' або 'podman-compose'.";
  LOG_MENU_PROMPT="Що зробити з логами?"; LOG_MENU_VIEW="Переглянути логи в терміналі"; LOG_MENU_SAVE="Зберегти логи у JSON файл"; LOG_MENU_BACK="Назад";
  LOG_SAVED_TO="Логи збережено у файл:"; MSG_STARTING_DOCS="Запускаю сервіс документації...";
}
set_lang_en(){
  MSG_LOGS_SAVED="Logs saved to:"; PROMPT_PRESS_ENTER="Press Enter..."; PROMPT_CHOICE="> Your choice:"; WARN_UNKNOWN_CHOICE="Unknown choice";
  MENU_TITLE="Select an action:"; MENU_1_FULL_START="Full run (install → clone/update → up)";
  MENU_2_ENSURE_ENGINE="Check/Install Podman"; MENU_3_CLONE_UPDATE="Clone/update repositories";
  MENU_4_UP="Start stack"; MENU_5_DOWN="Stop stack"; MENU_6_BUILD="Rebuild services"; MENU_7_PULL="Pull images";
  MENU_8_LOGS="Logs Menu"; MENU_L_LOGS_SNAPSHOT="Logs (last 200)"; MENU_9_STATUS="Status (ps)";
  MENU_T_CHOOSE_TECH="Change technology"; MENU_F_CHOOSE_FRONTEND="Change frontend"; MENU_M_CHOOSE_LANG="Change language";
  MENU_D_VIEW_DOCS="Open Documentation"; MENU_0_OPEN="Open in browser"; MENU_Q_QUIT="Quit";
  FRONTEND_BANNER_TITLE="Frontend"; FRONTEND_CURRENT="current:"; FRONTEND_PROMPT="Choose a frontend:";
  TECH_BANNER_TITLE="Technology"; TECH_CURRENT="current:"; TECH_PROMPT="Choose a backend technology:";
  MSG_FRONTEND_SET="Frontend set to:"; MSG_TECH_SET="Technology set to:"; MSG_ACTION_FAILED="Action finished with code";
  WARN_NO_COMPOSE="Could not find 'podman compose' or 'podman-compose'.";
  LOG_MENU_PROMPT="What to do with logs?"; LOG_MENU_VIEW="View logs in terminal"; LOG_MENU_SAVE="Save logs to JSON file"; LOG_MENU_BACK="Back";
  LOG_SAVED_TO="Logs saved to file:"; MSG_STARTING_DOCS="Starting documentation service...";
}

# ==================== UI / helpers ====================
if test -t 1; then
  BOLD="\033[1m"; RESET="\033[0m"; RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"; CYAN="\033[36m"; MAGENTA="\033[35m"
else
  BOLD=""; RESET=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; MAGENTA=""
fi

print_banner(){
  printf "${MAGENTA}${BOLD}"
  cat <<'ASCII'
  /$$$$$$   /$$$$$$  /$$   /$$ /$$$$$$$  /$$$$$$$    /$$$$$$  /$$   /$$
 /$$__  $$ /$$__  $$| $$$ | $$| $$__  $$| $$__  $$ /$$__  $$| $$  / $$
| $$  \__/| $$  \ $$| $$$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$/ $$/
|  $$$$$$ | $$$$$$$$| $$ $$ $$| $$  | $$| $$$$$$$ | $$  | $$ \  $$$$/
 \____  $$| $$__  $$| $$  $$$$| $$  | $$| $$__  $$| $$  | $$  >$$  $$
 /$$  \ $$| $$  | $$| $$\  $$$| $$  | $$| $$  \ $$| $$  | $$ /$$/\  $$
|  $$$$$$/| $$  | $$| $$ \  $$| $$$$$$$/| $$$$$$$/|  $$$$$$/| $$  \ $$
 \______/ |__/  |__/|__/  \__/|_______/ |_______/  \______/ |__/  |__/
                                                        setup (Podman)
ASCII
  printf "${RESET}\n"
}

prompt_for_language() {
  clear; print_banner
  while true; do
    printf "${BOLD}Please choose a language / Будь ласка, оберіть мову:${RESET}\n"
    printf "  ${CYAN}[1]${RESET} English\n  ${CYAN}[2]${RESET} Українська\n\n"
    read -rp "$(printf "${BOLD}> Your choice / Ваш вибір:${RESET} ")" c
    case "$c" in
      1) set_lang_en; break ;;
      2) set_lang_uk; break ;;
      *) clear; print_banner; printf "${RED}Invalid selection\n\n${RESET}" ;;
    esac
  done
}

log(){  printf "${BLUE}[setup]${RESET} %b\n" "$*"; }
ok(){   printf "${GREEN}[ ok ]${RESET} %b\n" "$*"; }
warn(){ printf "${YELLOW}[warn]${RESET} %b\n" "$*"; }
err(){  printf "${RED}[err ]${RESET} %b\n" "$*"; }

pause(){ echo; read -rp "$(printf "$PROMPT_PRESS_ENTER")" _ || true; }

on_error(){
  err "Failed at line ${BASH_LINENO[0]}: ${BASH_COMMAND}"
}
trap on_error ERR

have_cmd(){ command -v "$1" >/dev/null 2>&1; }
platform_os(){ case "$(uname -s)" in Darwin) echo mac;; Linux) echo linux;; MINGW*|MSYS*|CYGWIN*) echo win;; *) echo unknown;; esac; }

run_action() { set +e; "$@"; local rc=$?; set -e; [ $rc -ne 0 ] && warn "$MSG_ACTION_FAILED $rc"; pause; }

# ==================== Engine ensure (Podman) ====================
ensure_container_sane_defaults() {
  [ "$(platform_os)" != "linux" ] && return 0
  local SUDO_CMD=""
  if [ "$(id -u)" -ne 0 ] && have_cmd sudo; then SUDO_CMD="sudo"; fi
  $SUDO_CMD mkdir -p /etc/containers
  if ! $SUDO_CMD grep -q 'unqualified-search-registries' /etc/containers/registries.conf 2>/dev/null; then
    $SUDO_CMD bash -c "echo 'unqualified-search-registries = [\"docker.io\"]' > /etc/containers/registries.conf"
  fi
  if ! $SUDO_CMD [ -s /etc/subuid ] || ! $SUDO_CMD grep -q "^$(whoami):" /etc/subuid; then
    $SUDO_CMD bash -c "echo '$(whoami):100000:65536' >> /etc/subuid"
  fi
  if ! $SUDO_CMD [ -s /etc/subgid ] || ! $SUDO_CMD grep -q "^$(whoami):" /etc/subgid; then
    $SUDO_CMD bash -c "echo '$(whoami):100000:65536' >> /etc/subgid"
  fi
}

ensure_git(){
  if have_cmd git; then return 0; fi
  case "$(platform_os)" in
    mac) if have_cmd brew; then brew install git; else err "Install Git first (Homebrew recommended)"; return 1; fi ;;
    linux) sudo apt-get update && sudo apt-get install -y git || { err "Install Git first"; return 1; } ;;
    *) err "Unsupported OS for auto-install of Git"; return 1 ;;
  esac
}

ensure_podman(){
  if have_cmd podman; then return 0; fi
  case "$(platform_os)" in
    mac) if have_cmd brew; then brew install podman; else err "Install Podman: https://podman.io"; return 1; fi ;;
    linux) sudo apt-get update && sudo apt-get install -y podman || { err "Install Podman: https://podman.io"; return 1; } ;;
    win) err "On Windows, use Podman Desktop (install manually)"; return 1 ;;
    *) err "Unsupported OS for auto-install of Podman"; return 1 ;;
  esac
}

ensure_podman_machine_if_needed(){
  case "$(platform_os)" in
    mac|win)
      if podman info >/dev/null 2>&1; then return 0; fi
      if podman machine list >/dev/null 2>&1; then
        podman machine start || { warn "podman machine start failed"; return 0; }
      else
        podman machine init || true
        podman machine start || true
      fi
      ;;
  esac
}

restart_podman_machine_if_proxy_stuck(){
  case "$(platform_os)" in
    mac|win)
      warn "Detected proxy/gvproxy issue. Restarting podman machine…"
      set +e
      podman machine stop >/dev/null 2>&1
      pkill -f gvproxy >/dev/null 2>&1
      sleep 1
      podman machine start
      local rc=$?
      set -e
      if [ $rc -ne 0 ]; then
        err "Failed to restart podman machine (rc=$rc)"
        return $rc
      fi
      ok "podman machine restarted"
      ;;
    *) : ;;
  esac
}

ensure_podman_compose(){
  if have_cmd podman && podman compose version >/dev/null 2>&1; then return 0; fi
  if have_cmd podman-compose; then return 0; fi
  case "$(platform_os)" in
    mac)
      if have_cmd brew; then brew install podman-compose || true; fi
      ;;
    linux)
      if ! have_cmd pip3; then sudo apt-get update && sudo apt-get install -y python3-pip; fi
      sudo pip3 install podman-compose || true
      ;;
  esac
  if have_cmd podman && podman compose version >/dev/null 2>&1; then return 0; fi
  if have_cmd podman-compose; then return 0; fi
  warn "$WARN_NO_COMPOSE"
}

resolve_compose_cmd(){
  if have_cmd podman && podman compose version >/dev/null 2>&1; then
    echo "podman compose"
  else
    echo "podman-compose"
  fi
}

ensure_engine_ready(){
  ensure_git
  ensure_podman
  ensure_podman_machine_if_needed
  ensure_container_sane_defaults
  ensure_podman_compose
  if [ -z "${CMD:-}" ]; then CMD=$(resolve_compose_cmd); fi
  ok "Using compose: ${BOLD}$CMD${RESET}"
}

# ==================== Repo ops & state ====================
clone_or_update(){
  local url="$1" dir="$2"
  if [ -d "$dir/.git" ]; then
    log "Updating ${BOLD}$dir${RESET}..."
    (cd "$dir" && git pull --ff-only || git fetch --all --prune) || warn "git update failed in $dir"
  else
    log "Cloning ${BOLD}$url${RESET}..."
    git clone "$url" "$dir" || warn "git clone failed for $url"
  fi
}

patch_compose_frontend_path(){
  local be_dir="$1" fe_dir="$2"
  local f; f=$(find_compose_file "$be_dir" || true)
  [ -z "$f" ] && return 0
  if grep -qE "build:\s*\.\./sports_hub_.*_skeleton" "$f"; then
    log "Patching compose frontend build path -> ../$fe_dir"
    # macOS BSD sed vs GNU sed: use portable in-place trick
    cp "$f" "$f.bak"
    sed -E "s|(build:\s*)\.\./sports_hub_[^/]*_skeleton|\1../$fe_dir|g" "$f.bak" > "$f"
  fi
}

apply_tech_selection(){
  local tech_key="$1"; local frontend_name="${2:-}"
  local tech_index=-1
  for i in "${!TECH_KEYS[@]}"; do
    if [[ "${TECH_KEYS[$i]}" == "$tech_key" ]]; then tech_index=$i; break; fi
  done
  if [ "$tech_index" -eq -1 ]; then err "Internal error: unknown tech $tech_key"; return 1; fi

  CURRENT_TECH_KEY="$tech_key"
  CURRENT_TECH="${TECHS[$tech_index]}"
  [ -z "$frontend_name" ] && frontend_name="${DEFAULT_FES[$tech_index]}"
  CURRENT_FRONTEND_NAME="$frontend_name"

  BACKEND_URL="${BACKEND_URLS[$tech_index]}"
  BACKEND_DIR="$(basename "$BACKEND_URL" .git)"

  if [ "$CURRENT_FRONTEND_NAME" = "React" ]; then
    FRONTEND_URL="${FRONTEND_URLS[0]}"
  else
    FRONTEND_URL="${FRONTEND_URLS[1]}"
  fi
  FRONTEND_DIR="$(basename "$FRONTEND_URL" .git)"
  EXTRA_REPOS_STRING="${EXTRA_REPOS[$tech_index]}"

  echo -n "$CURRENT_TECH_KEY" > "$TECH_FILE"
  echo -n "$CURRENT_FRONTEND_NAME" > "$FRONTEND_FILE"
}

find_compose_file() {
  local dir="$1"
  for name in "compose.yml" "compose.yaml" "docker-compose.yml" "docker-compose.yaml"; do
    if [ -f "$dir/$name" ]; then echo "$dir/$name"; return 0; fi
  done
  return 1
}

# ==================== Actions ====================
wait_for_url(){
  local url="$1"; local timeout="${2:-120}"
  if ! have_cmd curl; then warn "curl not found, skipping wait"; return 0; fi
  log "Waiting for ${BOLD}$url${RESET}..."
  local start; start=$(date +%s)
  while true; do
    if curl -fsS "$url" >/dev/null 2>&1; then ok "Service is up: $url"; return 0; fi
    sleep 2
    if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then
      err "Timeout waiting for $url"
      return 1
    fi
  done
}

action_ensure_all(){ ensure_engine_ready; }

set_target_dir(){
  TARGET_DIR="$BACKEND_DIR"
  [ -d "$TARGET_DIR" ] || { err "Backend dir not found: $TARGET_DIR. Clone first."; return 1; }
}

action_clone_update(){
  clone_or_update "$BACKEND_URL" "$BACKEND_DIR"
  clone_or_update "$FRONTEND_URL" "$FRONTEND_DIR"

  # clone any extra repos listed for the current tech (space separated)
  for url in $EXTRA_REPOS_STRING; do
    [ -n "$url" ] || continue
    dir="$(basename "$url" .git)"
    clone_or_update "$url" "$dir"
  done

  # run post-clone hook inside backend dir
  ( cd "$BACKEND_DIR" && "post_clone_${CURRENT_TECH_KEY}" || true )

  # ensure compose references the chosen frontend path
  patch_compose_frontend_path "$BACKEND_DIR" "$FRONTEND_DIR"
}

action_up(){
  # Temporarily disable the global error trap for this function,
  # as we are handling potential errors manually here.
  trap '' ERR

  ensure_engine_ready
  set_target_dir || { trap on_error ERR; return 1; } # Restore trap and exit if dir is missing

  local up_log; up_log="$(mktemp -t setup-up.XXXXXX)"
  local try=1 max_try=2
  local rc=1 # Default to error status

  while [ $try -le $max_try ]; do
    log "Starting stack ($try/$max_try): $CMD up -d"
    # Use 'set +e' to manually capture the return code instead of exiting the script
    set +e
    ( cd "$TARGET_DIR" && $CMD up -d ) 2>&1 | tee "$up_log"
    rc=${PIPESTATUS[0]}
    set -e

    if [ $rc -eq 0 ]; then
      ok "Stack is up"
      break # Exit the loop on success
    fi

    # Check for the specific, recoverable "proxy" error
    if grep -qi "proxy already running" "$up_log"; then
      warn "Compose failed with a known proxy issue (gvproxy stuck). Attempting an automatic fix..."
      restart_podman_machine_if_proxy_stuck
      try=$((try+1))
      # Loop again for the next try
    else
      # If it's a different, unexpected error, show the log and exit the loop
      err "An unexpected error occurred during 'compose up'. See log below:"
      cat "$up_log"
      break # Exit loop on unhandled error
    fi
  done

  rm -f "$up_log"
  trap on_error ERR # IMPORTANT: Restore the global error trap before leaving the function
  return $rc
}

action_down(){
  set_target_dir || return 1
  ( cd "$TARGET_DIR" && $CMD down ) || true
}

action_build(){
  set_target_dir || return 1
  ( cd "$TARGET_DIR" && $CMD build )
}

action_pull(){
  set_target_dir || return 1
  ( cd "$TARGET_DIR" && $CMD pull )
}

action_status(){
  set_target_dir || return 1
  ( cd "$TARGET_DIR" && $CMD ps )
}

action_logs_snapshot(){
  set_target_dir || return 1
  ( cd "$TARGET_DIR" && $CMD logs --tail=200 )
  pause
}

action_open(){
  local url
  case "$(platform_os)" in
    win) url="http://127.0.0.1:3000/";;
    *)   url="http://localhost:3000/";;
  esac
  log "Open: ${BOLD}$url${RESET}"
  open_url "$url"
}

action_full_run(){
  ensure_engine_ready
  action_clone_update
  action_up
  wait_for_url "$WAIT_URL" "$WAIT_TIMEOUT" || true
  action_open
}

open_url(){
  local url="$1"
  case "${OSTYPE:-}" in
    darwin*) open "$url" || true ;;
    linux*)  xdg-open "$url" >/dev/null 2>&1 || true ;;
    msys*|cygwin*) cmd.exe /c start "" "$url" >/dev/null 2>&1 || true ;;
  esac
}

# ----- Logs menu & export -----
action_logs() {
  ensure_engine_ready || return 1
  set_target_dir || return 1
  clear; print_banner
  printf "${BOLD}$LOG_MENU_PROMPT${RESET}\n"
  local options=("$LOG_MENU_VIEW" "$LOG_MENU_SAVE" "$LOG_MENU_BACK")
  select opt in "${options[@]}"; do
    case $opt in
      "$LOG_MENU_VIEW") ( cd "$TARGET_DIR" && $CMD logs -f ) || true; break ;;
      "$LOG_MENU_SAVE") action_export_logs_as_json; break ;;
      "$LOG_MENU_BACK") break ;;
      *) warn "$WARN_UNKNOWN_CHOICE" ;;
    esac
  done
}

action_export_logs_as_json() {
  set_target_dir || return 1
  local log_dir="app_logs"; mkdir -p "$log_dir"
  local filename="log-$(date +%Y%m%d-%H%M%S).json"
  local outfile="$log_dir/$filename"

  log "Exporting logs to ${BOLD}$outfile${RESET}..."
  # capture logs with timestamps if available; avoid color codes
  (
    echo "["
    cd "$TARGET_DIR"
    # not all compose flavors support --timestamps; fallback to plain
    if $CMD logs --help 2>&1 | grep -q -- "--timestamps"; then
      $CMD logs --no-color --timestamps
    else
      $CMD logs --no-color
    fi | awk '
      BEGIN { first=1 }
      {
        gsub("\\\\","\\\\\\\\" );
        gsub("\"","\\\"" );
        line=$0;
        if (first==0) { printf(",\n") } else { first=0 }
        printf("{\"line\":\"%s\"}", line)
      }
      END { printf("\n") }
    '
    echo "]"
  ) > "$outfile"

  ok "$LOG_SAVED_TO ${BOLD}$outfile${RESET}"
}

# ----- Docs runner -----
action_run_docs() {
  ensure_engine_ready || return 1
  local container_name="sportshub-docs-container"

  # if already running, just open
  if podman ps --filter "name=$container_name" --filter "status=running" -q | grep -q .; then
    log "Documentation service is already running."
    open_url "$DOCS_URL"
    return 0
  fi

  log "$MSG_STARTING_DOCS"
  clone_or_update "$DOCS_REPO_URL" "$DOCS_DIR_NAME"

  local image_name="sportshub/api-docs-playground"

  log "Building docs image: $image_name..."
  ( cd "$DOCS_DIR_NAME" && podman build -t "$image_name" . )

  log "Running new docs container..."
  podman run -d --rm --name "$container_name" -p 5173:5173 "$image_name"

  wait_for_url "$DOCS_URL" || warn "Docs service may not be ready yet."
  open_url "$DOCS_URL"
}

# ==================== Menus ====================
choose_technology(){
  clear; print_banner; printf "${CYAN}${BOLD}${TECH_BANNER_TITLE}${RESET}\n";
  for i in "${!TECHS[@]}"; do printf "  [%d] %s\n" "$((i+1))" "${TECHS[$i]}"; done
  printf "\n  [q] %s\n" "$MENU_Q_QUIT"
  read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
  if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "${#TECHS[@]}" ]; then
    local tech_key="${TECH_KEYS[$((c-1))]}"
    apply_tech_selection "$tech_key"
    log "$MSG_TECH_SET ${BOLD}$CURRENT_TECH${RESET}"
  elif [[ "$c" == "q" ]]; then
    :
  else
    warn "$WARN_UNKNOWN_CHOICE"
  fi
}

choose_frontend(){
  clear; print_banner; printf "${BOLD}$FRONTEND_PROMPT${RESET}\n"
  for i in "${!FRONTEND_NAMES[@]}"; do printf "  [%d] %s\n" "$((i+1))" "${FRONTEND_NAMES[$i]}"; done
  printf "\n  [q] %s\n" "$MENU_Q_QUIT"
  read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
  if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "${#FRONTEND_NAMES[@]}" ]; then
    local fe_name="${FRONTEND_NAMES[$((c-1))]}"
    apply_tech_selection "$CURRENT_TECH_KEY" "$fe_name"
    log "$MSG_FRONTEND_SET ${BOLD}$fe_name${RESET}"
  fi
}

print_menu(){
  echo
  printf "${CYAN}${TECH_BANNER_TITLE}: ${BOLD}%s${RESET} | ${CYAN}${FRONTEND_BANNER_TITLE}: ${BOLD}%s${RESET}\n" "$CURRENT_TECH" "$CURRENT_FRONTEND_NAME"
  printf "${BOLD}$MENU_TITLE${RESET}\n"
  printf "  ${CYAN}[1]${RESET} %s\n" "$MENU_1_FULL_START"
  printf "  ${CYAN}[2]${RESET} %s\n" "$MENU_2_ENSURE_ENGINE"
  printf "  ${CYAN}[3]${RESET} %s\n" "$MENU_3_CLONE_UPDATE"
  printf "  ${CYAN}[4]${RESET} %s\n" "$MENU_4_UP"
  printf "  ${CYAN}[5]${RESET} %s\n" "$MENU_5_DOWN"
  printf "  ${CYAN}[6]${RESET} %s\n" "$MENU_6_BUILD"
  printf "  ${CYAN}[7]${RESET} %s\n" "$MENU_7_PULL"
  printf "  ${CYAN}[8]${RESET} %s\n" "$MENU_8_LOGS"
  printf "  ${CYAN}[L]${RESET} %s\n" "$MENU_L_LOGS_SNAPSHOT"
  printf "  ${CYAN}[9]${RESET} %s\n" "$MENU_9_STATUS"
  printf "  ${CYAN}[T]${RESET} %s\n" "$MENU_T_CHOOSE_TECH"
  printf "  ${CYAN}[F]${RESET} %s\n" "$MENU_F_CHOOSE_FRONTEND"
  printf "  ${CYAN}[D]${RESET} %s\n" "$MENU_D_VIEW_DOCS"
  printf "  ${CYAN}[M]${RESET} %s\n" "$MENU_M_CHOOSE_LANG"
  printf "  ${CYAN}[0]${RESET} %s\n" "$MENU_0_OPEN"
  printf "  ${CYAN}[q]${RESET} %s\n" "$MENU_Q_QUIT"
  echo
}

# ==================== Entry Point ====================
prompt_for_language

# read previous selection if exists, otherwise force choose
CURRENT_TECH_KEY="$(cat "$TECH_FILE" 2>/dev/null || true)"
if [ -z "$CURRENT_TECH_KEY" ]; then
  log "No technology selected yet. Please choose one."
  while [ -z "$CURRENT_TECH_KEY" ]; do
    choose_technology
    CURRENT_TECH_KEY="$(cat "$TECH_FILE" 2>/dev/null || true)"
    if [ -z "$CURRENT_TECH_KEY" ]; then
      warn "Selection is required. Press 'q' to exit."
      read -n 1 -srp "Press any key to try again or 'q' to quit..." key || true
      echo
      if [[ "${key:-}" == "q" || "${key:-}" == "Q" ]]; then echo "Bye!"; exit 0; fi
    fi
  done
fi

CURRENT_FRONTEND_NAME="$(cat "$FRONTEND_FILE" 2>/dev/null || true)"
apply_tech_selection "$CURRENT_TECH_KEY" "$CURRENT_FRONTEND_NAME"

# Resolve compose once
CMD=$(resolve_compose_cmd)

# Start logging to file as well
exec > >(tee -a "$LOG_FILE") 2>&1
log "$MSG_LOGS_SAVED ${BOLD}$LOG_FILE${RESET}"

clear; print_banner

while true; do
  print_menu
  read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
  case "$c" in
    1) run_action action_full_run ;;
    2) run_action action_ensure_all ;;
    3) run_action action_clone_update ;;
    4) run_action action_up ;;
    5) run_action action_down ;;
    6) run_action action_build ;;
    7) run_action action_pull ;;
    8) action_logs; pause ;;
    L|l) action_logs_snapshot ;;
    9) run_action action_status ;;
    T|t) choose_technology; clear; print_banner ;;
    F|f) choose_frontend;  clear; print_banner ;;
    D|d) run_action action_run_docs ;;
    M|m) prompt_for_language; clear; print_banner ;;
    0) run_action action_open ;;
    q|Q) echo "Bye!"; exit 0 ;;
    *)   warn "$WARN_UNKNOWN_CHOICE"; pause ;;
  esac
done
