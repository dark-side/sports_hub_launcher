# Sports Hub Setup CLI

## Overview
Sports Hub Setup CLI is a unified automation tool designed to bootstrap and manage multiple polyglot back-end and front-end projects under the `dark-side/sports_hub` organization.  
It automates environment setup, repository cloning, container management, and documentation hosting — all from a single, interactive terminal menu.

The tool was created to solve a long-standing issue: every Sports Hub subproject (Java, Python, Go, etc.) required its own installation steps, dependency setup, and environment configuration.  
Now, everything is consolidated into one universal script — `setup.sh` — which handles installation, cloning, building, and launching across all supported stacks.

### Interface Design
The CLI features a clean, professional interface with:
- Structured menu sections (LAUNCH, STATUS & LOGS, DOCUMENTATION, SETTINGS/ADVANCED)
- Numeric keys [1-9, 0, S] for easy one-hand navigation
- Color-coded options (green for primary actions, yellow for settings, red for destructive)
- Bilingual support (English/Ukrainian)
- Health Check Dashboard for real-time service monitoring
- Consistent formatting across all menus and submenus

---

## Key Features and Problems Solved

- **Unified Setup Process:** Replaces different setup processes for each language with a one-click setup and container orchestration.
- **Automatic Dependency Installation:** Verifies and automatically installs required dependencies such as Git, Podman, and Compose.
- **Conflict Resolution:** Includes built-in recovery for stuck Podman machines and resolves common proxy issues.
- **Automated Repository Management:** Automatically clones all required backend and frontend repositories and applies necessary patches.
- **Environment Configuration:** Automatically copies `.env.example` to `.env` (when available) to ensure a working default configuration.
- **Clear Interactive CLI:** Simplifies multi-stack management with a dynamic menu for backend and frontend technology selection.
- **Centralized Documentation:** Builds and serves a local documentation container via Podman for easy access.

---

## Supported Technologies

### Back-End Stacks
- Java
- Python
- Ruby
- Go
- C++
- PHP
- Node.js
- .NET
- Rust

### Front-End Stacks
- React
- Angular

---

## Documentation
Local documentation container is based on `api_docs_genai_playground`.

---

## Dependencies
This script is designed for use on:
- macOS, Linux, or Windows (via Git Bash)
- Podman (used instead of Docker)
- Podman Compose or podman-compose
- Git
- curl (for service health checks)

The script automatically checks for and attempts to install missing dependencies where possible.

---

## Setup and Usage

### 1. Clone the Repository
You can clone any of the skeleton projects or simply place the `setup.sh` script in a central folder that will contain all Sports Hub repositories.

```bash
git clone https://github.com/dark-side/sports_hub_java_skeleton.git
cd sports_hub_java_skeleton
chmod +x setup.sh
./setup.sh
```

### 2. Run the Setup Script
After making the script executable, run it:
```bash
./setup.sh
```

#### First-Time Setup

On first run, you will be guided through:

1. **Language Selection** - Choose between English or Українська
2. **Backend Technology** - Select from Java, Python, Ruby, Go, C++, PHP, Node.js, .NET, or Rust
3. **Frontend Framework** - Choose React or Angular

Your selections are stored for future sessions in:
```
~/.config/sportshub-setup/
```

You can change these settings anytime using **[S] Settings** from the main menu.

---

## Interactive Menu Options

### Main Menu Structure

The main menu is organized into logical sections with numeric keys for easy navigation:

#### LAUNCH (ЗАПУСК)
| Option | Description |
|:--|:--|
| **[1] Full Start** | Performs full environment validation, clones/updates repositories, starts containers, waits for service availability, and opens the app in your browser. |
| **[2] Start Stack** | Starts all containers in detached mode (`podman compose up -d`). |
| **[3] Stop Stack** | Stops and removes all running containers for the current backend. |

