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
  # Main menu - new structure
  MENU_TITLE="Оберіть дію:"; MENU_Q_QUIT="Вихід";
  # Section: ЗАПУСК
  MENU_1_FULL_START="Повний запуск (автоматично все)";
  MENU_2_START="Запустити Stack"; MENU_3_STOP="Зупинити Stack";
  # Section: СТАТУС І ЛОГИ
  MENU_4_STATUS="Статус контейнерів"; MENU_5_LOGS="Переглянути логи";
  MENU_6_OPEN="Відкрити у браузері";
  # Section: ДОКУМЕНТАЦІЯ
  MENU_7_API="API Info"; MENU_8_DOCS="Документація";
  # Section: НАЛАШТУВАННЯ (submenu)
  MENU_9_SETTINGS="Налаштування";
  # Section: ДОДАТКОВО (submenu)
  MENU_0_ADVANCED="Розширені інструменти";
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
  LOG_MENU_PROMPT="Що зробити з логами?"; LOG_MENU_VIEW="Переглянути (live)"; LOG_MENU_SAVE="Зберегти (JSON)"; LOG_MENU_BACK="Назад";
  LOG_MENU_BACKEND="Тільки Backend"; LOG_MENU_FRONTEND="Тільки Frontend"; LOG_MENU_DB="Тільки Database"; LOG_MENU_TAIL="Останні N рядків";
  LOG_SAVED_TO="Логи збережено:"; MSG_STARTING_DOCS="Запускаю документацію...";
  MSG_CLEANUP_WARN="УВАГА: Видалить ВСІ контейнери, образи та Podman!";
  MSG_CLEANUP_CONFIRM="Продовжити? (y/N):"; MSG_CLEANUP_DONE="Podman очищено.";
  # Section headers - new structure
  SECTION_LAUNCH="ЗАПУСК"; SECTION_STATUS="СТАТУС І ЛОГИ"; SECTION_DOCS="ДОКУМЕНТАЦІЯ";
  SECTION_SETTINGS="НАЛАШТУВАННЯ"; SECTION_ADVANCED="ДОДАТКОВО";
  SECTION_STACK_OPS="ОПЕРАЦІЇ"; SECTION_LOGS="ЛОГИ"; SECTION_PODMAN="PODMAN";
  # Settings submenu
  MENU_SETTINGS_TITLE="Налаштування";
  MENU_SET_TECH="Змінити технологію"; MENU_SET_FRONTEND="Змінити фронтенд"; MENU_SET_LANG="Змінити мову";
  # Advanced submenu
  MENU_ADVANCED_TITLE="Розширені інструменти";
  MENU_ADV_BUILD="Перезібрати контейнери"; MENU_ADV_PULL="Pull образів";
  MENU_ADV_CLONE="Клонувати/оновити репо"; MENU_ADV_ENSURE="Перевірити Podman";
  MENU_ADV_EXPORT_ENV="Експорт .env для мобайл"; MENU_ADV_RESET_DB="Скинути базу даних";
  MENU_ADV_CLEANUP="Очистити Podman"; MENU_ADV_SAVE_LOGS="Зберегти логи";
  MENU_ADV_SEED_DB="Заповнити БД тестовими даними";
  # New features
  MENU_HEALTH="Перевірка API"; MENU_RESET_DB="Скинути базу даних";
  MENU_EXPORT_ENV="Експорт .env для мобайл"; MENU_HELP="Довідка / Quick Start";
  MENU_HEALTH_DASHBOARD="Health Check Dashboard";
  MSG_HEALTH_OK="API працює!"; MSG_HEALTH_FAIL="API не відповідає";
  # Health Dashboard
  MSG_DASHBOARD_TITLE="СТАТУС СЕРВІСІВ"; MSG_CHECKING="Перевіряю...";
  MSG_SERVICE_BACKEND="Backend"; MSG_SERVICE_FRONTEND="Frontend"; MSG_SERVICE_DB="Database";
  MSG_SERVICE_API="API Endpoint"; MSG_STATUS_OK="OK"; MSG_STATUS_FAIL="ПОМИЛКА";
  MSG_STATUS_RUNNING="Працює"; MSG_STATUS_STOPPED="Зупинено";
  # Seed DB
  MSG_SEED_DB_TITLE="Заповнення БД тестовими даними";
  MSG_SEED_DB_CONFIRM="Заповнити базу тестовими даними? (y/N):";
  MSG_SEED_DB_DONE="Тестові дані додано!"; MSG_SEED_DB_FAIL="Помилка заповнення БД";
  MSG_RESET_DB_WARN="УВАГА: Це видалить всі дані з бази!";
  MSG_RESET_DB_CONFIRM="Скинути базу? (y/N):";
  MSG_RESET_DB_DONE="Базу даних скинуто.";
  MSG_ENV_EXPORTED=".env файл експортовано:";
  # Full run completion
  MSG_SUCCESS="Успіх!"; MSG_APP_RUNNING="Ваш додаток працює на";
  MSG_VIEW_LOGS="Переглянути логи"; MSG_RETURN_MENU="Повернутися в меню";
  MSG_LIVE_LOGS="Логи (Ctrl+C для виходу)";
  # Full run steps
  MSG_FULL_SETUP_TITLE="Повний запуск";
  MSG_FULL_SETUP_DESC="Це займе кілька хвилин. Ось що відбудеться:";
  MSG_STEP_1="Перевірка та встановлення Podman";
  MSG_STEP_2="Завантаження коду з GitHub";
  MSG_STEP_3="Збірка та запуск контейнерів";
  MSG_STEP_4="Очікування готовності додатку";
  MSG_STEP_5="Відкриття у браузері";
  MSG_PODMAN_READY="Podman готовий!";
  MSG_CODE_DOWNLOADED="Код завантажено!";
  MSG_CONTAINERS_STARTED="Контейнери запущено!";
  MSG_APP_READY="Додаток готовий!";
}
set_lang_en(){
  MSG_LOGS_SAVED="Logs saved to:"; PROMPT_PRESS_ENTER="Press Enter..."; PROMPT_CHOICE="> Your choice:"; WARN_UNKNOWN_CHOICE="Unknown choice";
  # Main menu - new structure
  MENU_TITLE="Select action:"; MENU_Q_QUIT="Quit";
  # Section: LAUNCH
  MENU_1_FULL_START="Full Start (automatic)";
  MENU_2_START="Start Stack"; MENU_3_STOP="Stop Stack";
  # Section: STATUS & LOGS
  MENU_4_STATUS="Container Status"; MENU_5_LOGS="View Logs";
  MENU_6_OPEN="Open in Browser";
  # Section: DOCUMENTATION
  MENU_7_API="API Info"; MENU_8_DOCS="Documentation";
  # Section: SETTINGS (submenu)
  MENU_9_SETTINGS="Settings";
  # Section: ADVANCED (submenu)
  MENU_0_ADVANCED="Advanced Tools";
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
  LOG_MENU_PROMPT="Logs:"; LOG_MENU_VIEW="View (live)"; LOG_MENU_SAVE="Save (JSON)"; LOG_MENU_BACK="Back";
  LOG_MENU_BACKEND="Backend only"; LOG_MENU_FRONTEND="Frontend only"; LOG_MENU_DB="Database only"; LOG_MENU_TAIL="Last N lines";
  LOG_SAVED_TO="Logs saved:"; MSG_STARTING_DOCS="Starting docs...";
  MSG_CLEANUP_WARN="WARNING: Will remove ALL containers, images and Podman!";
  MSG_CLEANUP_CONFIRM="Continue? (y/N):"; MSG_CLEANUP_DONE="Podman cleaned up.";
  # Section headers - new structure
  SECTION_LAUNCH="LAUNCH"; SECTION_STATUS="STATUS & LOGS"; SECTION_DOCS="DOCUMENTATION";
  SECTION_SETTINGS="SETTINGS"; SECTION_ADVANCED="ADVANCED";
  SECTION_STACK_OPS="OPERATIONS"; SECTION_LOGS="LOGS"; SECTION_PODMAN="PODMAN";
  # Settings submenu
  MENU_SETTINGS_TITLE="Settings";
  MENU_SET_TECH="Change Technology"; MENU_SET_FRONTEND="Change Frontend"; MENU_SET_LANG="Change Language";
  # Advanced submenu
  MENU_ADVANCED_TITLE="Advanced Tools";
  MENU_ADV_BUILD="Rebuild Containers"; MENU_ADV_PULL="Pull Images";
  MENU_ADV_CLONE="Clone/Update Repos"; MENU_ADV_ENSURE="Check Podman";
  MENU_ADV_EXPORT_ENV="Export .env for Mobile"; MENU_ADV_RESET_DB="Reset Database";
  MENU_ADV_CLEANUP="Cleanup Podman"; MENU_ADV_SAVE_LOGS="Save Logs";
  MENU_ADV_SEED_DB="Seed Database with Test Data";
  # New features
  MENU_HEALTH="API Health Check"; MENU_RESET_DB="Reset Database";
  MENU_EXPORT_ENV="Export .env for mobile"; MENU_HELP="Help / Quick Start";
  MENU_HEALTH_DASHBOARD="Health Check Dashboard";
  MSG_HEALTH_OK="API is working!"; MSG_HEALTH_FAIL="API is not responding";
  # Health Dashboard
  MSG_DASHBOARD_TITLE="SERVICE STATUS"; MSG_CHECKING="Checking...";
  MSG_SERVICE_BACKEND="Backend"; MSG_SERVICE_FRONTEND="Frontend"; MSG_SERVICE_DB="Database";
  MSG_SERVICE_API="API Endpoint"; MSG_STATUS_OK="OK"; MSG_STATUS_FAIL="ERROR";
  MSG_STATUS_RUNNING="Running"; MSG_STATUS_STOPPED="Stopped";
  # Seed DB
  MSG_SEED_DB_TITLE="Seed Database with Test Data";
  MSG_SEED_DB_CONFIRM="Seed database with test data? (y/N):";
  MSG_SEED_DB_DONE="Test data added!"; MSG_SEED_DB_FAIL="Failed to seed database";
  MSG_RESET_DB_WARN="WARNING: This will delete all data from the database!";
  MSG_RESET_DB_CONFIRM="Reset database? (y/N):";
  MSG_RESET_DB_DONE="Database has been reset.";
  MSG_ENV_EXPORTED=".env file exported to:";
  # Full run completion
  MSG_SUCCESS="Success!"; MSG_APP_RUNNING="Your application is running at";
  MSG_VIEW_LOGS="View live logs"; MSG_RETURN_MENU="Return to menu";
  MSG_LIVE_LOGS="Live Logs (Press Ctrl+C to exit)";
  # Full run steps
  MSG_FULL_SETUP_TITLE="Starting Full Setup";
  MSG_FULL_SETUP_DESC="This will take a few minutes. Here's what will happen:";
  MSG_STEP_1="Check and install Podman (container engine)";
  MSG_STEP_2="Download project code from GitHub";
  MSG_STEP_3="Build and start containers";
  MSG_STEP_4="Wait for application to be ready";
  MSG_STEP_5="Open in your browser";
  MSG_PODMAN_READY="Podman is ready!";
  MSG_CODE_DOWNLOADED="Code downloaded!";
  MSG_CONTAINERS_STARTED="Containers started!";
  MSG_APP_READY="Application is ready!";
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

show_welcome_screen() {
  local is_first_run="$1"
  if [[ "$is_first_run" != "true" ]]; then return 0; fi
  
  clear; print_banner
  echo
  printf "${BOLD}${GREEN}Welcome to Sports Hub Setup!${RESET}\n"
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "This tool will help you set up and run Sports Hub projects.\n"
  printf "Don't worry if you're new to containers - we'll handle everything!\n"
  echo
  printf "${BOLD}What this tool does:${RESET}\n"
  printf "  ${GREEN}✓${RESET} Installs required tools automatically\n"
  printf "  ${GREEN}✓${RESET} Downloads project code\n"
  printf "  ${GREEN}✓${RESET} Starts the application\n"
  printf "  ${GREEN}✓${RESET} Opens it in your browser\n"
  echo
  printf "${BOLD}You'll need to:${RESET}\n"
  printf "  1. Choose your preferred language\n"
  printf "  2. Select backend technology (e.g., Python, Java)\n"
  printf "  3. Select frontend framework (React or Angular)\n"
  printf "  4. Press [1] for Full Start - that's it!\n"
  echo
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  read -rp "$(printf "${BOLD}Press Enter to continue...${RESET}")" _
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
    warn "Podman VM is missing or corrupted. Attempting automatic recovery..."
    echo
    
    # Try to recreate the machine
    log "Initializing new Podman machine..."
    if podman machine init --cpus 4 --memory 4096 2>&1; then
      ok "Machine initialized"
      log "Starting Podman machine..."
      if podman machine start 2>&1; then
        ok "Podman machine recovered successfully!"
        return 0
      fi
    fi
    
    err "Automatic recovery failed"
    hint "Manual solution:"
    hint "  1. Run: ${BOLD}podman machine rm -f podman-machine-default${RESET}"
    hint "  2. Then: ${BOLD}podman machine init${RESET}"
    hint "  3. Then: ${BOLD}podman machine start${RESET}"
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
          warn "Machine is running but connection issues exist. Attempting restart..."
          if podman machine stop 2>&1 && podman machine start 2>&1; then
            ok "Podman machine restarted successfully!"
            return 0
          else
            err "Restart failed"
            hint "Try manually: ${BOLD}podman machine stop && podman machine start${RESET}"
          fi
        else
          warn "Podman machine is not running. Starting..."
          if podman machine start 2>&1; then
            ok "Podman machine started successfully!"
            return 0
          else
            err "Failed to start machine"
            hint "Try: ${BOLD}podman machine start${RESET}"
          fi
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
  clear; print_banner
  echo
  printf "${BOLD}${GREEN}$MSG_FULL_SETUP_TITLE${RESET}\n"
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "$MSG_FULL_SETUP_DESC\n"
  echo
  printf "  ${CYAN}[1/5]${RESET} %s\n" "$MSG_STEP_1"
  printf "  ${CYAN}[2/5]${RESET} %s\n" "$MSG_STEP_2"
  printf "  ${CYAN}[3/5]${RESET} %s\n" "$MSG_STEP_3"
  printf "  ${CYAN}[4/5]${RESET} %s\n" "$MSG_STEP_4"
  printf "  ${CYAN}[5/5]${RESET} %s\n" "$MSG_STEP_5"
  echo
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  pause
  
  echo
  log "[1/5] $MSG_STEP_1..."
  ensure_engine_ready
  ok "$MSG_PODMAN_READY"
  echo
  
  log "[2/5] $MSG_STEP_2..."
  action_clone_update
  ok "$MSG_CODE_DOWNLOADED"
  echo
  
  log "[3/5] $MSG_STEP_3..."
  action_up
  ok "$MSG_CONTAINERS_STARTED"
  echo
  
  log "[4/5] $MSG_STEP_4..."
  wait_for_url "$WAIT_URL" "$WAIT_TIMEOUT" || true
  ok "$MSG_APP_READY"
  echo
  
  log "[5/5] $MSG_STEP_5..."
  action_open
  echo
  ok "${GREEN}${BOLD}$MSG_SUCCESS${RESET} $MSG_APP_RUNNING ${BOLD}$WAIT_URL${RESET}"
  echo
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "  ${CYAN}[L]${RESET}  %s\n" "$MSG_VIEW_LOGS"
  printf "  ${CYAN}[Enter]${RESET}  %s\n" "$MSG_RETURN_MENU"
  echo
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" log_choice
  case "$log_choice" in
    L|l)
      printf "\n${BOLD}$MSG_LIVE_LOGS${RESET}\n\n"
      ( cd "$TARGET_DIR" && $CMD logs -f ) || true
      ;;
  esac
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
  
  while true; do
    clear; print_banner
    echo
    printf "  ${BOLD}${SECTION_LOGS}${RESET}\n"
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    echo
    printf "  ${BOLD}Live Logs${RESET}\n"
    printf "    ${CYAN}[1]${RESET}  %s\n" "$LOG_MENU_VIEW"
    printf "    ${CYAN}[2]${RESET}  %s\n" "$LOG_MENU_BACKEND"
    printf "    ${CYAN}[3]${RESET}  %s\n" "$LOG_MENU_FRONTEND"
    printf "    ${CYAN}[4]${RESET}  %s\n" "$LOG_MENU_DB"
    echo
    printf "  ${BOLD}Other${RESET}\n"
    printf "    ${CYAN}[5]${RESET}  %s\n" "$LOG_MENU_TAIL"
    printf "    ${CYAN}[6]${RESET}  %s\n" "$LOG_MENU_SAVE"
    echo
    printf "    ${CYAN}[0]${RESET}  %s\n" "$LOG_MENU_BACK"
    echo
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    echo
    read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
    case "$c" in
      1) printf "\n${BOLD}Live Logs${RESET} (Ctrl+C to exit)\n\n"; ( cd "$TARGET_DIR" && $CMD logs -f ) || true ;;
      2) printf "\n${BOLD}Backend Logs${RESET} (Ctrl+C to exit)\n\n"; ( cd "$TARGET_DIR" && $CMD logs -f backend ) || true ;;
      3) printf "\n${BOLD}Frontend Logs${RESET} (Ctrl+C to exit)\n\n"; ( cd "$TARGET_DIR" && $CMD logs -f react_frontend ) || true ;;
      4) printf "\n${BOLD}Database Logs${RESET} (Ctrl+C to exit)\n\n"; ( cd "$TARGET_DIR" && $CMD logs -f db ) || true ;;
      5) action_logs_tail ;;
      6) action_export_logs_as_json ;;
      0|q|Q) return ;;
      *) warn "$WARN_UNKNOWN_CHOICE"; pause ;;
    esac
  done
}

