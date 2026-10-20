
@echo off
setlocal EnableExtensions
title EFS + BitLocker Backup Manager
color 0B

:: ============================================================
:: EFS + BITLOCKER MANAGER
:: Run as Administrator on installed Windows.
:: Backup folder: next to this CMD file.
:: ============================================================

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Please run as Administrator.
    echo Right-click this file and select Run as administrator.
    pause
    exit /b 1
)

:MENU
cls
echo ============================================================
echo                 EFS + BITLOCKER MANAGER
echo ============================================================
echo.
echo   [1] Check and Backup EFS + BitLocker
echo   [2] Decrypt EFS files and turn off BitLocker on all volumes
echo   [3] Exit
echo.
choice /c 123 /n /m "Select an option [1-3]: "

if errorlevel 3 goto END
if errorlevel 2 goto DISABLEALL
if errorlevel 1 goto BACKUP


:: ============================================================
:: OPTION 1 - CHECK AND BACKUP
:: ============================================================

:BACKUP
cls
echo ============================================================
echo                CHECK AND BACKUP
echo ============================================================
echo.
echo Checking available volumes and encryption status...
echo This scan may take a long time.
echo.

set "CHECKDIR=%TEMP%\EFS_BL_Check_%RANDOM%_%RANDOM%"
md "%CHECKDIR%" 2>nul

if not exist "%CHECKDIR%\" (
    echo [ERROR] Cannot create temporary check folder.
    pause
    goto MENU
)

set "NEEDBACKUP=0"
set "EFSFOUND=0"
set "BLFOUND=0"

:: ------------------------------------------------------------
:: Check BitLocker volumes
:: ------------------------------------------------------------

echo [1/3] Checking BitLocker...

manage-bde -status > "%CHECKDIR%\BitLocker_Status.txt" 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$v=Get-BitLockerVolume -ErrorAction SilentlyContinue; if($v | Where-Object { $_.VolumeStatus -ne 'FullyDecrypted' }) { exit 0 } else { exit 1 }"

if not errorlevel 1 (
    set "BLFOUND=1"
    set "NEEDBACKUP=1"
    echo BitLocker encryption detected.
) else (
    echo No BitLocker-encrypted volumes detected.
)

:: ------------------------------------------------------------
:: Check EFS encrypted files on accessible drive letters
:: ------------------------------------------------------------

echo.
echo [2/3] Scanning EFS files...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$out='%CHECKDIR%\EFS_Scan.txt'; $errors='%CHECKDIR%\EFS_Scan_Errors.txt'; $found=$false; $drives=Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue; foreach($d in $drives) { $root=$d.DeviceID+'\'; Write-Host ('Scanning '+$root); try { Get-ChildItem -LiteralPath $root -Force -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [IO.FileAttributes]::Encrypted } | ForEach-Object { $_.FullName | Out-File -LiteralPath $out -Append -Encoding utf8; $found=$true } } catch { $_.Exception.Message | Out-File -LiteralPath $errors -Append } }; if($found) { exit 0 } else { exit 1 }" 

if not errorlevel 1 (
    set "EFSFOUND=1"
    set "NEEDBACKUP=1"
    echo EFS-encrypted files detected.
) else (
    echo No EFS-encrypted files detected by the scan.
)

:: ------------------------------------------------------------
:: No encryption detected - do not create backup folder
:: ------------------------------------------------------------

echo.
if "%NEEDBACKUP%"=="0" (
    echo ============================================================
    echo No EFS files or BitLocker encryption detected.
    echo No backup folder was created.
    echo ============================================================
    rd /s /q "%CHECKDIR%" 2>nul
    pause
    goto MENU
)

:: ------------------------------------------------------------
:: Create unique backup folder only when encryption is detected
:: ------------------------------------------------------------

echo [3/3] Preparing backup folder...

set "ROOT=%~dp0Backup"
set "PCNAME=%COMPUTERNAME%"
set "PRODID="

for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductId 2^>nul ^| find /i "ProductId"') do set "PRODID=%%B"

if not defined PRODID set "PRODID=UnknownProductID"

set "BKDATE="
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "BKDATE=%%A"

if not defined BKDATE (
    echo [ERROR] Cannot determine backup date.
    rd /s /q "%CHECKDIR%" 2>nul
    pause
    goto MENU
)

set "BACKUP=%ROOT%\%PCNAME%_%PRODID%_%BKDATE%"

md "%BACKUP%" 2>nul

if not exist "%BACKUP%\" (
    echo [ERROR] Cannot create backup folder:
    echo "%BACKUP%"
    rd /s /q "%CHECKDIR%" 2>nul
    pause
    goto MENU
)

echo.
echo Backup destination:
echo "%BACKUP%"
echo.

:: Save basic computer information

(
    echo ComputerName=%COMPUTERNAME%
    echo WindowsProductID=%PRODID%
    echo BackupDate=%BKDATE%
    echo EFSDetected=%EFSFOUND%
    echo BitLockerDetected=%BLFOUND%
) > "%BACKUP%\System_Info.txt"

