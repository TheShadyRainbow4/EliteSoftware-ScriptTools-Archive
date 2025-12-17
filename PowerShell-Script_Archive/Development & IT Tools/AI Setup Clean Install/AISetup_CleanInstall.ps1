# ===================================================================================
# AI CONVERSATIONAL ASSISTANT - FULLY AUTOMATED MULTI-THREADED SETUP SCRIPT
# ===================================================================================
# This script will perform a full, automated setup of all components.
#
# IMPORTANT:
# - Ensure Git is installed before running: https://git-scm.com/download/win
# - Run this script with Administrator privileges.
# - This script is designed for a clean installation.
# ===================================================================================

# --- 1. CONFIGURATION ---
$projectRoot = "E:\LOCAL_TTS_CONVERSATION_AI"
$pythonVersion = "3.10.11"

# --- 2. SETUP PROJECT DIRECTORY ---
Write-Host "--- Step 1: Creating/Verifying Project Directory at $projectRoot ---" -ForegroundColor Green
if (-not (Test-Path $projectRoot)) {
    New-Item -Path $projectRoot -ItemType Directory -Force
}
Set-Location $projectRoot

# --- 3. INSTALL PYENV-WIN (PYTHON VERSION MANAGER) ---
Write-Host "--- Step 2: Installing pyenv-win for Python version management ---" -ForegroundColor Green
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "$PSScriptRoot\install-pyenv-win.ps1"
&"$PSScriptRoot\install-pyenv-win.ps1"
# Add pyenv to the PATH for this session
$env:PYENV = [System.Environment]::GetEnvironmentVariable('PYENV', 'User')
if (-not $env:PYENV) { $env:PYENV = "$env:USERPROFILE\.pyenv\pyenv-win" }
$env:Path = "$($env:PYENV)\bin;$($env:PYENV)\shims;$($env:Path)"

# --- 4. START PARALLEL JOBS ---
Write-Host "--- Step 3: Starting parallel downloads and installations. This will run in the background. ---" -ForegroundColor Green

# Job 1: Install Python
$pythonJob = Start-Job -Name "InstallPython" -ScriptBlock {
    param($pyVer)
    $env:PYENV = [System.Environment]::GetEnvironmentVariable('PYENV', 'User')
    if (-not $env:PYENV) { $env:PYENV = "$env:USERPROFILE\.pyenv\pyenv-win" }
    $env:Path = "$($env:PYENV)\bin;$($env:PYENV)\shims;$($env:Path)"
    pyenv install $pyVer
    pyenv rehash
} -ArgumentList $pythonVersion

# Job 2: Download AND Install SillyTavern
$sillyTavernJob = Start-Job -Name "SetupSillyTavern" -ScriptBlock {
    param($path)
    Set-Location $path
    git clone https://github.com/SillyTavern/SillyTavern.git -b release SillyTavern
    # Run the dependency installer script for SillyTavern
    Start-Process -FilePath "$path\SillyTavern\Update-And-Start.bat" -Wait
} -ArgumentList $projectRoot

# Job 3: Download XTTS-WebUI
$xttsJob = Start-Job -Name "DownloadXTTS" -ScriptBlock {
    param($path)
    Set-Location $path
    git clone https://github.com/daswer123/xtts-api-server.git XTTS-WebUI
} -ArgumentList $projectRoot

# --- 5. WAIT FOR JOBS TO COMPLETE ---
Write-Host "--- All jobs started. Waiting for downloads and SillyTavern setup to complete... ---" -ForegroundColor Yellow
# We only need to wait for the three main jobs to finish before the final step
Wait-Job -Name "InstallPython", "SetupSillyTavern", "DownloadXTTS" | Out-Null
Write-Host "--- All parallel jobs have finished. ---" -ForegroundColor Green

# Optional: Display any errors from the jobs
Get-Job | ForEach-Object {
    if ($_.State -eq 'Failed') {
        Write-Host "Job '$($_.Name)' failed. Error:" -ForegroundColor Red
        Receive-Job -Job $_
    }
}
# Clean up jobs
Get-Job | Remove-Job

# --- 6. SETUP THE PYTHON ENVIRONMENT FOR XTTS-WEBUI (Final Sequential Step) ---
Write-Host "--- Step 4: Setting up the Python environment for XTTS-WebUI. This is the final, long step. ---" -ForegroundColor Green
Set-Location "$projectRoot\XTTS-WebUI"
try {
    pyenv local $pythonVersion
    python -m venv venv
    Write-Host "Installing Python dependencies for XTTS... Please be patient." -ForegroundColor Yellow
    &"$projectRoot\XTTS-WebUI\venv\Scripts\pip.exe" install -r requirements.txt
} catch {
    Write-Host "ERROR: Failed to set up XTTS-WebUI environment." -ForegroundColor Red
    exit 1
}

# --- 7. FINAL INSTRUCTIONS ---
Set-Location $projectRoot
# (Final instructions remain the same as the previous script)
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "SUCCESS! The automated setup has finished." -ForegroundColor Cyan
Write-Host "======================================================================="
Write-Host "Your project is located at: $projectRoot"
Write-Host ""
Write-Host "Here are your important next steps:" -ForegroundColor Yellow
Write-Host "1. MANUAL STEP: Install the NVIDIA CUDA Toolkit (the LOCAL version) if you haven't already."
Write-Host "2. MANUAL STEP: Launch LM Studio (or Jan) and START its local API server."
Write-Host "3. LAUNCH XTTS-WebUI: Go to the '$projectRoot\XTTS-WebUI' folder and run its 'start.bat'."
Write-Host "4. LAUNCH SILLYTAVERN: Go to the '$projectRoot\SillyTavern' folder and run its 'Start.bat'."
Write-Host "5. CONFIGURE SILLYTAVERN: This is your only remaining configuration step. Connect to your"
Write-Host "   running LLM and TTS servers in the SillyTavern UI."
Write-Host ""
Write-Host "The heaviest lifting is done! Enjoy your conversational AI!" -ForegroundColor Green