action_logs_tail() {
  local lines
  read -rp "$(printf "${BOLD}Number of lines (default 100):${RESET} ")" lines
  lines="${lines:-100}"
  clear
  printf "${BOLD}Last $lines lines${RESET}\n"
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n\n"
  ( cd "$TARGET_DIR" && $CMD logs --tail="$lines" ) || true
  echo
  pause
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
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "  ${BOLD}Registration Requirements${RESET} ${YELLOW}(422 errors? check this)${RESET}\n"
  printf "    - email:    valid format (user@domain.com)\n"
  printf "    - password: min 8 chars, 1 uppercase, 1 number\n"
  printf "    - password_confirmation: must match password\n"
  echo
  printf "  ${BOLD}Example Registration${RESET}\n"
  printf "    ${YELLOW}curl -X POST http://localhost:${api_port}/users/registrations \\${RESET}\n"
  printf "    ${YELLOW}  -H \"Content-Type: application/json\" \\${RESET}\n"
  printf "    ${YELLOW}  -d '{\"email\":\"test@example.com\",\"password\":\"Password1\",\"password_confirmation\":\"Password1\"}'${RESET}\n"
  echo
  printf "  ${RED}⚠ Important for Mobile Devs${RESET}\n"
  printf "    ID field type varies by backend technology:\n"
  printf "    - Java, Python, Ruby: ${CYAN}id${RESET} is ${YELLOW}integer${RESET}\n"
  printf "    - Some backends may return ${CYAN}id${RESET} as ${YELLOW}string${RESET}\n"
  printf "    ${BOLD}Recommendation:${RESET} Parse ID as String in your mobile app\n"
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

# ==================== Health Check ====================
action_health_check() {
  local api_port="3002"
  local api_url="http://localhost:${api_port}"
  
  echo
  log "Checking API health at ${BOLD}${api_url}${RESET}..."
  echo
  
  # Check main API endpoint
  printf "  %-30s" "Backend API..."
  if curl -s --max-time 5 "${api_url}/api/articles" >/dev/null 2>&1; then
    printf "${GREEN}OK${RESET}\n"
  else
    printf "${RED}FAIL${RESET}\n"
  fi
  
  # Check specific endpoints
  local endpoints=("/api/articles" "/api/users")
  for ep in "${endpoints[@]}"; do
    printf "  %-30s" "  ${ep}..."
    local response
    response=$(curl -s --max-time 5 -w "%{http_code}" -o /dev/null "${api_url}${ep}" 2>/dev/null || echo "000")
    if [[ "$response" == "200" || "$response" == "201" ]]; then
      printf "${GREEN}${response}${RESET}\n"
    elif [[ "$response" == "000" ]]; then
      printf "${RED}NO RESPONSE${RESET}\n"
    else
      printf "${YELLOW}${response}${RESET}\n"
    fi
  done
  
  # Check frontend
  printf "  %-30s" "Frontend (port 3000)..."
  if curl -s --max-time 5 "http://localhost:3000" >/dev/null 2>&1; then
    printf "${GREEN}OK${RESET}\n"
  else
    printf "${RED}FAIL${RESET}\n"
  fi
  
  # Check docs if running
  printf "  %-30s" "Docs (port 5173)..."
  if curl -s --max-time 5 "http://localhost:5173" >/dev/null 2>&1; then
    printf "${GREEN}OK${RESET}\n"
  else
    printf "${YELLOW}NOT RUNNING${RESET}\n"
  fi
  
  echo
}

# ==================== Health Check Dashboard ====================
action_health_dashboard() {
  clear
  echo
  printf "  ${BOLD}${CYAN}╔═══════════════════════════════════════════════════════╗${RESET}\n"
  printf "  ${BOLD}${CYAN}║${RESET}           ${BOLD}$MSG_DASHBOARD_TITLE${RESET}                    ${BOLD}${CYAN}║${RESET}\n"
  printf "  ${BOLD}${CYAN}╚═══════════════════════════════════════════════════════╝${RESET}\n"
  echo
  
  local api_port="3002"
  local frontend_port="3000"
  local db_port="5432"
  
  # Function to check container status
  check_container() {
    local name_pattern="$1"
    local container_id
    container_id=$(podman ps -q --filter "name=${name_pattern}" 2>/dev/null | head -1)
    if [[ -n "$container_id" ]]; then
      echo "running"
    else
      container_id=$(podman ps -aq --filter "name=${name_pattern}" 2>/dev/null | head -1)
      if [[ -n "$container_id" ]]; then
        echo "stopped"
      else
        echo "not_found"
      fi
    fi
  }
  
  # Function to check HTTP endpoint
  check_http() {
    local url="$1"
    local timeout="${2:-5}"
    local response
    response=$(curl -s --max-time "$timeout" -w "%{http_code}" -o /dev/null "$url" 2>/dev/null || echo "000")
    echo "$response"
  }
  
  # Function to print status
  print_status() {
    local label="$1"
    local status="$2"
    local extra="$3"
    printf "  ${BOLD}%-20s${RESET}" "$label"
    case "$status" in
      "ok"|"running"|"200"|"201"|"204"|"301"|"302")
        printf "${GREEN}● $MSG_STATUS_OK${RESET}"
        ;;
      "stopped")
        printf "${YELLOW}○ $MSG_STATUS_STOPPED${RESET}"
        ;;
      "000"|"not_found"|"fail")
        printf "${RED}✗ $MSG_STATUS_FAIL${RESET}"
        ;;
      *)
        printf "${YELLOW}? ${status}${RESET}"
        ;;
    esac
    [[ -n "$extra" ]] && printf " ${CYAN}($extra)${RESET}"
    echo
  }
  
  printf "  ${BOLD}${SECTION_STATUS}${RESET}\n"
  printf "  ${CYAN}───────────────────────────────────────────────────────${RESET}\n"
  
  # Check containers
  printf "\n  ${BOLD}CONTAINERS${RESET}\n"
  
  printf "  %-20s %s\n" "" "$MSG_CHECKING"
  
  # Backend container
  local backend_status
  backend_status=$(check_container "backend\|api\|rails\|node\|python\|java")
  print_status "$MSG_SERVICE_BACKEND" "$backend_status" "container"
  
  # Frontend container
  local frontend_status
  frontend_status=$(check_container "frontend\|react\|angular\|web")
  print_status "$MSG_SERVICE_FRONTEND" "$frontend_status" "container"
  
  # Database container
  local db_status
  db_status=$(check_container "db\|postgres\|mysql\|mongo\|database")
  print_status "$MSG_SERVICE_DB" "$db_status" "container"
  
  # Check HTTP endpoints
  printf "\n  ${BOLD}HTTP ENDPOINTS${RESET}\n"
  
  # Backend API
  local api_http
  api_http=$(check_http "http://localhost:${api_port}/api/articles")
  print_status "Backend API" "$api_http" "port ${api_port}"
  
  # Frontend
  local frontend_http
  frontend_http=$(check_http "http://localhost:${frontend_port}")
  print_status "Frontend" "$frontend_http" "port ${frontend_port}"
  
  # Database connection (via backend health or direct)
  printf "  ${BOLD}%-20s${RESET}" "Database"
  if [[ "$db_status" == "running" ]]; then
    # Try to check if DB is accepting connections
    if podman exec $(podman ps -q --filter "name=db\|postgres" | head -1) pg_isready -U postgres >/dev/null 2>&1; then
      printf "${GREEN}● $MSG_STATUS_OK${RESET} ${CYAN}(port ${db_port})${RESET}\n"
    else
      printf "${GREEN}● $MSG_STATUS_RUNNING${RESET} ${CYAN}(port ${db_port})${RESET}\n"
    fi
  else
    printf "${RED}✗ $MSG_STATUS_FAIL${RESET}\n"
  fi
  
  # API Endpoints detail
  printf "\n  ${BOLD}API ENDPOINTS${RESET}\n"
  local endpoints=("/api/articles" "/api/users" "/api/auth/sign_in")
  for ep in "${endpoints[@]}"; do
    local ep_status
    ep_status=$(check_http "http://localhost:${api_port}${ep}")
    print_status "  ${ep}" "$ep_status" ""
  done
  
  # Summary
  echo
  printf "  ${CYAN}───────────────────────────────────────────────────────${RESET}\n"
  
  local all_ok=true
  [[ "$backend_status" != "running" ]] && all_ok=false
  [[ "$frontend_status" != "running" ]] && all_ok=false
  [[ "$db_status" != "running" ]] && all_ok=false
  [[ "$api_http" == "000" ]] && all_ok=false
  
  if $all_ok; then
    printf "  ${GREEN}${BOLD}✓ All services are running!${RESET}\n"
  else
    printf "  ${YELLOW}${BOLD}⚠ Some services need attention${RESET}\n"
    echo
    printf "  ${CYAN}Tip:${RESET} Run ${GREEN}[1]${RESET} Full Start or ${CYAN}[2]${RESET} Start Stack\n"
  fi
  echo
}