#### STATUS & LOGS (СТАТУС І ЛОГИ)
| Option | Description |
|:--|:--|
| **[4] Container Status** | Shows the list of currently running containers. |
| **[5] Health Dashboard** | Displays real-time status of all services (containers, HTTP endpoints, API health, database connection). |
| **[6] View Logs** | Opens live logs from running containers. |
| **[7] Open in Browser** | Opens the running application (default: [http://localhost:3000](http://localhost:3000)). |

#### DOCUMENTATION (ДОКУМЕНТАЦІЯ)
| Option | Description |
|:--|:--|
| **[8] API Info** | Displays comprehensive API information including endpoints, URLs, and example curl commands. |
| **[9] Documentation** | Builds and launches a local documentation container (`api_docs_genai_playground`) and opens it at [http://localhost:5173](http://localhost:5173). |

#### SETTINGS / ADVANCED (НАЛАШТУВАННЯ / ДОДАТКОВО)
| Option | Description |
|:--|:--|
| **[S] Settings** | Opens Settings submenu (technology, frontend, language). |
| **[0] Advanced** | Opens Advanced Tools submenu (rebuild, seed DB, cleanup). |

#### OTHER
| Option | Description |
|:--|:--|
| **[?] Help** | Shows quick start guide and troubleshooting tips. |
| **[Q] Quit** | Exits the CLI. |

---

### Settings Submenu [S]

| Option | Description |
|:--|:--|
| **[1] Change Technology** | Switches between backend technologies (e.g., Java → Go). Automatically updates repo URLs and paths. |
| **[2] Change Frontend** | Switches between React and Angular for the selected backend. |
| **[3] Change Language** | Switches interface language between English and Ukrainian. |
| **[0] Back** | Returns to the main menu. |

---

### Advanced Tools Submenu [0]

| Option | Description |
|:--|:--|
| **[1] Rebuild Containers** | Rebuilds images for backend and frontend services. |
| **[2] Pull Images** | Pulls the latest container images defined in your compose file. |
| **[3] Clone/Update Repos** | Clones or updates backend, frontend, and optional docs repositories. |
| **[4] Check Podman** | Ensures Podman and Compose are installed and configured. |
| **[5] Save Logs** | Exports container logs to a JSON file in the `app_logs/` directory. |
| **[6] Export .env for Mobile** | Generates environment file for mobile developers. |
| **[7] Seed Database** | Populates database with test data (categories, articles, users). |
| **[8] Reset Database** | ⚠️ Removes all data and recreates database from scratch. |
| **[9] Cleanup Podman** | ⚠️ Removes all containers, images, and optionally uninstalls Podman. |
| **[0] Back** | Returns to the main menu. |

---

### Health Check Dashboard

The Health Dashboard (`[5]` from main menu) provides a comprehensive view of all services:

```
╬═══════════════════════════════════════════════════════╗
║           SERVICE STATUS                              ║
╚═══════════════════════════════════════════════════════╝

CONTAINERS
  Backend             ● OK (container)
  Frontend            ● OK (container)
  Database            ● OK (container)

HTTP ENDPOINTS
  Backend API         ● OK (port 3002)
  Frontend            ● OK (port 3000)
  Database            ● OK (port 5432)

API ENDPOINTS
  /api/articles       ● 200
  /api/users          ● 200
  /api/auth/sign_in   ● 200

───────────────────────────────────────────────────────
✓ All services are running!
```

---

## Quick Start Examples

### Example 1: First-Time Full Setup
```bash
./setup.sh
# 1. Select language (1 for English, 2 for Українська)
# 2. Choose backend (e.g., 2 for Python)
# 3. Choose frontend (e.g., 1 for React)
# 4. Press [1] for Full Start
```

### Example 2: Check Service Health
```bash
# From main menu:
# Press [5] to open Health Dashboard
# View status of all containers, HTTP endpoints, and API health
```

### Example 3: Switch Technology Stack
```bash
# From main menu:
# Press [S] for Settings menu
# Press [1] to change backend technology
# Press [2] to change frontend framework
# Press [2] from main menu to start the new stack
```

### Example 4: Seed Database with Test Data
```bash
# From main menu:
# Press [0] for Advanced Tools
# Press [7] to seed database
# Confirm with 'y' to populate test categories, articles, and users
```

### Example 5: View API Information
```bash
# From main menu:
# Press [8] to see all API endpoints, URLs, and example curl commands
```

### Example 6: Export Logs for Debugging
```bash
# From main menu:
# Press [0] for Advanced Tools
# Press [5] to save logs as JSON
# Logs will be saved to app_logs/ directory
```

---

## Command-Line Options

The script supports several command-line options for automation and troubleshooting:

```bash
./setup.sh --help              # Show help message
./setup.sh --version           # Show version information
./setup.sh --tech=python       # Pre-select Python backend
./setup.sh --frontend=Angular  # Pre-select Angular frontend
./setup.sh --no-tee            # Disable tee logging (fixes some terminal issues)
```

### Environment Variables

```bash
ENABLE_TEE_LOG=0 ./setup.sh    # Disable tee logging
OPEN_BROWSER=0 ./setup.sh      # Disable auto-opening browser
WAIT_TIMEOUT=300 ./setup.sh    # Set custom timeout (default: 180s)
```

---

## Troubleshooting

### Podman Issues

If you experience issues with Podman (e.g., errors about Podman machine, proxy conflicts, or connection problems), follow these steps:

#### Complete Podman Reinstallation

1. **Uninstall Podman completely:**
   ```bash
   brew uninstall podman-desktop
   brew uninstall podman
   ```

2. **Restart your machine** to ensure all Podman processes are terminated.

3. **Run the setup script** which will install everything from scratch:
   ```bash
   ./setup.sh
   ```
   The script will automatically detect missing dependencies and install Podman properly.

#### Manual Podman Machine Initialization

If you still experience issues after reinstallation, manually initialize the Podman machine:

```bash
podman machine init
podman machine start
./setup.sh
```

#### Notes
- The setup script works best when run from a clean state without manual Podman installations
- Always ensure both `podman-desktop` and `podman` are uninstalled before reinstalling
- For more information on uninstalling Podman Desktop, see: [Podman Desktop Uninstallation Guide](https://podman-desktop.io/docs/uninstall)

---
