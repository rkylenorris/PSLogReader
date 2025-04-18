Import-Module PS2EXE
# This script converts a PowerShell script into an executable file using the PS2EXE module.

Invoke-PS2EXE -InputFile .\LogReader.ps1 -OutputFile .\LogViewer.exe -NoConsole -IconFile ".\icon.ico" -Title "Log Reader" 