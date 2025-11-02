# SignalRGB for Razer Fix

Eliminates the conflict between Razer Synapse and SignalRGB by running the Chroma Sample App as a hidden background service.

## Problem

After Windows reinstall, Chroma SDK fails to initialize because Task Scheduler has a stale user SID. The app crashes in a restart loop.

## Solution

Uses native Windows Task Scheduler to execute the app with current user credentials at logon.

## Setup

### Step 1: Compile Sample App

Download from https://github.com/RazerOfficial/CChromaEditor

Save the full path to RazerChromaSampleApplication.exe

### Step 2: Create Launch Script

Save as LaunchAndHideChroma.ps1:

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

    $chromaApp = "C:\Path\To\RazerChromaSampleApplication.exe"
    $appProcessName = "RazerChromaSampleApplication"

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

**EDIT: Change $chromaApp path to your compiled app location**

### Step 3: Create Task Scheduler Task

Run in PowerShell as Administrator:

    schtasks /create /tn "HiddenChroma" /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Path\To\LaunchAndHideChroma.ps1" /sc ONLOGON /rl HIGHEST

Replace the path with your actual script location.

### Step 4: Test

Log out and back in. App launches silently at logon.

## Why It Works

- Native schtasks handles user SID automatically
- No registry hacks - survives Windows reinstalls
- Easy to update - just edit script paths
- Runs hidden in background

## Troubleshooting

- Task does not run: Verify script path is correct
- Chroma not initializing: Ensure Synapse is running
- Blocked execution: Run Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
