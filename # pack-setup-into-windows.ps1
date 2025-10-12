# pack-setup-into-windows.ps1
param(
  [string]$AppName     = "Sports Hub Setup",
  [string]$BundleDir   = "SportsHubSetup-win",
  [string]$SetupScript = "setup.sh",
  [string]$IconIco     = "app.ico",
  [switch]$NoZip,
  [switch]$NoDesktopShortcut
)

$ErrorActionPreference = 'Stop'

# Clean up previous build
if (Test-Path $BundleDir) { Remove-Item -Recurse -Force $BundleDir }
$Res = Join-Path $BundleDir "Resources"
New-Item -ItemType Directory -Force -Path $BundleDir,$Res | Out-Null

# Check setup.sh existence
if (!(Test-Path $SetupScript)) {
  Write-Error "setup.sh not found in the current directory."
  exit 1
}
Copy-Item $SetupScript (Join-Path $Res "setup.sh") -Force

# Generate run_setup.ps1
@'
[CmdletBinding()]
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$Host.UI.RawUI.WindowTitle = "Sports Hub Setup"

function WInfo($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function WOk($m){   Write-Host "[OK] $m" -ForegroundColor Green }
function WWarn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function WErr($m){  Write-Host "[ERROR] $m" -ForegroundColor Red }
function CmdExists($n){ $null -ne (Get-Command $n -ErrorAction SilentlyContinue) }

$IsWin = $IsWindows
$IsMac = $IsMacOS
$IsNix = $IsLinux

WInfo "Detected OS: Windows=$IsWin macOS=$IsMac Linux=$IsNix"

# Log paths
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$BundleRoot = Split-Path -Parent $ScriptRoot

if ($IsWin) {
  $UserBase = $env:LOCALAPPDATA
  if (-not $UserBase) { $UserBase = [Environment]::GetFolderPath('LocalApplicationData') }
} elseif ($IsMac) {
  $UserBase = Join-Path $HOME "Library/Logs"
} else {
  $UserBase = Join-Path $HOME ".local/share"
}
$UserDir = Join-Path $UserBase "SportsHubSetup"
New-Item -ItemType Directory -Force -Path $UserDir | Out-Null

$AppLog  = Join-Path $ScriptRoot "setup-run.log"
$UserLog = Join-Path $UserDir   "setup-run.log"

function TeeLine([string]$line){
  $ts = [DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
  $formatted = "$ts $line"
  Add-Content -Path $AppLog -Value $formatted -ErrorAction SilentlyContinue
  Add-Content -Path $UserLog -Value $formatted -ErrorAction SilentlyContinue
}

# Toast notifications
$ToastAvailable = $false
if ($IsWin) {
  try {
    if (Get-Module -ListAvailable -Name BurntToast) {
      Import-Module BurntToast -ErrorAction SilentlyContinue
      $ToastAvailable = $true
    }
  } catch {}
}
function Toast($title,$msg,$success=$true){
  if (-not $ToastAvailable) { return }
  try {
    $AppIconIco = Join-Path $BundleRoot "app.ico"
    if (Test-Path $AppIconIco) {
      New-BurntToastNotification -Text $title, $msg -AppLogo $AppIconIco | Out-Null
    } else {
      New-BurntToastNotification -Text $title, $msg | Out-Null
    }
  } catch {}
}

# Spinner helper
$script:SpinnerIdx = 0
function With-Spinner($Label, [scriptblock]$Block) {
  $chars = "|/-\"
  $job = Start-Job -ScriptBlock $Block
  while ($job.State -eq 'Running') {
    $c = $chars[$script:SpinnerIdx % $chars.Length]
    Write-Host -NoNewline "`r$Label $c"
    Start-Sleep -Milliseconds 120
    $script:SpinnerIdx++
  }
  Receive-Job $job -Wait 2>$null 1>$null
  Write-Host "`r$Label Done    "
}

# Install via Winget if missing
function Install-PackageIfMissing($pkgName,$wingetId){
  if (CmdExists $pkgName) { return }
  if (-not (CmdExists winget)) { WErr "winget not found"; return }
  WInfo "Installing $pkgName..."
  With-Spinner "Installing $pkgName" {
    winget install -e --id $wingetId --accept-source-agreements --accept-package-agreements | Out-Null
  }
}

# Ensure Git Bash
function Ensure-Git {
  WInfo "Checking/Installing Git Bash..."
  if (CmdExists git -and CmdExists bash) { WOk "Git Bash found"; return }
  WInfo "Git Bash not found - installing Git for Windows..."
  Install-PackageIfMissing "git" "Git.Git"
  Start-Sleep 3
  $bashPath = "C:\Program Files\Git\bin\bash.exe"
  if (Test-Path $bashPath) {
    $env:Path += ";C:\Program Files\Git\bin"
    WOk "Git Bash installed at $bashPath"
  } else {
    WErr "bash not found after installation"
    throw "bash not found"
  }
}

# Ensure Podman
function Ensure-Podman {
  WInfo "Checking/Installing Podman..."
  if (CmdExists podman) { WOk "Podman CLI found"; return }

  WInfo "Installing Podman Desktop (GUI)..."
  Install-PackageIfMissing "podman" "RedHat.Podman-Desktop"

  Start-Sleep 5
  if (CmdExists podman) { WOk "Podman found after Desktop installation"; return }

  WWarn "CLI podman.exe not found - trying Containers.Podman (CLI-only)"
  Install-PackageIfMissing "podman" "containers.podman"
  Start-Sleep 5

  $exe = "$env:LOCALAPPDATA\Programs\RedHat\Podman Desktop\Podman Desktop.exe"
  if (Test-Path $exe) {
    WInfo "Launching Podman Desktop to initialize CLI..."
    Start-Process -FilePath $exe -ArgumentList "--hidden" -WindowStyle Hidden
    Start-Sleep -Seconds 20
    WInfo "Closing Podman Desktop after initialization"
    Get-Process "Podman Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
  }

  $src = "$env:LOCALAPPDATA\Programs\RedHat\Podman Desktop\resources\app.asar.unpacked\node_modules\@podman-desktop\podman\win32\podman.exe"
  $dst = "$env:LOCALAPPDATA\Programs\RedHat\Podman Desktop\resources\podman\podman.exe"
  if (Test-Path $src -and -not (Test-Path $dst)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    Copy-Item $src $dst -Force
    WOk "Podman CLI manually activated"
  }

  $cliPath = "$env:LOCALAPPDATA\Programs\RedHat\Podman Desktop\resources\podman"
  if (Test-Path (Join-Path $cliPath "podman.exe")) {
    $env:Path += ";$cliPath"
    WOk "Podman CLI added to PATH"
  } else {
    WErr "Podman still not found after activation"
    WWarn "Start Podman Desktop manually once and rerun the script"
    throw "podman missing"
  }
}

# Ensure Podman VM
function Ensure-PodmanMachine {
  if ($IsWin -or $IsMac) {
    WInfo "Checking Podman VM state..."
    try {
      podman info | Out-Null
      WOk "Podman VM already running and responsive."
      return
    } catch {
      WWarn "Podman VM not responding. Attempting to start..."
    }

    try {
      $machineExists = (podman machine list --format "{{.Name}}" | Select-String "podman-machine-default" -ErrorAction SilentlyContinue)
      if (-not $machineExists) {
        WInfo "No Podman machine found. Initializing..."
        podman machine init
      }

      WInfo "Starting Podman VM..."
      podman machine start

      WInfo "Waiting for VM to be ready..."
      $retries = 10
      $delay = 3
      for ($i = 0; $i -lt $retries; $i++) {
        try {
          podman info | Out-Null
          WOk "Podman VM started successfully."
          return
        } catch {
          Start-Sleep -Seconds $delay
        }
      }
      throw "Failed to connect to Podman VM after startup."

    } catch {
      WErr "Error while starting Podman VM."
      WErr $_.Exception.Message
      WWarn "Ensure virtualization (Hyper-V or WSL2) is enabled and rerun the script."
      throw
    }
  } else {
    WInfo "Podman machine not required on Linux."
  }
}

# Configure container host
function Set-ContainerHost {
  if ($IsWin) {
    $v = "npipe:////./pipe/podman"
    $env:DOCKER_HOST = $v
    $env:CONTAINER_HOST = $v
    WOk "DOCKER_HOST/CONTAINER_HOST set to $v"
    return
  }
}

# Workspace selection
function Choose-Workspace {
  if ($IsWin) {
    try {
      Add-Type -AssemblyName System.Windows.Forms | Out-Null
      $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
      $dlg.Description = "Select a folder for repository cloning"
      $dlg.ShowNewFolderButton = $true
      $res = $dlg.ShowDialog()
      if ($res -ne [System.Windows.Forms.DialogResult]::OK) {
        WWarn "No folder selected. Exiting."
        Read-Host "Press ENTER to close"; exit 0
      }
      return $dlg.SelectedPath
    } catch { WWarn "Forms UI unavailable, using default path" }
  }
  $def = Join-Path $env:USERPROFILE "SportsHubWorkspace"
  if (-not (Test-Path $def)) { New-Item -ItemType Directory -Force -Path $def | Out-Null }
  return $def
}

function To-Posix([string]$p){
  if($p -match '^[A-Za-z]:'){
    $d=$p.Substring(0,1).ToLower()
    return "/$d/" + $p.Substring(3).Replace('\','/')
  } else { return $p.Replace('\','/') }
}

# Main setup steps
$Steps = @(
  @{i=1;  title="Checking/Installing Git Bash"; fn={ Ensure-Git } }
  @{i=2;  title="Checking/Installing Podman";  fn={ Ensure-Podman } }
  @{i=3;  title="Starting Podman machine";     fn={ Ensure-PodmanMachine } }
  @{i=4;  title="Selecting workspace";         fn={ $script:WS = Choose-Workspace } }
)

$Total = $Steps.Count
$script:ExitCode = 0
try {
  foreach($s in $Steps){
    $pct = [int](($s.i / $Total) * 100)
    Write-Progress -Activity "Sports Hub Setup" -Status "$($s.title)" -PercentComplete $pct
    & $s.fn
  }
  Write-Progress -Activity "Sports Hub Setup" -Completed
  WOk "Completed successfully. You can now run setup.sh"
}
catch {
  Write-Progress -Activity "Sports Hub Setup" -Completed
  WErr $_.Exception.Message
  $script:ExitCode = 1
}
finally {
  WInfo "Logs: $AppLog , $UserLog"
  if ($IsWin) { Read-Host "Press ENTER to close" }
  exit $script:ExitCode
}
'@ | Set-Content -Encoding UTF8BOM (Join-Path $Res "run_setup.ps1")

# Create launch.cmd
@"
@echo off
setlocal
set SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Resources\run_setup.ps1"
endlocal
"@ | Set-Content -Encoding ASCII (Join-Path $BundleDir "launch.cmd")

# Create README
@"
$AppName (Windows)
==================
- Automatically installs Git Bash and Podman Desktop.
- Launches Podman Desktop in the background for CLI initialization.
- Sets PATH and runs setup.sh.
"@ | Set-Content -Encoding UTF8BOM (Join-Path $BundleDir "README.txt")

Write-Host "[OK] Windows bundle created: $BundleDir" -ForegroundColor Green