# ==================== Seed Database ====================
action_seed_db() {
  echo
  printf "  ${BOLD}$MSG_SEED_DB_TITLE${RESET}\n"
  printf "  ${CYAN}───────────────────────────────────────────────────────${RESET}\n"
  echo
  
  read -rp "$(printf "${BOLD}$MSG_SEED_DB_CONFIRM${RESET} ")" confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log "Seed cancelled."
    return 0
  fi
  
  set_target_dir || return 1
  
  log "Seeding database with test data..."
  
  # Detect technology and run appropriate seed command
  case "$CURRENT_TECH_KEY" in
    ruby)
      # Rails seed
      local backend_container
      backend_container=$(podman ps -q --filter "name=backend\|api\|rails" | head -1)
      if [[ -n "$backend_container" ]]; then
        log "Running Rails db:seed..."
        podman exec "$backend_container" bundle exec rails db:seed 2>&1 || {
          err "$MSG_SEED_DB_FAIL"
          return 1
        }
      else
        err "Backend container not found. Start the stack first."
        return 1
      fi
      ;;
    node)
      # Node.js seed (using npm run seed or similar)
      local backend_container
      backend_container=$(podman ps -q --filter "name=backend\|api\|node" | head -1)
      if [[ -n "$backend_container" ]]; then
        log "Running npm seed..."
        podman exec "$backend_container" npm run seed 2>&1 || \
        podman exec "$backend_container" npx prisma db seed 2>&1 || {
          # Fallback: try to run seed SQL directly
          log "Trying direct SQL seed..."
          seed_db_sql
        }
      else
        err "Backend container not found. Start the stack first."
        return 1
      fi
      ;;
    python)
      # Python/Django seed
      local backend_container
      backend_container=$(podman ps -q --filter "name=backend\|api\|python\|django" | head -1)
      if [[ -n "$backend_container" ]]; then
        log "Running Python seed..."
        podman exec "$backend_container" python manage.py loaddata seed_data.json 2>&1 || \
        podman exec "$backend_container" python seed.py 2>&1 || {
          log "Trying direct SQL seed..."
          seed_db_sql
        }
      else
        err "Backend container not found. Start the stack first."
        return 1
      fi
      ;;
    java)
      # Java/Spring seed - usually via SQL or Flyway
      log "Running SQL seed for Java backend..."
      seed_db_sql
      ;;
    *)
      log "Running generic SQL seed..."
      seed_db_sql
      ;;
  esac
  
  ok "$MSG_SEED_DB_DONE"
}

