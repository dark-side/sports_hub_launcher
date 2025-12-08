#!/usr/bin/env bash
# setup.sh — Universal interactive menu for multi-stack app (backend + frontend)
# Engine: Podman (no Docker). macOS / Linux / Windows(Git Bash) supported.

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
set -E

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Sports Hub Setup — Universal interactive menu for multi-stack app (backend + frontend)
Engine: Podman (no Docker). macOS / Linux / Windows(Git Bash) supported.

Options:
  -h, --help          Show this help message and exit
  -v, --version       Show version information
  --no-tee            Disable tee logging (fixes some terminal issues)
  --tech=<KEY>        Pre-select backend technology (java|python|ruby|go|cpp|php|node|net|rust)
  --frontend=<NAME>   Pre-select frontend (React|Angular)

Environment Variables:
  ENABLE_TEE_LOG=0    Disable tee logging
  OPEN_BROWSER=0      Disable auto-opening browser
  WAIT_TIMEOUT=N      Timeout in seconds for waiting on services (default: 180)

Examples:
  $(basename "$0")                    # Interactive mode
  $(basename "$0") --tech=python      # Pre-select Python backend
  $(basename "$0") --no-tee           # Disable tee logging

For more information, see: https://github.com/dark-side/sports_hub_launcher
EOF
  exit 0
}

show_version() {
  echo "Sports Hub Setup v1.0.0"
  exit 0
}

CLI_TECH=""
CLI_FRONTEND=""
for arg in "$@"; do
  case "$arg" in
    -h|--help) show_help ;;
    -v|--version) show_version ;;
    --no-tee) ENABLE_TEE_LOG=0 ;;
    --tech=*) CLI_TECH="${arg#*=}" ;;
    --frontend=*) CLI_FRONTEND="${arg#*=}" ;;
    *) echo "Unknown option: $arg"; echo "Use --help for usage information."; exit 1 ;;
  esac
done

# ==================== Defaults / Globals ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/sportshub-setup"
mkdir -p "$CONFIG_DIR"

ENGINE="podman"
COMPOSE_CMD="${COMPOSE_CMD:-}"
OPEN_BROWSER=${OPEN_BROWSER:-1}
WAIT_URL="${WAIT_URL:-http://localhost:3000/}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180}"
LOG_FILE="$CONFIG_DIR/setup.log"
ENABLE_TEE_LOG=${ENABLE_TEE_LOG:-1}
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

DEFAULT_FES=("React" "React" "React" "Angular" "React" "React" "Angular" "Angular" "React")

FRONTEND_NAMES=("React" "Angular")
FRONTEND_URLS=(
  "https://github.com/dark-side/sports_hub_react_skeleton.git"
  "https://github.com/dark-side/sports_hub_angular_skeleton.git"
)

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

ENV_FILE_MAP=(
  "java:"
  "python:.env.example"
  "ruby:"
  "go:.example.env"
  "cpp:.env.example"
  "php:"
  "node:"
  "net:"
  "rust:.env.example"
)

post_clone_hook() {
  local tech_key="$1"
  local src_file=""

  for entry in "${ENV_FILE_MAP[@]}"; do
    local key="${entry%%:*}"
    local val="${entry#*:}"
    if [[ "$key" == "$tech_key" ]]; then
      src_file="$val"
      break
    fi
  done

  if [[ -n "$src_file" && -f "$src_file" ]]; then
    cp -n "$src_file" .env 2>/dev/null || true
    log "Created .env from $src_file"
  fi
}

