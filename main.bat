@echo off
setlocal EnableDelayedExpansion

:: ===================================================================================
:: Script Name: Brave Browser Privacy & Debloat (Windows)
:: Description: Enhances Brave Browser privacy by disabling telemetry, bloatware, 
::              and unwanted features on Windows.
:: Author: Fiandev
:: ===================================================================================

:: Check for Administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Configuration & Constants
set "BRAVE_EXEC_PATH="
set "USER_DATA_PATH="
set "BACKUP_DIR=%USERPROFILE%\BraveBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"

:: Initialize
cls
echo ==============================================================================
echo Brave Browser Privacy ^& Debloating Script (Windows)
echo ==============================================================================
echo.

:: 1. Close Brave Browser
echo [1/6] Closing running Brave instances...
taskkill /F /IM brave.exe >nul 2>&1
if %errorLevel% equ 0 (
    echo    - Brave Browser closed successfully.
) else (
    echo    - Brave Browser was not running.
)
echo.

:: 2. Locate Brave Installation & User Data
echo [2/6] Locating Brave installation...
if exist "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" (
    set "BRAVE_EXEC_PATH=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
) else if exist "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe" (
    set "BRAVE_EXEC_PATH=C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe"
) else if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe" (
    set "BRAVE_EXEC_PATH=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe"
)

if defined BRAVE_EXEC_PATH (
    echo    - Found Brave at: "%BRAVE_EXEC_PATH%"
) else (
    echo    ! Error: Brave Browser executable not found.
    pause
    exit /b 1
)

set "USER_DATA_PATH=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
if exist "%USER_DATA_PATH%" (
    echo    - Found User Data at: "%USER_DATA_PATH%"
) else (
    echo    ! Error: User Data directory not found. Have you run Brave at least once?
    pause
    exit /b 1
)
echo.

:: 3. Create Backups
echo [3/6] Creating backups...
mkdir "%BACKUP_DIR%" 2>nul
echo    - Backup directory created: "%BACKUP_DIR%"

:: Backup Hosts file
copy "%HOSTS_FILE%" "%BACKUP_DIR%\hosts.bak" >nul 2>&1
echo    - Hosts file backed up.

:: 4. Modify Preferences for All Profiles
echo [4/6] Modifying preferences for all profiles...

:: PowerShell script to update JSON
set "PS_SCRIPT=%TEMP%\update_brave_prefs.ps1"
(
echo $path = $args[0]
echo if ^(Test-Path $path^) {
echo     try {
echo         $json = Get-Content $path -Raw ^| ConvertFrom-Json
echo         if ^(-not $json.brave^) { $json | Add-Member -MemberType NoteProperty -Name "brave" -Value @{} }
echo         if ^(-not $json.brave.rewards^) { $json.brave | Add-Member -MemberType NoteProperty -Name "rewards" -Value @{} }
echo         $json.brave.rewards.enabled = $false
echo         $json.brave.rewards.hide_button = $true
echo         if ^(-not $json.brave.brave_ads^) { $json.brave | Add-Member -MemberType NoteProperty -Name "brave_ads" -Value @{} }
echo         $json.brave.brave_ads.enabled = $false
echo         $json.brave.brave_ads.opted_in = $false
echo         if ^(-not $json.brave.wallet^) { $json.brave | Add-Member -MemberType NoteProperty -Name "wallet" -Value @{} }
echo         $json.brave.wallet.rpc_allowed_origins = @^(@)
echo         $json.brave.wallet.keyring_lock_timeout_mins = 0
echo         if ^(-not $json.brave.p3a_enabled^) { $json.brave | Add-Member -MemberType NoteProperty -Name "p3a_enabled" -Value $false }
echo         $json.brave.p3a_enabled = $false
echo         if ^(-not $json.brave.stats^) { $json.brave | Add-Member -MemberType NoteProperty -Name "stats" -Value @{} }
echo         $json.brave.stats.usage_ping_enabled = $false
echo         if ^(-not $json.brave.today^) { $json.brave | Add-Member -MemberType NoteProperty -Name "today" -Value @{} }
echo         $json.brave.today.opted_in = $false
echo         if ^(-not $json.brave.ipfs^) { $json.brave | Add-Member -MemberType NoteProperty -Name "ipfs" -Value @{} }
echo         $json.brave.ipfs.enabled = $false
echo         if ^(-not $json.brave.leo^) { $json.brave | Add-Member -MemberType NoteProperty -Name "leo" -Value @{} }
echo         $json.brave.leo.enabled = $false
echo         $json.brave.leo.onboarding_seen = $true
echo         if ^(-not $json.brave.ai_chat^) { $json.brave | Add-Member -MemberType NoteProperty -Name "ai_chat" -Value @{} }
echo         $json.brave.ai_chat.enabled = $false
echo         if ^(-not $json.brave.ai^) { $json.brave | Add-Member -MemberType NoteProperty -Name "ai" -Value @{} }
echo         $json.brave.ai.autocomplete_enabled = $false
echo         $json ^| ConvertTo-Json -Depth 20 ^| Set-Content $path
echo         Write-Host "Success"
echo     } catch {
echo         Write-Host "Error: $_"
echo     }
echo }
) > "%PS_SCRIPT%"

:: Iterate through Default and Profile * directories
for /d %%D in ("%USER_DATA_PATH%\Default" "%USER_DATA_PATH%\Profile *") do (
    if exist "%%D\Preferences" (
        set "PROFILE_NAME=%%~nxD"
        echo    - Processing profile: !PROFILE_NAME!
        
        :: Backup Preferences
        mkdir "%BACKUP_DIR%\!PROFILE_NAME!" 2>nul
        copy "%%D\Preferences" "%BACKUP_DIR%\!PROFILE_NAME!\Preferences.bak" >nul 2>&1
        
        :: Run PowerShell script to update preferences
        powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" "%%D\Preferences"
    )
)