# Helper function to seed DB via SQL
seed_db_sql() {
  local db_container
  db_container=$(podman ps -q --filter "name=db\|postgres\|mysql" | head -1)
  
  if [[ -z "$db_container" ]]; then
    err "Database container not found."
    return 1
  fi
  
  # Create sample seed data
  local seed_sql="
-- Sports Hub Test Data
-- Generated: $(date)

-- Sample Categories
INSERT INTO categories (name, created_at, updated_at) VALUES 
  ('Football', NOW(), NOW()),
  ('Basketball', NOW(), NOW()),
  ('Tennis', NOW(), NOW()),
  ('Hockey', NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Sample Articles
INSERT INTO articles (title, content, category_id, created_at, updated_at) VALUES 
  ('Champions League Final Preview', 'The biggest match of the year is approaching...', 1, NOW(), NOW()),
  ('NBA Playoffs Update', 'The playoff race is heating up...', 2, NOW(), NOW()),
  ('Wimbledon 2024 Preview', 'The grass court season begins...', 3, NOW(), NOW()),
  ('Stanley Cup Finals', 'Hockey''s ultimate prize awaits...', 4, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Sample Users (for testing)
INSERT INTO users (email, name, created_at, updated_at) VALUES 
  ('admin@sportshub.test', 'Admin User', NOW(), NOW()),
  ('editor@sportshub.test', 'Editor User', NOW(), NOW()),
  ('reader@sportshub.test', 'Reader User', NOW(), NOW())
ON CONFLICT DO NOTHING;
"
  
  log "Inserting test data into database..."
  echo "$seed_sql" | podman exec -i "$db_container" psql -U postgres -d postgres 2>&1 || {
    warn "Some seed data may have failed (duplicates are OK)"
  }
}

# ==================== Reset Database ====================
action_reset_db() {
  echo
  warn "$MSG_RESET_DB_WARN"
  echo
  
  read -rp "$(printf "${BOLD}$MSG_RESET_DB_CONFIRM${RESET} ")" confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log "Reset cancelled."
    return 0
  fi
  
  set_target_dir || return 1
  
  log "Stopping containers..."
  (cd "$TARGET_DIR" && $CMD down -v 2>/dev/null) || true
  
  log "Removing database volumes..."
  podman volume ls -q | grep -E "(db|postgres|mysql|mongo)" | xargs -r podman volume rm -f 2>/dev/null || true
  
  log "Starting fresh..."
  (cd "$TARGET_DIR" && $CMD up -d --build) || {
    err "Failed to restart containers"
    return 1
  }
  
  ok "$MSG_RESET_DB_DONE"
}

# ==================== Export .env for Mobile ====================
action_export_env() {
  local api_port="3002"
  local output_dir="$HOME/Desktop"
  local output_file="$output_dir/sportshub_mobile.env"
  
  # Create .env content for mobile developers
  cat > "$output_file" << EOF
# Sports Hub - Mobile Development Environment
# Generated: $(date)
# Technology: $CURRENT_TECH

# API Configuration
API_BASE_URL=http://localhost:${api_port}
API_VERSION=v1

# Endpoints
ENDPOINT_ARTICLES=/api/articles
ENDPOINT_USERS=/api/users
ENDPOINT_AUTH=/api/auth/sign_in
ENDPOINT_REGISTER=/users/registrations

# For Android Emulator use:
# API_BASE_URL=http://10.0.2.2:${api_port}

# For iOS Simulator use:
# API_BASE_URL=http://localhost:${api_port}

# For Physical Device (replace with your machine's IP):
# API_BASE_URL=http://YOUR_LOCAL_IP:${api_port}

# Example: Get your local IP with:
# macOS: ipconfig getifaddr en0
# Linux: hostname -I | awk '{print \$1}'
EOF

  ok "$MSG_ENV_EXPORTED ${BOLD}$output_file${RESET}"
  echo
  printf "  ${CYAN}Tip:${RESET} Copy this file to your mobile project\n"
  echo
}

# ==================== Help / Quick Start ====================
action_help() {
  clear; print_banner
  echo
  printf "  ${BOLD}Quick Start Guide${RESET}\n"
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "  ${BOLD}For Mobile Developers:${RESET}\n"
  printf "    1. Press ${GREEN}[1]${RESET} to start the full stack\n"
  printf "    2. Wait for containers to start (~2-3 min first time)\n"
  printf "    3. API will be available at ${GREEN}http://localhost:3002${RESET}\n"
  printf "    4. Press ${CYAN}[E]${RESET} to export .env for your mobile project\n"
  echo
  printf "  ${BOLD}Common Tasks:${RESET}\n"
  printf "    ${GREEN}[1]${RESET}  Full Start    - Clone repos, build & run everything\n"
  printf "    ${CYAN}[S]${RESET}  Stack         - Start/stop/rebuild containers\n"
  printf "    ${CYAN}[A]${RESET}  API Info      - View endpoints and examples\n"
  printf "    ${CYAN}[H]${RESET}  Health Check  - Verify API is responding\n"
  printf "    ${CYAN}[X]${RESET}  Tools         - Logs, Podman management\n"
  echo
  printf "  ${BOLD}Troubleshooting:${RESET}\n"
  printf "    - ${YELLOW}422 on registration?${RESET} Check password requirements\n"
  printf "    - ${YELLOW}API not responding?${RESET} Run ${CYAN}[H]${RESET} to check health\n"
  printf "    - ${YELLOW}Containers failing?${RESET} Try ${CYAN}[S]${RESET} -> ${CYAN}[3]${RESET} Rebuild\n"
  printf "    - ${YELLOW}Complete reset?${RESET} Use ${CYAN}[X]${RESET} -> ${RED}[4]${RESET} Cleanup Podman\n"
  echo
  printf "  ${BOLD}Keyboard Shortcuts:${RESET}\n"
  printf "    ${CYAN}[T]${RESET} Change backend    ${CYAN}[F]${RESET} Change frontend\n"
  printf "    ${CYAN}[M]${RESET} Change language   ${RED}[Q]${RESET} Quit\n"
  echo
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
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

# Main menu - new clean structure
print_menu(){
  echo
  printf "  ${BOLD}${TECH_BANNER_TITLE}:${RESET} ${GREEN}%s${RESET}    ${BOLD}${FRONTEND_BANNER_TITLE}:${RESET} ${GREEN}%s${RESET}\n" "$CURRENT_TECH" "$CURRENT_FRONTEND_NAME"
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  # Section: LAUNCH
  printf "  ${BOLD}${SECTION_LAUNCH}${RESET}\n"
  printf "    ${GREEN}[1]${RESET}  %s\n" "$MENU_1_FULL_START"
  printf "    ${CYAN}[2]${RESET}  %s\n" "$MENU_2_START"
  printf "    ${CYAN}[3]${RESET}  %s\n" "$MENU_3_STOP"
  echo
  # Section: STATUS & LOGS
  printf "  ${BOLD}${SECTION_STATUS}${RESET}\n"
  printf "    ${CYAN}[4]${RESET}  %s\n" "$MENU_4_STATUS"
  printf "    ${GREEN}[5]${RESET}  %s\n" "$MENU_HEALTH_DASHBOARD"
  printf "    ${CYAN}[6]${RESET}  %s\n" "$MENU_5_LOGS"
  printf "    ${CYAN}[7]${RESET}  %s\n" "$MENU_6_OPEN"
  echo
  # Section: DOCUMENTATION
  printf "  ${BOLD}${SECTION_DOCS}${RESET}\n"
  printf "    ${CYAN}[8]${RESET}  %s\n" "$MENU_7_API"
  printf "    ${CYAN}[9]${RESET}  %s\n" "$MENU_8_DOCS"
  echo
  # Section: SETTINGS & ADVANCED (submenus)
  printf "  ${BOLD}${SECTION_SETTINGS} / ${SECTION_ADVANCED}${RESET}\n"
  printf "    ${YELLOW}[S]${RESET}  %s  ${CYAN}→${RESET}\n" "$MENU_9_SETTINGS"
  printf "    ${YELLOW}[0]${RESET}  %s  ${CYAN}→${RESET}\n" "$MENU_0_ADVANCED"
  echo
  printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  printf "    ${CYAN}[?]${RESET}  %s\n" "$MENU_HELP"
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

# Settings submenu
menu_settings(){
  while true; do
    clear; print_banner
    echo
    printf "  ${BOLD}$MENU_SETTINGS_TITLE${RESET}\n"
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    echo
    printf "    ${CYAN}[1]${RESET}  %s\n" "$MENU_SET_TECH"
    printf "    ${CYAN}[2]${RESET}  %s\n" "$MENU_SET_FRONTEND"
    printf "    ${CYAN}[3]${RESET}  %s\n" "$MENU_SET_LANG"
    echo
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    printf "    ${CYAN}[0]${RESET}  %s\n" "$MENU_BACK"
    echo
    read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
    case "$c" in
      1) choose_technology ;;
      2) choose_frontend ;;
      3) prompt_for_language ;;
      0|q|Q) return ;;
      *) warn "$WARN_UNKNOWN_CHOICE"; pause ;;
    esac
  done
}