# ==================== i18n ====================
set_lang_uk(){
  MSG_LOGS_SAVED="Логи збережено в:"; PROMPT_PRESS_ENTER="Натисніть Enter..."; PROMPT_CHOICE="> Ваш вибір:"; WARN_UNKNOWN_CHOICE="Невідомий вибір";
  # Main menu
  MENU_TITLE="Оберіть дію:"; MENU_1_FULL_START="Повний запуск";
  MENU_S_STACK="Управління Stack"; MENU_T_TOOLS="Інструменти";
  MENU_A_API="API Info"; MENU_D_VIEW_DOCS="Документація";
  MENU_0_OPEN="Відкрити у браузері"; MENU_Q_QUIT="Вихід";
  # Stack submenu
  MENU_STACK_TITLE="Управління Stack"; MENU_UP="Запустити"; MENU_DOWN="Зупинити";
  MENU_BUILD="Перезібрати"; MENU_PULL="Pull образів"; MENU_STATUS="Статус";
  MENU_CLONE="Клонувати/оновити репо"; MENU_BACK="Назад";
  # Tools submenu
  MENU_TOOLS_TITLE="Інструменти"; MENU_LOGS="Переглянути логи"; MENU_LOGS_SAVE="Зберегти логи";
  MENU_ENSURE="Перевірити Podman"; MENU_CLEANUP="Очистити Podman";
  MENU_TECH="Змінити технологію"; MENU_FRONTEND="Змінити фронтенд"; MENU_LANG="Змінити мову";
  # Other
  FRONTEND_BANNER_TITLE="Фронтенд"; TECH_BANNER_TITLE="Технологія";
  FRONTEND_PROMPT="Оберіть фронтенд"; TECH_PROMPT="Оберіть технологію бекенду";
  MSG_FRONTEND_SET="Фронтенд встановлено:"; MSG_TECH_SET="Технологію встановлено:";
  MSG_ACTION_FAILED="Дія завершилась з кодом"; WARN_NO_COMPOSE="Не знайдено 'podman compose'.";
  LOG_MENU_PROMPT="Що зробити з логами?"; LOG_MENU_VIEW="Переглянути"; LOG_MENU_SAVE="Зберегти (JSON)"; LOG_MENU_BACK="Назад";
  LOG_SAVED_TO="Логи збережено:"; MSG_STARTING_DOCS="Запускаю документацію...";
  MSG_CLEANUP_WARN="УВАГА: Видалить ВСІ контейнери, образи та Podman!";
  MSG_CLEANUP_CONFIRM="Продовжити? (y/N):"; MSG_CLEANUP_DONE="Podman очищено.";
  # Section headers
  SECTION_MAIN="ОСНОВНЕ"; SECTION_RESOURCES="РЕСУРСИ"; SECTION_SETTINGS="НАЛАШТУВАННЯ";
  SECTION_STACK_OPS="ОПЕРАЦІЇ"; SECTION_LOGS="ЛОГИ"; SECTION_PODMAN="PODMAN";
}
set_lang_en(){
  MSG_LOGS_SAVED="Logs saved to:"; PROMPT_PRESS_ENTER="Press Enter..."; PROMPT_CHOICE="> Your choice:"; WARN_UNKNOWN_CHOICE="Unknown choice";
  # Main menu
  MENU_TITLE="Select action:"; MENU_1_FULL_START="Full Start";
  MENU_S_STACK="Manage Stack"; MENU_T_TOOLS="Tools";
  MENU_A_API="API Info"; MENU_D_VIEW_DOCS="Documentation";
  MENU_0_OPEN="Open in browser"; MENU_Q_QUIT="Quit";
  # Stack submenu
  MENU_STACK_TITLE="Stack Management"; MENU_UP="Start"; MENU_DOWN="Stop";
  MENU_BUILD="Rebuild"; MENU_PULL="Pull images"; MENU_STATUS="Status";
  MENU_CLONE="Clone/update repos"; MENU_BACK="Back";
  # Tools submenu
  MENU_TOOLS_TITLE="Tools"; MENU_LOGS="View logs"; MENU_LOGS_SAVE="Save logs";
  MENU_ENSURE="Check Podman"; MENU_CLEANUP="Cleanup Podman";
  MENU_TECH="Change technology"; MENU_FRONTEND="Change frontend"; MENU_LANG="Change language";
  # Other
  FRONTEND_BANNER_TITLE="Frontend"; TECH_BANNER_TITLE="Technology";
  FRONTEND_PROMPT="Choose frontend"; TECH_PROMPT="Choose backend technology";
  MSG_FRONTEND_SET="Frontend set to:"; MSG_TECH_SET="Technology set to:";
  MSG_ACTION_FAILED="Action failed with code"; WARN_NO_COMPOSE="Could not find 'podman compose'.";
  LOG_MENU_PROMPT="Logs:"; LOG_MENU_VIEW="View"; LOG_MENU_SAVE="Save (JSON)"; LOG_MENU_BACK="Back";
  LOG_SAVED_TO="Logs saved:"; MSG_STARTING_DOCS="Starting docs...";
  MSG_CLEANUP_WARN="WARNING: Will remove ALL containers, images and Podman!";
  MSG_CLEANUP_CONFIRM="Continue? (y/N):"; MSG_CLEANUP_DONE="Podman cleaned up.";
  # Section headers
  SECTION_MAIN="MAIN"; SECTION_RESOURCES="RESOURCES"; SECTION_SETTINGS="SETTINGS";
  SECTION_STACK_OPS="OPERATIONS"; SECTION_LOGS="LOGS"; SECTION_PODMAN="PODMAN";
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
    echo
    printf "${BOLD}Please choose a language / Будь ласка, оберіть мову${RESET}\n"
    printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    echo
    printf "  ${CYAN}[1]${RESET}  English\n"
    printf "  ${CYAN}[2]${RESET}  Українська\n"
    echo
    printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    echo
    read -rp "$(printf "${BOLD}> Your choice / Ваш вибір:${RESET} ")" c
    case "$c" in
      1) set_lang_en; break ;;
      2) set_lang_uk; break ;;
      *) clear; print_banner; printf "${RED}Invalid selection / Невірний вибір${RESET}\n\n"; sleep 1 ;;
    esac
  done
}

