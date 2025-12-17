@echo off
REM --- Launcher for WIP Unenrollment Tool ---
REM Created by: Zachary Whiteman & Google Gemini Ai. 2025-10-18 - 08:08:45

REM The /c closes the CMD window after execution, leaving only the PowerShell GUI.
REM The -File parameter is the most robust way to launch a script with PowerShell 7.
REM NOTE: You may need to change the path below if your PowerShell 7 executable
REM is not in the standard location or if you want to use the PowerShell 7 preview executable.

SET PSH_EXE="C:\Program Files\PowerShell\7\pwsh.exe"
SET SCRIPT_PATH="%~dp0WIP_Unenroll.ZACH"

REM The 'start' command launches the process in a new, unattached window.
REM This is the key to preventing the script host from dying on us.
start "" %PSH_EXE% -NoProfile -ExecutionPolicy Bypass -File %SCRIPT_PATH%

REM Exit the batch file immediately
EXIT