# Advanced submenu
menu_advanced(){
  while true; do
    clear; print_banner
    echo
    printf "  ${BOLD}$MENU_ADVANCED_TITLE${RESET}\n"
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    echo
    printf "    ${CYAN}[1]${RESET}  %s\n" "$MENU_ADV_BUILD"
    printf "    ${CYAN}[2]${RESET}  %s\n" "$MENU_ADV_PULL"
    printf "    ${CYAN}[3]${RESET}  %s\n" "$MENU_ADV_CLONE"
    printf "    ${CYAN}[4]${RESET}  %s\n" "$MENU_ADV_ENSURE"
    printf "    ${CYAN}[5]${RESET}  %s\n" "$MENU_ADV_SAVE_LOGS"
    printf "    ${CYAN}[6]${RESET}  %s\n" "$MENU_ADV_EXPORT_ENV"
    echo
    printf "    ${YELLOW}[7]${RESET}  %s\n" "$MENU_ADV_SEED_DB"
    printf "    ${RED}[8]${RESET}  %s\n" "$MENU_ADV_RESET_DB"
    printf "    ${RED}[9]${RESET}  %s\n" "$MENU_ADV_CLEANUP"
    echo
    printf "  ${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
    printf "    ${CYAN}[0]${RESET}  %s\n" "$MENU_BACK"
    echo
    read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
    case "$c" in
      1) run_action action_build ;;
      2) run_action action_pull ;;
      3) run_action action_clone_update ;;
      4) run_action action_ensure_all ;;
      5) action_export_logs_as_json; pause ;;
      6) action_export_env; pause ;;
      7) action_seed_db; pause ;;
      8) action_reset_db; pause ;;
      9) action_cleanup_podman; pause ;;
      0|q|Q) return ;;
      *) warn "$WARN_UNKNOWN_CHOICE"; pause ;;
    esac
  done
}