log(){  printf "${BLUE}[setup]${RESET} %b\n" "$*"; }
ok(){   printf "${GREEN}[ ok ]${RESET} %b\n" "$*"; }
warn(){ printf "${YELLOW}[warn]${RESET} %b\n" "$*"; }
err(){  printf "${RED}[err ]${RESET} %b\n" "$*"; }
hint(){ printf "${CYAN}[hint]${RESET} %b\n" "$*"; }

pause(){ echo; read -rp "$(printf "$PROMPT_PRESS_ENTER")" _ || true; }

on_error(){
  err "Failed at line ${BASH_LINENO[0]}: ${BASH_COMMAND}"
}
trap on_error ERR

have_cmd(){ command -v "$1" >/dev/null 2>&1; }
platform_os(){ case "$(uname -s)" in Darwin) echo mac;; Linux) echo linux;; MINGW*|MSYS*|CYGWIN*) echo win;; *) echo unknown;; esac; }

diagnose_podman_issue() {
  local error_output="$1"
  echo
  err "Podman issue detected"
  echo

  if ! have_cmd podman; then
    err "Podman is not installed"
    hint "Run option [2] from the menu for automatic installation"
    return 1
  fi

  if echo "$error_output" | grep -qi "VM does not exist"; then
    err "Podman VM is not initialized"
    hint "Solution:"
    hint "  1. Run: ${BOLD}podman machine init${RESET}"
    hint "  2. Then: ${BOLD}podman machine start${RESET}"
    hint "  3. Or try option [2] in the menu for automatic setup"
    return 1
  fi
  
  if echo "$error_output" | grep -qi "cannot connect to podman\|connection.*refused\|no such file or directory.*podman"; then
    err "Cannot connect to Podman"

    if [ "$(platform_os)" = "mac" ] || [ "$(platform_os)" = "win" ]; then
      hint "Checking Podman machine status..."
      
      if podman machine list >/dev/null 2>&1; then
        local machine_status
        machine_status=$(podman machine list 2>&1 || true)
        echo "$machine_status"
        
        if echo "$machine_status" | grep -qi "Currently running"; then
          warn "Machine is running but connection issues exist"
          hint "Try restarting Podman machine:"
          hint "  ${BOLD}podman machine stop && podman machine start${RESET}"
        else
          warn "Podman machine is not running"
          hint "Try starting it:"
          hint "  ${BOLD}podman machine start${RESET}"
        fi
      else
        err "Podman machine not initialized"
        hint "Initialize the machine:"
        hint "  ${BOLD}podman machine init${RESET}"
        hint "  ${BOLD}podman machine start${RESET}"
      fi
    fi
    
    hint "If the problem persists:"
    hint "  1. Completely uninstall Podman:"
    hint "     ${BOLD}brew uninstall podman-desktop && brew uninstall podman${RESET}"
    hint "  2. Restart your computer"
    hint "  3. Run setup.sh again"
    hint "  More info: https://podman-desktop.io/docs/uninstall"
    return 1
  fi
  
  if echo "$error_output" | grep -qi "proxy already running\|gvproxy"; then
    warn "gvproxy issue detected"
    hint "Attempting automatic fix..."
    return 2
  fi
  
  if echo "$error_output" | grep -qi "permission denied"; then
    err "Permission issue detected"
    hint "May need to add user to group:"
    hint "  ${BOLD}sudo usermod -aG podman \$(whoami)${RESET}"
    hint "Then logout and login again"
    return 1
  fi

  warn "Unknown Podman error"
  hint "Try:"
  hint "  1. Check status: ${BOLD}podman info${RESET}"
  hint "  2. Restart machine: ${BOLD}podman machine restart${RESET}"
  hint "  3. View logs: ${BOLD}podman machine inspect${RESET}"
  return 1
}

