after a reinstall of windows (gotta friggin' love broken USB enumeration) this didn't work - so I bullied another LLM and we finally got it working after far too long

# Razer Chroma SDK + SignalRGB - Task Scheduler Fix

**Problem:** After a Windows reinstall, the Chroma SDK Sample App fails to launch at logon due to stale user SID references in Task Scheduler.

## Solution Overview

The issue is that the old Task Scheduler task references a user SID that no longer exists on the new Windows install. Recreating the task with the current user's SID fixes this.

## Step 1: Compile/Locate the Sample App

Download and compile the Razer Chroma Sample Application from:
https://github.com/RazerOfficial/CChromaEditor?tab=readme-ov-file#sample-project

Note the compiled path (e.g., `C:\Path\To\RazerChromaSampleApplication.exe`)

## Step 2: Create the PowerShell Launch Script

Save this as `LaunchAndHideChroma.ps1` (or similar) in your PowerShell Scripts directory:

LaunchAndHideChroma.ps1
Launches the Razer Chroma Sample App and hides it from taskbar
Add-Type -Namespace Win32 -Name WindowHelper -MemberDefinition @'
public const int GWL_EXSTYLE = -20;
public const int WS_EX_APPWINDOW = 0x00040000;
public const int WS_EX_TOOLWINDOW = 0x00000080;
public const int SW_HIDE = 0;

text
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
public static extern int GetWindowLong(System.IntPtr hWnd, int nIndex);

[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
public static extern int SetWindowLong(System.IntPtr hWnd, int nIndex, int dwNewLong);

[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
'@

=== EDIT THESE PATHS ===
$chromaApp = "C:\Path\To\RazerChromaSampleApplication.exe" # Change to your compiled app path
$appProcessName = "RazerChromaSampleApplication"

======================
$proc = Get-Process -Name $appProcessName -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $proc) {
Write-Output "Launching Chroma Sample App..."
$proc = Start-Process -FilePath $chromaApp -PassThru

text
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

Write-Output "Chroma Sample App is now hidden and running in background."

text

## Step 3: Create the Task Scheduler Task

**Open PowerShell as Administrator** and run this **single command**:

schtasks /create /tn "HiddenChroma" /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\Path\To\LaunchAndHideChroma.ps1'" /sc ONLOGON /rl HIGHEST

text

**Replace `C:\Path\To\LaunchAndHideChroma.ps1` with your actual PowerShell script path.**

## Step 4: Test

Log out and back in (or restart). The Sample App should launch silently at logon.

## Troubleshooting

- **Task doesn't run:** Check that the PowerShell script path is correct and accessible
- **No window hiding:** Ensure MinimizeToTray is installed for additional window management
- **Services not starting:** Verify Razer Synapse is installed and running

## Key Difference from Before

The original setup relied on PowerShell script embedding and complex XML manipulation. This simplified approach uses native Windows Task Scheduler (/create via schtasks) which handles user SID resolution automatically and survives Windows reinstalls without modification.
