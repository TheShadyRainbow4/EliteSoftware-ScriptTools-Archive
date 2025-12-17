# Define the log folder path
$logFolderPath = Join-Path $PSScriptRoot "Logs"
if (-not (Test-Path $logFolderPath)) {
    New-Item -Path $logFolderPath -ItemType Directory | Out-Null
}

# Start PowerShell transcription. This is the absolute first thing.
Start-Transcript -Path (Join-Path $logFolderPath "SessionLog.txt") -Append

Write-Host "Minimal script started successfully."
Write-Host "This is a test to ensure basic PowerShell execution and logging work."

# Stop transcription
Stop-Transcript

Write-Host "Minimal script finished."
# Exit the script without trying to show any UI or perform complex operations.
exit 0