run_action() { 
  set +e
  local action_output
  action_output=$("$@" 2>&1)
  local rc=$?
  echo "$action_output"
  
  set -e
  
  if [ $rc -ne 0 ]; then
    warn "$MSG_ACTION_FAILED $rc"
    if echo "$action_output" | grep -qi "podman\|cannot connect\|VM does not exist\|machine"; then
      echo
      warn "Looks like a Podman issue"
      hint "Try option [2] from the menu to check Podman setup"
      hint "Or see the Troubleshooting section in README"
    fi
  fi
  
  pause
}

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
  if have_cmd podman; then 
    ok "Podman is installed"
    return 0
  fi
  
  log "Podman not found. Installing..."
  
  case "$(platform_os)" in
    mac) 
      if have_cmd brew; then 
        log "Installing Podman via Homebrew..."
        if brew install podman; then
          ok "Podman installed successfully"
          return 0
        else
          err "Failed to install Podman via brew"
          hint "Try manually:"
          hint "  ${BOLD}brew install podman${RESET}"
          hint "Or download Podman Desktop: https://podman-desktop.io"
          return 1
        fi
      else 
        err "Homebrew not found. Cannot auto-install Podman"
        hint "Option 1: Install Homebrew first"
        hint "  Visit: https://brew.sh"
        hint "  Then: ${BOLD}brew install podman${RESET}"
        hint "Option 2: Install Podman Desktop"
        hint "  Visit: https://podman-desktop.io"
        return 1
      fi 
      ;;
    linux) 
      log "Installing Podman via apt..."
      if sudo apt-get update && sudo apt-get install -y podman; then
        ok "Podman installed successfully"
        return 0
      else
        err "Failed to install Podman"
        hint "Try manually:"
        hint "  ${BOLD}sudo apt-get install podman${RESET}"
        hint "Or visit: https://podman.io/getting-started/installation"
        return 1
      fi
      ;;
    win) 
      err "Windows detected. Podman requires manual installation"
      hint "Download Podman Desktop:"
      hint "  https://podman-desktop.io/downloads"
      hint "After installation, restart the script"
      return 1 
      ;;
    *) 
      err "Unsupported OS for auto-install of Podman"
      hint "Please install Podman manually: https://podman.io/getting-started/installation"
      return 1 
      ;;
  esac
}

ensure_podman_machine_if_needed(){
  case "$(platform_os)" in
    mac|win)
      if podman info >/dev/null 2>&1; then 
        ok "Podman machine is running"
        return 0
      fi
      
      log "Checking Podman machine status..."
      local machine_output
      machine_output=$(podman machine list 2>&1 || true)

      if ! echo "$machine_output" | grep -qi "NAME"; then
        log "No Podman machine found. Initializing..."
        if ! podman machine init; then
          err "Failed to initialize Podman machine"
          diagnose_podman_issue "$machine_output"
          return 1
        fi
        ok "Podman machine initialized"
      fi

      log "Starting Podman machine..."
      local start_output
      start_output=$(podman machine start 2>&1) || {
        local rc=$?
        err "Failed to start Podman machine"
        diagnose_podman_issue "$start_output"
        return $rc
      }

      if podman info >/dev/null 2>&1; then
        ok "Podman machine started successfully"
        return 0
      else
        err "Podman machine started but cannot connect"
        diagnose_podman_issue "$(podman info 2>&1 || true)"
        return 1
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
  if have_cmd podman && podman compose version >/dev/null 2>&1; then 
    ok "Using built-in 'podman compose'"
    return 0
  fi
  if have_cmd podman-compose; then 
    ok "Using 'podman-compose'"
    return 0
  fi
  
  log "Podman Compose not found. Installing..."
  
  case "$(platform_os)" in
    mac)
      if have_cmd brew; then 
        log "Installing podman-compose via Homebrew..."
        brew install podman-compose || {
          warn "Failed to install podman-compose via brew"
          hint "Try manually:"
          hint "  ${BOLD}brew install podman-compose${RESET}"
        }
      else
        err "Homebrew not found. Please install podman-compose manually"
        hint "Install Homebrew: https://brew.sh"
        hint "Then: ${BOLD}brew install podman-compose${RESET}"
        return 1
      fi
      ;;
    linux)
      if ! have_cmd pip3; then 
        log "Installing pip3..."
        sudo apt-get update && sudo apt-get install -y python3-pip
      fi
      log "Installing podman-compose via pip..."
      sudo pip3 install podman-compose || {
        warn "Failed to install podman-compose via pip"
        hint "Try manually:"
        hint "  ${BOLD}pip3 install podman-compose${RESET}"
      }
      ;;
  esac

  if have_cmd podman && podman compose version >/dev/null 2>&1; then 
    ok "Successfully installed podman compose"
    return 0
  fi
  if have_cmd podman-compose; then 
    ok "Successfully installed podman-compose"
    return 0
  fi
  
  err "$WARN_NO_COMPOSE"
  hint "Install manually:"
  hint "  macOS: ${BOLD}brew install podman-compose${RESET}"
  hint "  Linux: ${BOLD}pip3 install podman-compose${RESET}"
  return 1
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

  for url in $EXTRA_REPOS_STRING; do
    [ -n "$url" ] || continue
    dir="$(basename "$url" .git)"
    clone_or_update "$url" "$dir"
  done

  ( cd "$BACKEND_DIR" && post_clone_hook "$CURRENT_TECH_KEY" )

  patch_compose_frontend_path "$BACKEND_DIR" "$FRONTEND_DIR"
}

