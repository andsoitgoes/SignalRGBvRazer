# PowerShell script (e.g., launch_chroma_dummy.ps1)
$appPath = "C:\Path\To\RazerChromaSampleApplication.exe"
Start-Process -FilePath $appPath -WindowStyle Hidden