del "%PS_SCRIPT%" >nul 2>&1
echo    - Preferences updated.
echo.

:: 5. Block Telemetry in Hosts File
echo [5/6] Blocking telemetry domains...
set "DOMAINS=variations.brave.com go-updater.brave.com componentupdater.brave.com crlsets.brave.com laptop-updates.brave.com brave-core-ext.s3.brave.com grant.rewards.brave.com stats.brave.com p3a.brave.com analytics.brave.com rewards.brave.com pcdn.brave.com static1.brave.com updates.bravesoftware.com"

for %%D in (%DOMAINS%) do (
    findstr /C:"%%D" "%HOSTS_FILE%" >nul
    if !errorlevel! neq 0 (
        echo 0.0.0.0 %%D >> "%HOSTS_FILE%"
        echo    - Blocked: %%D
    )
)
echo    - Telemetry blocking complete.
echo.

:: 6. Select Shortcut Type
echo [6/7] Select shortcut type...
echo.
echo Select shortcut type to create:
echo 1) Private (Incognito + Privacy Flags) - [Default]
echo 2) Slim (Standard Window + Privacy Flags)
echo 3) Both
echo.
set /p "SHORTCUT_CHOICE=Enter choice [1-3]: "
if not defined SHORTCUT_CHOICE set "SHORTCUT_CHOICE=1"

:: Common Privacy Flags (No Incognito)
set "BASE_PRIVACY_ARGS=--disable-brave-sync --disable-features=BraveRewards,BraveAds,BraveWallet,BraveNews,Speedreader,BraveAdblock,BraveSpeedreader,BraveVPN,Crypto,CryptoWallets,InterestCohortAPI,Fledge,Topics,InterestFeedV2,UseChromeOSDirectVideoDecoder,BraveLeo,BraveLeoInline,BraveAIChat,BraveAIPrompts,BravePromptAutocomplete --disable-background-networking --disable-component-extensions-with-background-pages --disable-domain-reliability --disable-sync-preferences --disable-site-isolation-trials --disable-prediction-service --disable-remote-fonts --disable-extensions-http-throttling --disable-breakpad --disable-speech-api --disable-translate --disable-sync --disable-first-run-ui --disable-client-side-phishing-detection --disable-component-updater --disable-suggestions-service --disable-webgl --no-pings --no-report-upload --no-service-autorun --no-first-run --aggressive-cache-discard --metrics-recording-only --clear-token-service --reset-variation-state --block-new-web-contents --start-maximized"

:: 7. Create Shortcuts based on choice
echo.
echo [7/7] Creating shortcuts...

:: Helper script for shortcut creation
set "PS_CREATE_SHORTCUT=%TEMP%\create_shortcut_func.ps1"
(
echo param^($path, $target, $args, $desc^)
echo $WshShell = New-Object -comObject WScript.Shell
echo $Shortcut = $WshShell.CreateShortcut^($path^)
echo $Shortcut.TargetPath = $target
echo $Shortcut.Arguments = $args
echo $Shortcut.Description = $desc
echo $Shortcut.Save^(\)
) > "%PS_CREATE_SHORTCUT%"

if "%SHORTCUT_CHOICE%"=="1" goto CreatePrivate
if "%SHORTCUT_CHOICE%"=="2" goto CreateSlim
if "%SHORTCUT_CHOICE%"=="3" goto CreateBoth
goto CreatePrivate

:CreatePrivate
set "S_PATH=%USERPROFILE%\Desktop\Brave (Private).lnk"
set "S_ARGS=%BASE_PRIVACY_ARGS% --incognito"
powershell -ExecutionPolicy Bypass -File "%PS_CREATE_SHORTCUT%" "%S_PATH%" "%BRAVE_EXEC_PATH%" "%S_ARGS%" "Launch Brave (Private)"
echo    - Created: Brave (Private)
goto EndShortcuts

:CreateSlim
set "S_PATH=%USERPROFILE%\Desktop\Brave (Slim).lnk"
set "S_ARGS=%BASE_PRIVACY_ARGS%"
powershell -ExecutionPolicy Bypass -File "%PS_CREATE_SHORTCUT%" "%S_PATH%" "%BRAVE_EXEC_PATH%" "%S_ARGS%" "Launch Brave (Slim)"
echo    - Created: Brave (Slim)
goto EndShortcuts

:CreateBoth
:: Private
set "S_PATH=%USERPROFILE%\Desktop\Brave (Private).lnk"
set "S_ARGS=%BASE_PRIVACY_ARGS% --incognito"
powershell -ExecutionPolicy Bypass -File "%PS_CREATE_SHORTCUT%" "%S_PATH%" "%BRAVE_EXEC_PATH%" "%S_ARGS%" "Launch Brave (Private)"
echo    - Created: Brave (Private)

:: Slim
set "S_PATH=%USERPROFILE%\Desktop\Brave (Slim).lnk"
set "S_ARGS=%BASE_PRIVACY_ARGS%"
powershell -ExecutionPolicy Bypass -File "%PS_CREATE_SHORTCUT%" "%S_PATH%" "%BRAVE_EXEC_PATH%" "%S_ARGS%" "Launch Brave (Slim)"
echo    - Created: Brave (Slim)
goto EndShortcuts

:EndShortcuts
del "%PS_CREATE_SHORTCUT%" >nul 2>&1
echo.

echo ==============================================================================
echo Setup Complete!
echo.
echo Please review the backups at: "%BACKUP_DIR%"
echo It is recommended to verify settings at brave://settings/privacy
echo ==============================================================================
pause