action_up(){
  trap '' ERR

  ensure_engine_ready
  set_target_dir || { trap on_error ERR; return 1; }

  local up_log; up_log="$(mktemp -t setup-up.XXXXXX)"
  local try=1 max_try=2
  local rc=1

  while [ $try -le $max_try ]; do
    log "Starting stack ($try/$max_try): $CMD up -d"
    set +e
    ( cd "$TARGET_DIR" && $CMD up -d ) 2>&1 | tee "$up_log"
    rc=${PIPESTATUS[0]}
    set -e

    if [ $rc -eq 0 ]; then
      ok "Stack is up"
      rm -f "$up_log"
      trap on_error ERR
      return 0
    fi

    local log_content
    log_content=$(cat "$up_log")

    if echo "$log_content" | grep -qi "proxy already running\|gvproxy"; then
      warn "Compose failed with a known proxy issue (gvproxy stuck). Attempting an automatic fix..."
      restart_podman_machine_if_proxy_stuck
      try=$((try+1))

    elif echo "$log_content" | grep -qi "cannot connect to podman\|VM does not exist\|connection.*refused"; then
      err "An unexpected error occurred during 'compose up'."
      echo
      cat "$up_log"
      echo
      local diag_rc
      diagnose_podman_issue "$log_content" || diag_rc=$?
      
      if [ "${diag_rc:-0}" -eq 2 ]; then
        warn "Attempting automatic fix..."
        restart_podman_machine_if_proxy_stuck
        try=$((try+1))
      else
        break
      fi
    else
      err "An unexpected error occurred during 'compose up'. See log below:"
      echo
      cat "$up_log"
      echo
      warn "Troubleshooting steps:"
      hint "  1. Check if Podman is running: ${BOLD}podman info${RESET}"
      hint "  2. Review compose file: ${BOLD}cat $TARGET_DIR/compose.yml${RESET}"
      hint "  3. Try running manually: ${BOLD}cd $TARGET_DIR && $CMD up${RESET}"
      break
    fi
  done

  rm -f "$up_log"
  trap on_error ERR
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
  local raw_log; raw_log="$(mktemp)"

  log "Exporting logs to ${BOLD}$outfile${RESET}..."

  (
    cd "$TARGET_DIR"
    if $CMD logs --help 2>&1 | grep -q -- "--timestamps"; then
      $CMD logs --no-color --timestamps 2>/dev/null
    else
      $CMD logs --no-color 2>/dev/null
    fi
  ) > "$raw_log"

  if have_cmd jq; then
    jq -R -s 'split("\n") | map(select(length > 0)) | map({line: .})' < "$raw_log" > "$outfile"
  elif have_cmd python3; then
    python3 -c "
import json, sys
lines = [{'line': l} for l in sys.stdin.read().splitlines() if l]
print(json.dumps(lines, ensure_ascii=False, indent=2))
" < "$raw_log" > "$outfile"
  elif have_cmd python; then
    python -c "
import json, sys
lines = [{'line': l} for l in sys.stdin.read().splitlines() if l]
print(json.dumps(lines, ensure_ascii=False, indent=2))
" < "$raw_log" > "$outfile"
  else
    (
      echo "["
      awk '
        BEGIN { first=1 }
        {
          gsub(/\\/, "\\\\");
          gsub(/"/, "\\\"");
          gsub(/\t/, "\\t");
          gsub(/\r/, "");
          if (first==0) { printf(",\n") } else { first=0 }
          printf("{\"line\":\"%s\"}", $0)
        }
        END { if (first==0) printf("\n") }
      ' < "$raw_log"
      echo "]"
    ) > "$outfile"
  fi

  rm -f "$raw_log"
  ok "$LOG_SAVED_TO ${BOLD}$outfile${RESET}"
}

