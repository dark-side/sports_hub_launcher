# Sports Hub Setup CLI

## Overview
Sports Hub Setup CLI is a unified automation tool designed to bootstrap and manage multiple polyglot back-end and front-end projects under the `dark-side/sports_hub` organization.  
It automates environment setup, repository cloning, container management, and documentation hosting — all from a single, interactive terminal menu.

The tool was created to solve a long-standing issue: every Sports Hub subproject (Java, Python, Go, etc.) required its own installation steps, dependency setup, and environment configuration.  
Now, everything is consolidated into one universal script — `setup.sh` — which handles installation, cloning, building, and launching across all supported stacks.

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
```




At startup, you will be prompted to:

- Choose a language (English or Ukrainian)
- Choose a backend technology (Java, Rust, etc.)
- Choose a frontend (React or Angular)

Your selections will be stored for future sessions in: 
```
~/.config/sportshub-setup/
```

---

## Interactive Menu Options

| Option | Description |
|:--|:--|
| **[1] Full Run (install → clone/update → up)** | Performs full environment validation, clones/updates repositories, starts containers, waits for service availability, and opens the app in your browser. |
| **[2] Check/Install Podman** | Ensures Podman and Compose are installed and configured. Initializes and starts the Podman machine if needed. |
| **[3] Clone/Update Repositories** | Clones or updates backend, frontend, and optional docs repositories for the selected tech stack. |
| **[4] Start Stack (up)** | Starts all containers in detached mode (`podman compose up -d`). Includes automatic recovery from “proxy already running” issues. |
| **[5] Stop Stack (down)** | Stops and removes all running containers for the current backend. |
| **[6] Rebuild Services (build)** | Rebuilds images for backend and frontend services. |
| **[7] Pull Images** | Pulls the latest container images defined in your compose file. |
| **[8] Logs Menu** | Opens a sub-menu with options to follow logs live or export them to a JSON file. |
| **[L] Logs (last 200)** | Displays the last 200 lines of logs from your containers. |
| **[9] Status (ps)** | Shows the list of currently running containers. |
| **[T] Change Technology** | Switches between backend technologies (e.g., Java → Go). Automatically updates repo URLs and paths. |
| **[F] Change Frontend** | Switches between React and Angular for the selected backend. |
| **[D] Open Documentation** | Builds and launches a local documentation container (`api_docs_genai_playground`) and opens it at [http://localhost:5173](http://localhost:5173). |
| **[M] Change Language** | Switches interface language between English and Ukrainian. |
| **[0] Open in Browser** | Opens the running application (default: [http://localhost:3000](http://localhost:3000)). |
| **[q] Quit** | Exits the CLI. |

---
