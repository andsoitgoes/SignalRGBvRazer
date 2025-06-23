# LaunchAndHideChroma.ps1

# Define the helper type with the necessary Win32 API methods and constants.
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

# Path to your Chroma Sample Application
$chromaApp = "C:\Visual Studio\Compiled\RazerChromaSampleApplication.exe"

# Process name (without the .exe extension) – adjust if needed.
$appProcessName = "RazerChromaSampleApplication"

# Check if the application is already running.
$proc = Get-Process -Name $appProcessName -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $proc) {
    Write-Output "Application not running. Launching..."
    $proc = Start-Process -FilePath $chromaApp -PassThru

    # Wait until the app creates its main window.
    while ($proc.MainWindowHandle -eq 0) {
        Start-Sleep -Milliseconds 100
        $proc.Refresh()
    }
} else {
    Write-Output "Application already running."
}

# Retrieve the app's main window handle.
$hwnd = $proc.MainWindowHandle

# Get the current extended window style.
$oldStyle = [Win32.WindowHelper]::GetWindowLong($hwnd, [Win32.WindowHelper]::GWL_EXSTYLE)

# Modify the style: remove WS_EX_APPWINDOW and add WS_EX_TOOLWINDOW.
$newStyle = ($oldStyle -band (-bnot [Win32.WindowHelper]::WS_EX_APPWINDOW)) -bor [Win32.WindowHelper]::WS_EX_TOOLWINDOW
[Win32.WindowHelper]::SetWindowLong($hwnd, [Win32.WindowHelper]::GWL_EXSTYLE, $newStyle)

# Hide the window completely (SW_HIDE = 0).
[Win32.WindowHelper]::ShowWindow($hwnd, [Win32.WindowHelper]::SW_HIDE)

# Don't forget to add to task scheduler the following line: powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Path\To\LaunchAndHideChroma.ps1"
Write-Output "Chroma Sample App should now be hidden and removed from the taskbar."
