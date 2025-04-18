$levels = @("INFO", "WARN", "ERROR", "DEBUG")
$processes = @("AuthService", "DataSync", "CacheService", "Scheduler", "ReportService", "System")
$messages = @(
    "User '{0}' successfully logged in.",
    "User '{0}' logged out.",
    "Invalid password attempt for user '{0}'.",
    "Data synchronization took longer than expected.",
    "Synchronization completed with {1} errors.",
    "Cache cleared successfully.",
    "Task '{2}' scheduled for {3}.",
    "Failed to generate daily report: {4}.",
    "System check completed. All systems operational."
)
$usernames = @("jdoe", "asmith", "bjones", "admin")
$tasks = @("BackupJob", "CleanupJob", "HealthCheck")
$times = @("02:00 AM", "04:00 AM", "12:00 PM")
$errors = @("file access denied", "timeout occurred", "disk full", "permission denied")

$logFilePath = ".\sample-log.log"
Remove-Item -Path $logFilePath -ErrorAction SilentlyContinue

for ($i = 0; $i -lt 500; $i++) {
    $datetime = (Get-Date).AddMinutes(-$i*3).ToString("yyyy-MM-dd HH:mm:ss")
    $proc = Get-Random $processes
    $lvl = Get-Random $levels

    # Pick and format a message template
    $msgTemplate = Get-Random $messages
    $msg = switch -Regex ($msgTemplate) {
        '\{0\}' { $msgTemplate -f (Get-Random $usernames) }
        '\{1\}' { $msgTemplate -f "", (Get-Random -Minimum 0 -Maximum 5) }
        '\{2\}' { $msgTemplate -f "", "", (Get-Random $tasks) }
        '\{3\}' { $msgTemplate -f "", "", "", (Get-Random $times) }
        '\{4\}' { $msgTemplate -f "", "", "", "", (Get-Random $errors) }
        Default { $msgTemplate }
    }

    "$datetime|$proc|$lvl|$msg" | Out-File -FilePath $logFilePath -Append -Encoding utf8
}

Write-Host "✅ Sample log file generated at: $logFilePath"


Invoke-PS2EXE -InputFile .\LogReader.ps1 -OutputFile .\LogViewer.exe -NoConsole -IconFile ".\icon.ico" -Title "Log Reader" 

[Convert]::ToBase64String([IO.File]::ReadAllBytes(".\magnify_search.gif")) | Set-Content ".\search-doc.b64"