# ==================== Entry Point ====================
# Check if this is first run
IS_FIRST_RUN="false"
if [ ! -f "$TECH_FILE" ] && [ -z "$CLI_TECH" ]; then
  IS_FIRST_RUN="true"
fi

show_welcome_screen "$IS_FIRST_RUN"
prompt_for_language

# Use CLI args if provided, otherwise read from config
if [[ -n "$CLI_TECH" ]]; then
  CURRENT_TECH_KEY="$CLI_TECH"
else
  CURRENT_TECH_KEY="$(cat "$TECH_FILE" 2>/dev/null || true)"
fi

if [ -z "$CURRENT_TECH_KEY" ]; then
  clear; print_banner
  echo
  printf "${BOLD}${GREEN}Step 2 of 3: Choose Backend Technology${RESET}\n"
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "Select the programming language for your backend.\n"
  printf "${CYAN}Tip:${RESET} If unsure, Python or Node.js are great starting points!\n"
  echo
  pause
  
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

# Show frontend selection hint on first run
if [[ "$IS_FIRST_RUN" == "true" ]] && [ -z "$CURRENT_FRONTEND_NAME" ]; then
  clear; print_banner
  echo
  printf "${BOLD}${GREEN}Step 3 of 3: Choose Frontend Framework${RESET}\n"
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "Select the frontend framework for your application.\n"
  printf "${CYAN}Tip:${RESET} React is more popular, Angular is more structured.\n"
  echo
  pause
  choose_frontend
  CURRENT_FRONTEND_NAME="$(cat "$FRONTEND_FILE" 2>/dev/null || true)"