action_run_docs() {
  ensure_engine_ready || return 1
  local container_name="sportshub-docs-container"
  local docs_path="$SCRIPT_DIR/$DOCS_DIR_NAME"

  if podman ps --filter "name=$container_name" --filter "status=running" -q 2>/dev/null | grep -q .; then
    log "Documentation service is already running."
    open_url "$DOCS_URL"
    return 0

  fi

  if podman ps -a --filter "name=$container_name" -q 2>/dev/null | grep -q .; then
    log "Removing stopped docs container..."
    podman rm -f "$container_name" >/dev/null 2>&1 || true
  fi

  log "$MSG_STARTING_DOCS"

  clone_or_update "$DOCS_REPO_URL" "$docs_path"

  if [ ! -d "$docs_path" ]; then
    err "Failed to clone docs repository to $docs_path"
    return 1
  fi

  local image_name="sportshub/api-docs-playground"

  log "Building docs image: $image_name..."
  if ! ( cd "$docs_path" && podman build -t "$image_name" . ); then
    err "Failed to build docs image"
    return 1
  fi

  log "Running new docs container..."
  if ! podman run -d --rm --name "$container_name" -p 5173:5173 "$image_name"; then
    err "Failed to start docs container"
    hint "Check if port 5173 is already in use: ${BOLD}lsof -i :5173${RESET}"
    return 1
  fi

  wait_for_url "$DOCS_URL" || warn "Docs service may not be ready yet."
  open_url "$DOCS_URL"
}

# ==================== API Info ====================
action_api_info() {
  local api_port="3002"
  local frontend_port="3000"
  
  clear; print_banner
  echo
  printf "  ${BOLD}API Information${RESET}\n"
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "  ${BOLD}Backend API${RESET}\n"
  printf "    URL:  ${GREEN}http://localhost:${api_port}${RESET}\n"
  echo
  printf "  ${BOLD}Endpoints${RESET}\n"
  printf "    ${CYAN}GET ${RESET} /api/articles          - List all articles\n"
  printf "    ${CYAN}GET ${RESET} /api/articles/:id      - Get article by ID\n"
  printf "    ${CYAN}POST${RESET} /api/articles          - Create article\n"
  printf "    ${CYAN}GET ${RESET} /api/users             - List users\n"
  printf "    ${CYAN}POST${RESET} /users/registrations   - Register user\n"
  printf "    ${CYAN}POST${RESET} /api/auth/sign_in      - Sign in\n"
  echo
  printf "  ${BOLD}Example curl${RESET}\n"
  printf "    ${YELLOW}curl http://localhost:${api_port}/api/articles${RESET}\n"
  printf "    ${YELLOW}curl http://localhost:${api_port}/api/articles/1${RESET}\n"
  echo
  printf "  ${BOLD}Frontend${RESET}\n"
  printf "    URL:  ${GREEN}http://localhost:${frontend_port}${RESET}\n"
  echo
  printf "  ${BOLD}Documentation${RESET}\n"
  printf "    URL:  ${GREEN}http://localhost:5173${RESET} (run [D] to start)\n"
  echo
}

