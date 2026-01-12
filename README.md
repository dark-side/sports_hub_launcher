# Sports Hub Setup CLI

## Overview
Sports Hub Setup CLI is a unified automation tool designed to bootstrap and manage multiple polyglot back-end and front-end projects under the `dark-side/sports_hub` organization.  
It automates environment setup, repository cloning, container management, and documentation hosting — all from a single, interactive terminal menu.

The tool was created to solve a long-standing issue: every Sports Hub subproject (Java, Python, Go, etc.) required its own installation steps, dependency setup, and environment configuration.  
Now, everything is consolidated into one universal script — `setup.sh` — which handles installation, cloning, building, and launching across all supported stacks.

### Interface Design
The CLI features a clean, professional interface with:
- Structured menu sections (MAIN, RESOURCES, SETTINGS)
- Letter and number keys for intuitive navigation
- Color-coded options (green for primary actions, cyan for resources, yellow for settings)
- Bilingual support (English/Ukrainian)
- Health Check for real-time service monitoring
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

## Project Structure

After running the launcher, your directory structure will look like this:

```
sports_hub_launcher/          # Main launcher repository
├── setup.sh                  # Main setup script
├── clean-restart.sh          # Full cleanup script
├── quick-restart.sh          # Quick restart script
├── README.md
├── sports_hub_java_skeleton/      # Auto-cloned backend (example)
├── sports_hub_react_skeleton/     # Auto-cloned frontend (example)
└── api_docs_genai_playground/     # Auto-cloned docs (if available)
```

**Note:** The launcher automatically clones backend and frontend repositories into the same directory. You don't need to manage them manually.

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

### 1. Clone the Launcher Repository

The `setup.sh` script is located in the **launcher repository**, not in individual skeleton projects.

```bash
# Clone the launcher repository
git clone https://github.com/dark-side/sports_hub_launcher.git
cd sports_hub_launcher

# Make the script executable
chmod +x setup.sh

# Run the setup
./setup.sh
```

**Important:** The launcher will automatically clone the backend and frontend repositories you select. You don't need to clone them manually.

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

The launcher will then:
- ✅ Install Podman if needed
- ✅ Clone the selected backend repository (e.g., `sports_hub_java_skeleton`)
- ✅ Clone the selected frontend repository (e.g., `sports_hub_react_skeleton`)
- ✅ Set up and start all containers
- ✅ Open the application in your browser

You can change these settings anytime using **[S] Settings** from the main menu.

---

## Interactive Menu Options

### Main Menu Structure

The main menu is organized into three logical sections:

#### MAIN
| Option | Description |
|:--|:--|
| **[1] Full Start** | Performs full environment validation, clones/updates repositories, starts containers, waits for service availability, and opens the app in your browser. |
| **[S] Manage Stack** | Opens the Stack Management submenu with container operations. |
| **[X] Tools** | Opens the Tools submenu with logs and Podman utilities. |

#### RESOURCES
| Option | Description |
|:--|:--|
| **[A] API Info** | Displays comprehensive API information including endpoints, URLs, and example curl commands. |
| **[H] API Health Check** | Checks the health of all API endpoints and services. |
| **[D] Documentation** | Builds and launches a local documentation container (`api_docs_genai_playground`) and opens it at [http://localhost:5173](http://localhost:5173). |
| **[0] Open in browser** | Opens the running application (default: [http://localhost:3000](http://localhost:3000)). |

#### SETTINGS
| Option | Description |
|:--|:--|
| **[T] Change technology** | Switches between backend technologies (e.g., Java → Go). Automatically updates repo URLs and paths. |
| **[F] Change frontend** | Switches between React and Angular for the selected backend. |
| **[M] Change language** | Switches interface language between English and Ukrainian. |

#### EXIT
| Option | Description |
|:--|:--|
| **[Q] Quit** | Exits the CLI. |

---

### Stack Management Submenu [S]

| Option | Description |
|:--|:--|
| **[1] Start** | Starts all containers in detached mode (`podman compose up -d`). Includes automatic recovery from "proxy already running" issues. |
| **[2] Stop** | Stops and removes all running containers for the current backend. |
| **[3] Rebuild** | Rebuilds images for backend and frontend services. |
| **[4] Pull images** | Pulls the latest container images defined in your compose file. |
| **[5] Status** | Shows the list of currently running containers. |
| **[6] Clone/update repos** | Clones or updates backend, frontend, and optional docs repositories for the selected tech stack. |
| **[0] Back** | Returns to the main menu. |

---

### Tools Submenu [X]

#### LOGS
| Option | Description |
|:--|:--|
| **[1] View logs** | Opens a sub-menu with options to follow logs live or view recent logs. |
| **[2] Save logs** | Exports container logs to a JSON file in the `app_logs/` directory. |

#### PODMAN
| Option | Description |
|:--|:--|
| **[3] Check Podman** | Ensures Podman and Compose are installed and configured. Initializes and starts the Podman machine if needed. |
| **[4] Cleanup Podman** | Removes all containers, images, and optionally uninstalls Podman completely. Use with caution. |

| Option | Description |
|:--|:--|
| **[0] Back** | Returns to the main menu. |

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

### Example 2: Check API Health
```bash
# From main menu:
# Press [H] for API Health Check
# View status of backend API, endpoints, and database
```

### Example 3: Switch Technology Stack
```bash
# From main menu:
# Press [T] to change backend technology
# Press [F] to change frontend framework
# Press [S] then [6] to clone/update new repositories
# Press [S] then [1] to start the new stack
```

### Example 4: View API Information
```bash
# From main menu:
# Press [A] to see all API endpoints, URLs, and example curl commands
```

### Example 5: Export Logs for Debugging
```bash
# From main menu:
# Press [X] for Tools menu
# Press [2] to save logs as JSON
# Logs will be saved to app_logs/ directory
```

---

## Helper Scripts

The launcher includes helper scripts for common tasks:

### clean-restart.sh - Complete Cleanup
```bash
./clean-restart.sh
```
Performs a complete cleanup:
- Stops all Podman containers
- Removes all images and volumes
- Deletes Podman machine
- Cleans configuration directories
- Optionally uninstalls Podman
- Optionally restarts your Mac

### quick-restart.sh - Quick Restart
```bash
./quick-restart.sh
```
Quick restart without full cleanup:
- Stops Podman machine
- Removes Podman machine
- Automatically launches setup.sh

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

### Port Conflicts with Other Container Tools

If you see errors like `bind: address already in use`, you may have other container tools running:

#### Colima
```bash
# Check if Colima is running
colima status

# Stop Colima
colima stop

# Then restart setup.sh
./setup.sh
```

#### Docker Desktop
```bash
# Stop Docker Desktop from the menu bar
# Or use command line:
killall Docker

# Then restart setup.sh
./setup.sh
```

#### Rancher Desktop / Lima
```bash
# Check what's using the port
lsof -i :5432  # PostgreSQL
lsof -i :3000  # Frontend
lsof -i :3002  # Backend

# Stop the conflicting service
# Then restart setup.sh
./setup.sh
```

**Note:** Podman works best when other container tools (Docker, Colima, Rancher Desktop) are not running simultaneously.

---

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
