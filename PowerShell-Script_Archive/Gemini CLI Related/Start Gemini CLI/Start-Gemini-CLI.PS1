#Requires -Version 5.1
<#
.SYNOPSIS
    Starts the Gemini CLI from the script's current directory.
.DESCRIPTION
    This script automatically determines its own location,
    sets the working directory to that location,
    and then executes the "gemini" command.

    It assumes "gemini" is available in your system's PATH.

    It includes extensive error handling, which will
    display detailed error information and pause the console
    on failure, preventing it from closing immediately.
.NOTES
    Author: Gemini
    Date: 2025-11-14
    Version: 2.0
#>

# --- ⚙️ Configuration ---
# This is the command that will be executed.
# It is assumed this command is in your system's PATH.
$cliCommand = "gemini"
# ---------------------------

$ErrorOccurred = $false
$scriptDir = $null

try {
    # --- 1. Determine Script Directory ---
    # $PSScriptRoot is the built-in variable for a script's directory
    if (-not $PSScriptRoot) {
        Write-Warning "\$PSScriptRoot variable is not available. Using fallback method."
        # Fallback for environments where $PSScriptRoot might not be set
        if ($MyInvocation.MyCommand.Path) {
            $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        } else {
            # This is a critical failure, we cannot proceed.
            throw "Fatal Error: Could not determine the script's directory. Both \$PSScriptRoot and \$MyInvocation.MyCommand.Path are unavailable."
        }
    } else {
        $scriptDir = $PSScriptRoot
    }

    Write-Host "Script location identified: $scriptDir"

    # --- 2. Change Working Directory ---
    Set-Location -Path $scriptDir -ErrorAction Stop
    Write-Host "Successfully changed working directory to: $scriptDir"

    # --- 3. Execute the CLI ---
    Write-Host "Attempting to start command: $cliCommand"
    Write-Host "--------------------------------------------------"

    # Use the call operator '&' to execute the command from the system PATH.
    # The working directory is now set to where this script is.
    & $cliCommand

    Write-Host "--------------------------------------------------"
    Write-Host "Gemini CLI process finished."

} catch {
    # --- 🚨 Error Handling ---
    $ErrorOccurred = $true
    Write-Host "==================== ERROR ====================" -ForegroundColor Red
    Write-Host "An error occurred while trying to run the script:" -ForegroundColor Red
    
    # Provide detailed, formatted error information
    Write-Host "
    📄 Error Message:  $($_.Exception.Message)
    🖊️ Command:        $($_.InvocationInfo.Line)
    🔢 Line Number:    $($_.InvocationInfo.ScriptLineNumber)
    " -ForegroundColor Yellow

    if ($_.Exception.Message -like "*cannot be found*") {
        Write-Host "
        💡 HINT: This error often means the command '$cliCommand'
           is not in your system's PATH environment variable.
           Please ensure 'gemini' can be run from any command prompt.
        " -ForegroundColor Cyan
    }
    
    Write-Host "Full Error Details:" -ForegroundColor Gray
    Write-Host ($_ | Format-List | Out-String) -ForegroundColor Gray
    Write-Host "================== END ERROR ==================" -ForegroundColor Red

} finally {
    Write-Host "Script execution has completed."
    
    # If an error was caught, the error message will be displayed,
    # but the script will no longer pause here.
}