# ==================== Podman Cleanup ====================
action_cleanup_podman() {
  echo
  warn "$MSG_CLEANUP_WARN"
  echo
  printf "  ${YELLOW}podman stop -a${RESET}             - Stop all containers\n"
  printf "  ${YELLOW}podman rm -a${RESET}               - Remove all containers\n"
  printf "  ${YELLOW}podman rmi -a -f${RESET}           - Remove all images\n"
  printf "  ${YELLOW}podman system prune -a -f${RESET}  - Prune system\n"
  printf "  ${YELLOW}podman machine rm -f${RESET}       - Remove Podman VM\n"
  if [[ "$(platform_os)" == "mac" ]]; then
    printf "  ${YELLOW}brew uninstall podman-common${RESET}\n"
    printf "  ${YELLOW}brew uninstall podman${RESET}\n"
  fi
  printf "  ${YELLOW}rm -rf ~/.config/containers ...${RESET}\n"
  echo

  read -rp "$(printf "${BOLD}$MSG_CLEANUP_CONFIRM${RESET} ")" confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log "Cleanup cancelled."
    return 0
  fi

  log "Stopping all containers..."
  podman stop -a 2>/dev/null || true

  log "Removing all containers..."
  podman rm -a 2>/dev/null || true

  log "Removing all images..."
  podman rmi -a -f 2>/dev/null || true

  log "Pruning system..."
  podman system prune -a -f 2>/dev/null || true

  if [[ "$(platform_os)" == "mac" || "$(platform_os)" == "win" ]]; then
    log "Removing Podman machine..."
    podman machine stop 2>/dev/null || true
    podman machine rm -f 2>/dev/null || true
  fi

  log "Removing Podman config directories..."
  rm -rf ~/.config/containers ~/.local/share/containers ~/.cache/podman 2>/dev/null || true

  if [[ "$(platform_os)" == "mac" ]]; then
    echo
    read -rp "$(printf "${BOLD}Uninstall Podman via brew too? (y/N):${RESET} ")" uninstall_brew
    if [[ "$uninstall_brew" =~ ^[Yy]$ ]]; then
      log "Uninstalling Podman via Homebrew..."
      brew uninstall podman-common 2>/dev/null || true
      brew uninstall podman 2>/dev/null || true
      ok "Podman uninstalled via brew"
    fi
  fi

  ok "$MSG_CLEANUP_DONE"
  hint "Run option [2] to reinstall Podman when needed."
}

# ==================== Menus ====================
choose_technology(){
  clear; print_banner
  echo
  printf "  ${BOLD}${TECH_PROMPT}${RESET}\n"
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  for i in "${!TECHS[@]}"; do 
    printf "    ${CYAN}[%d]${RESET}  %s\n" "$((i+1))" "${TECHS[$i]}"
  done
  echo
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  printf "    ${CYAN}[0]${RESET}  %s\n" "$MENU_BACK"
  echo
  read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
  if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "${#TECHS[@]}" ]; then
    local tech_key="${TECH_KEYS[$((c-1))]}"
    apply_tech_selection "$tech_key"
    log "$MSG_TECH_SET ${BOLD}$CURRENT_TECH${RESET}"
  fi
}

choose_frontend(){
  clear; print_banner
  echo
  printf "  ${BOLD}${FRONTEND_PROMPT}${RESET}\n"
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  for i in "${!FRONTEND_NAMES[@]}"; do 
    printf "    ${CYAN}[%d]${RESET}  %s\n" "$((i+1))" "${FRONTEND_NAMES[$i]}"
  done
  echo
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  printf "    ${CYAN}[0]${RESET}  %s\n" "$MENU_BACK"
  echo
  read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
  if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "${#FRONTEND_NAMES[@]}" ]; then
    local fe_name="${FRONTEND_NAMES[$((c-1))]}"
    apply_tech_selection "$CURRENT_TECH_KEY" "$fe_name"
    log "$MSG_FRONTEND_SET ${BOLD}$fe_name${RESET}"
  fi
}

# Main menu
print_menu(){
  echo
  printf "  ${BOLD}${TECH_BANNER_TITLE}:${RESET} ${GREEN}%s${RESET}    ${BOLD}${FRONTEND_BANNER_TITLE}:${RESET} ${GREEN}%s${RESET}\n" "$CURRENT_TECH" "$CURRENT_FRONTEND_NAME"
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "  ${BOLD}${SECTION_MAIN}${RESET}\n"
  printf "    ${GREEN}[1]${RESET}  %s\n" "$MENU_1_FULL_START"
  printf "    ${CYAN}[S]${RESET}  %s\n" "$MENU_S_STACK"
  printf "    ${CYAN}[X]${RESET}  %s\n" "$MENU_T_TOOLS"
  echo
  printf "  ${BOLD}${SECTION_RESOURCES}${RESET}\n"
  printf "    ${CYAN}[A]${RESET}  %s\n" "$MENU_A_API"
  printf "    ${CYAN}[D]${RESET}  %s\n" "$MENU_D_VIEW_DOCS"
  printf "    ${CYAN}[0]${RESET}  %s\n" "$MENU_0_OPEN"
  echo
  printf "  ${BOLD}${SECTION_SETTINGS}${RESET}\n"
  printf "    ${YELLOW}[T]${RESET}  %s\n" "$MENU_TECH"
  printf "    ${YELLOW}[F]${RESET}  %s\n" "$MENU_FRONTEND"
  printf "    ${YELLOW}[M]${RESET}  %s\n" "$MENU_LANG"
  echo
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  printf "    ${RED}[Q]${RESET}  %s\n" "$MENU_Q_QUIT"
  echo
}

