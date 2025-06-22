# SignalRGBvRazer
Simple steps!

Download the Sampler App (acquired and then compiled from https://github.com/RazerOfficial/CChromaEditor?tab=readme-ov-file#sample-project) and put it in whatever directory you prefer.

The same goes for the script.

Drop it wherever, change the directory to the compiled app and that step is done.

Then schedule it with Windows Task Manager:

Schedule it at logon
- Open Task Scheduler.
- Action → Create Task…
- On General, give it a name (“Chroma Hidden”).
- Check “Run only when user is logged on” (so window-hiding works).
- On Triggers, New… → Begin the task: At log on → OK.
- On Actions, New… →
• Program/script: powershell.exe
• Add arguments:
-NoProfile -ExecutionPolicy Bypass -File "C:\Path\To\LaunchChromaHidden.ps1"
- OK and exit.
