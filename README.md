# SignalRGB for Razer Fix

Eliminates the conflict between Razer Synapse/Chroma SDK and SignalRGB by running the Razer Chroma Sample App as a hidden background service at logon.

## Problem

After a Windows reinstall, the Chroma SDK fails to initialize properly because Task Scheduler references an old user SID that no longer exists. The Sample App crashes in a restart loop instead of initializing cleanly.

## Solution

This solution uses a native Windows Task Scheduler approach to properly execute the Sample App with the current user's credentials on every logon.

## Setup

### Step 1: Compile the Sample App

Download and compile the Razer Chroma Sample Application from:
https://github.com/RazerOfficial/CChromaEditor?tab=readme-ov-file#sample-project

Note the full path to your compiled RazerChromaSampleApplication.exe (e.g., C:\Visual Studio\Compiled\RazerChromaSampleApplication.exe)

### Step 2: Create the Launch Script

Save the following as LaunchAndHideChroma.ps1 in your PowerShell Scripts directory:

# LaunchAndHideChroma.ps1
# Launches the Razer Chroma Sample App and hides it from taskbar

Add-Type -Namespace Win32 -Name WindowHelper -MemberDefinition @'
    public const int GWL_EXSTYLE = -20;
    public const int WS_EX_APPWINDOW = 0x00040000;
    public const int WS_EX_TOOLWINDOW = 0x00000080;
    public const int SW_HIDE = 0;

    [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowLong(System.IntPtr hWnd, int nIndex);

    [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
    public static extern int SetWindowLong(System.IntPtr hWnd, int nIndex, int dwNewLong);

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
'@

# === CONFIGURE THESE PATHS ===
$chromaApp = "C:\Path\To\RazerChromaSampleApplication.exe"
$appProcessName = "RazerChromaSampleApplication"
# =============================

$proc = Get-Process -Name $appProcessName -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $proc) {
    Write-Output "Launching Chroma Sample App..."
    $proc = Start-Process -FilePath $chromaApp -PassThru

    while ($proc.MainWindowHandle -eq 0) {
        Start-Sleep -Milliseconds 100
        $proc.Refresh()
    }
} else {
    Write-Output "Chroma Sample App already running."
}

$hwnd = $proc.MainWindowHandle
$oldStyle = [Win32.WindowHelper]::GetWindowLong($hwnd, [Win32.WindowHelper]::GWL_EXSTYLE)
$newStyle = ($oldStyle -band (-bnot [Win32.WindowHelper]::WS_EX_APPWINDOW)) -bor [Win32.WindowHelper]::WS_EX_TOOLWINDOW
[Win32.WindowHelper]::SetWindowLong($hwnd, [Win32.WindowHelper]::GWL_EXSTYLE, $newStyle)
[Win32.WindowHelper]::ShowWindow($hwnd, [Win32.WindowHelper]::SW_HIDE)

Write-Output "Chroma Sample App is now hidden and running."

EDIT THE PATHS AT THE TOP OF THE SCRIPT:
- $chromaApp — Full path to your compiled RazerChromaSampleApplication.exe

### Step 3: Create the Task Scheduler Task

Open PowerShell as Administrator and run this command:

schtasks /create /tn "HiddenChroma" /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\Path\To\LaunchAndHideChroma.ps1'" /sc ONLOGON /rl HIGHEST

Replace C:\Path\To\LaunchAndHideChroma.ps1 with your actual script path.

### Step 4: Test

Log out and back in (or restart). The Sample App should launch silently at logon and initialize Chroma.

## Why This Works

- Native schtasks command handles user SID mapping automatically
- No registry hacks — survives Windows reinstalls without modification
- Simple to update — just edit the PowerShell script paths if needed
- Hidden at startup — runs in background, doesn't clutter taskbar

## Troubleshooting

- Task doesn't run: Verify the script path is correct and the file is readable
- Chroma not initializing: Ensure Razer Synapse is installed and all services are running
- Script execution blocked: Run Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser first

## One Major Note

You may still need MinimizeToTray installed for additional window management on some systems, but the core functionality works without it.