# Stack submenu
menu_stack(){
  while true; do
    clear; print_banner
    echo
    printf "  ${BOLD}$MENU_STACK_TITLE${RESET}\n"
    printf "  ${BOLD}${TECH_BANNER_TITLE}:${RESET} ${GREEN}%s${RESET}\n" "$CURRENT_TECH"
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    echo
    printf "  ${BOLD}${SECTION_STACK_OPS}${RESET}\n"
    printf "    ${GREEN}[1]${RESET}  %s\n" "$MENU_UP"
    printf "    ${YELLOW}[2]${RESET}  %s\n" "$MENU_DOWN"
    printf "    ${CYAN}[3]${RESET}  %s\n" "$MENU_BUILD"
    printf "    ${CYAN}[4]${RESET}  %s\n" "$MENU_PULL"
    printf "    ${CYAN}[5]${RESET}  %s\n" "$MENU_STATUS"
    printf "    ${CYAN}[6]${RESET}  %s\n" "$MENU_CLONE"
    echo
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    printf "    ${CYAN}[0]${RESET}  %s\n" "$MENU_BACK"
    echo
    read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
    case "$c" in
      1) run_action action_up ;;
      2) run_action action_down ;;
      3) run_action action_build ;;
      4) run_action action_pull ;;
      5) run_action action_status ;;
      6) run_action action_clone_update ;;
      0|q|Q) return ;;
      *) warn "$WARN_UNKNOWN_CHOICE"; pause ;;
    esac
  done
}

# Tools submenu
menu_tools(){
  while true; do
    clear; print_banner
    echo
    printf "  ${BOLD}$MENU_TOOLS_TITLE${RESET}\n"
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    echo
    printf "  ${BOLD}${SECTION_LOGS}${RESET}\n"
    printf "    ${CYAN}[1]${RESET}  %s\n" "$MENU_LOGS"
    printf "    ${CYAN}[2]${RESET}  %s\n" "$MENU_LOGS_SAVE"
    echo
    printf "  ${BOLD}${SECTION_PODMAN}${RESET}\n"
    printf "    ${CYAN}[3]${RESET}  %s\n" "$MENU_ENSURE"
    printf "    ${RED}[4]${RESET}  %s\n" "$MENU_CLEANUP"
    echo
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    printf "    ${CYAN}[0]${RESET}  %s\n" "$MENU_BACK"
    echo
    read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
    case "$c" in
      1) action_logs; pause ;;
      2) action_export_logs_as_json; pause ;;
      3) run_action action_ensure_all ;;
      4) action_cleanup_podman; pause ;;
      0|q|Q) return ;;
      *) warn "$WARN_UNKNOWN_CHOICE"; pause ;;
    esac
  done
}

# ==================== Entry Point ====================
prompt_for_language

# Use CLI args if provided, otherwise read from config
if [[ -n "$CLI_TECH" ]]; then
  CURRENT_TECH_KEY="$CLI_TECH"
else
  CURRENT_TECH_KEY="$(cat "$TECH_FILE" 2>/dev/null || true)"
fi

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

if [[ -n "$CLI_FRONTEND" ]]; then
  CURRENT_FRONTEND_NAME="$CLI_FRONTEND"
else
  CURRENT_FRONTEND_NAME="$(cat "$FRONTEND_FILE" 2>/dev/null || true)"
fi

apply_tech_selection "$CURRENT_TECH_KEY" "$CURRENT_FRONTEND_NAME"

CMD=$(resolve_compose_cmd)

if [[ "${ENABLE_TEE_LOG:-1}" == "1" ]]; then
  exec > >(tee -a "$LOG_FILE") 2>&1
  log "$MSG_LOGS_SAVED ${BOLD}$LOG_FILE${RESET}"
fi

clear; print_banner

while true; do
  print_menu
  read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
  case "$c" in
    1) run_action action_full_run ;;
    S|s) menu_stack ;;
    A|a) action_api_info; pause ;;
    D|d) run_action action_run_docs ;;
    T|t) choose_technology ;;
    F|f) choose_frontend ;;
    M|m) prompt_for_language ;;
    X|x) menu_tools ;;
    0) run_action action_open ;;
    q|Q) echo "Bye!"; exit 0 ;;
    *)   warn "$WARN_UNKNOWN_CHOICE"; pause ;;
  esac
  clear; print_banner
done