:: Save BitLocker status

copy /y "%CHECKDIR%\BitLocker_Status.txt" "%BACKUP%\BitLocker_Status.txt" >nul

:: Save EFS scan results

if exist "%CHECKDIR%\EFS_Scan.txt" (
    copy /y "%CHECKDIR%\EFS_Scan.txt" "%BACKUP%\EFS_Encrypted_Files.txt" >nul
)

if exist "%CHECKDIR%\EFS_Scan_Errors.txt" (
    copy /y "%CHECKDIR%\EFS_Scan_Errors.txt" "%BACKUP%\EFS_Scan_Errors.txt" >nul
)

:: ------------------------------------------------------------
:: Export EFS certificate for current user
:: ------------------------------------------------------------

if "%EFSFOUND%"=="1" (
    echo.
    echo ============================================================
    echo EFS files detected.
    echo Exporting the current user's EFS certificate...
    echo Enter a strong password when prompted.
    echo ============================================================
    echo.

    cipher /x "%BACKUP%\EFS_Certificate"

    echo.
    if exist "%BACKUP%\EFS_Certificate.pfx" (
        echo EFS PFX file found.
    ) else (
        echo [WARNING] EFS PFX was not found at the expected path.
        echo Check the cipher command output and locate the exported file.
    )
) else (
    echo.
    echo No EFS files detected. Skipping EFS certificate export.
)

:: ------------------------------------------------------------
:: Save BitLocker protector information for detected volumes
:: WARNING: Output can contain recovery passwords in plaintext.
:: ------------------------------------------------------------

if "%BLFOUND%"=="1" (
    echo.
    echo Saving BitLocker protector information...
    echo WARNING: These files may contain recovery passwords.
    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
     "$vols=Get-BitLockerVolume -ErrorAction SilentlyContinue; foreach($v in $vols) { if($v.VolumeStatus -ne 'FullyDecrypted' -and $v.MountPoint) { $safe=$v.MountPoint.TrimEnd(':','\'); $path=Join-Path '%BACKUP%' ('BitLocker_Protectors_'+$safe+'.txt'); ('Volume: '+$v.MountPoint) | Out-File -LiteralPath $path -Encoding utf8; manage-bde -protectors -get $v.MountPoint 2>&1 | Out-File -LiteralPath $path -Append -Encoding utf8 } }"
)

echo.
echo ============================================================
echo BACKUP COMMANDS FINISHED
echo ============================================================
echo.
echo Review all files in:
echo "%BACKUP%"
echo.
echo Verify that the PFX and required recovery keys exist.
echo Store recovery keys securely, preferably on another device.
echo.

rd /s /q "%CHECKDIR%" 2>nul

choice /c YN /n /m "Do you want to decrypt EFS and turn off BitLocker now? [Y/N]: "
if errorlevel 2 goto MENU
goto DISABLEALL


:: ============================================================
:: OPTION 2 - DECRYPT EFS AND TURN OFF BITLOCKER
:: ============================================================

:DISABLEALL
cls
echo ============================================================
echo           DECRYPT EFS + TURN OFF BITLOCKER
echo ============================================================
echo.
echo WARNING:
echo - EFS decryption changes files.
echo - BitLocker decryption can take a long time.
echo - Locked or inaccessible volumes may fail.
echo - Back up important data and recovery keys first.
echo.
choice /c YN /n /m "Process all detected volumes? [Y/N]: "
if errorlevel 2 goto MENU

echo.
echo ============================================================
echo [1/2] Decrypting accessible EFS files
echo ============================================================
echo.
echo This may take a long time.
echo.

for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\" (
        echo.
        echo Processing EFS files on %%D:\
        cipher /d /s:%%D:\ /h
    )
)

echo.
echo ============================================================
echo [2/2] Requesting BitLocker decryption on all volumes
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Continue'; $vols=Get-BitLockerVolume -ErrorAction SilentlyContinue; foreach($v in $vols) { if($v.VolumeStatus -ne 'FullyDecrypted' -and $v.MountPoint) { Write-Host ('Processing '+$v.MountPoint+' - '+$v.VolumeStatus); try { Disable-BitLocker -MountPoint $v.MountPoint -ErrorAction Stop | Out-Host } catch { Write-Host ('FAILED: '+$v.MountPoint+' - '+$_.Exception.Message) } } }"

echo.
echo ============================================================
echo REQUESTS FINISHED - VERIFY ACTUAL STATUS
echo ============================================================
echo.
manage-bde -status
echo.
echo BitLocker decryption may continue in the background.
echo Check again with: manage-bde -status
echo.
echo EFS files that could not be accessed may remain encrypted.
echo.
pause
goto MENU


:: ============================================================
:: EXIT
:: ============================================================

:END
endlocal
exit /b 0