fi

apply_tech_selection "$CURRENT_TECH_KEY" "$CURRENT_FRONTEND_NAME"

CMD=$(resolve_compose_cmd)

if [[ "${ENABLE_TEE_LOG:-1}" == "1" ]]; then
  exec > >(tee -a "$LOG_FILE") 2>&1
  log "$MSG_LOGS_SAVED ${BOLD}$LOG_FILE${RESET}"
fi

# Show quick start hint for first-time users
if [[ "$IS_FIRST_RUN" == "true" ]]; then
  clear; print_banner
  echo
  printf "${BOLD}${GREEN}Setup Complete!${RESET}\n"
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  printf "You've selected:\n"
  printf "  ${BOLD}Backend:${RESET}  ${GREEN}$CURRENT_TECH${RESET}\n"
  printf "  ${BOLD}Frontend:${RESET} ${GREEN}$CURRENT_FRONTEND_NAME${RESET}\n"
  echo
  printf "${BOLD}${CYAN}Quick Start:${RESET}\n"
  printf "  Press ${GREEN}[1]${RESET} for Full Start - this will:\n"
  printf "    • Install Podman (container engine) if needed\n"
  printf "    • Download your project code\n"
  printf "    • Start the application\n"
  printf "    • Open it in your browser\n"
  echo
  printf "  ${CYAN}Note:${RESET} First run may take 5-10 minutes to download everything.\n"
  echo
  printf "${CYAN}═══════════════════════════════════════════════════════${RESET}\n"
  echo
  pause
fi

clear; print_banner

while true; do
  print_menu
  read -rp "$(printf "${BOLD}$PROMPT_CHOICE${RESET} ")" c
  case "$c" in
    # LAUNCH section
    1) action_full_run ;;
    2) run_action action_up ;;
    3) run_action action_down ;;
    # STATUS & LOGS section
    4) run_action action_status ;;
    5) action_health_dashboard; pause ;;
    6) action_logs; pause ;;
    7) action_open; pause ;;
    # DOCUMENTATION section
    8) action_api_info; pause ;;
    9) action_run_docs ;;
    # SETTINGS submenu
    S|s) menu_settings ;;
    # ADVANCED submenu
    0) menu_advanced ;;
    # Help & Quit
    \?) action_help; pause ;;
    q|Q) echo "Bye!"; exit 0 ;;
    *)   warn "$WARN_UNKNOWN_CHOICE"; pause ;;
  esac
  clear; print_banner
done
