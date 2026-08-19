# ================= FORCE TLS 1.2 + OPTIMIZE =================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    [Net.ServicePointManager]::DefaultConnectionLimit = 1024
    [Net.ServicePointManager]::Expect100Continue = $false
    [Net.ServicePointManager]::UseNagleAlgorithm = $false
} catch {}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "APP TEST SANDBOX (GITHUB RAW REFS)"

Remove-Item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue

# ================= ADMIN CHECK =================
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# ================= TẠO RAM DISK =================
$RamDiskLetter = $null
$UseRamDisk = $false
$Global:SubstDrive = $null
$Global:SubstFolder = $null

function Create-RamDisk {
    param([int]$SizeMB = 1024)
    
    Write-Host "Dang tao RAM Disk $SizeMB MB..." -ForegroundColor Yellow
    
    try {
        $usedLetters = (Get-Volume | Select-Object -ExpandProperty DriveLetter) + 
                       (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name)
        
        $availableLetter = (67..90 | ForEach-Object {[char]$_}) | 
            Where-Object {$usedLetters -notcontains $_} | 
            Select-Object -First 1
        
        if (-not $availableLetter) {
            Write-Host "Khong tim thay o dia trong!" -ForegroundColor Red
            return $null
        }
        
        if (Get-Command imdisk -ErrorAction SilentlyContinue) {
            $null = imdisk -a -s "$($SizeMB)M" -m "$($availableLetter):" -p "/fs:ntfs /q /y"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Da tao RAM Disk tai ${availableLetter}:" -ForegroundColor Green
                return "${availableLetter}:"
            }
        }
        
        Write-Host "ImDisk khong co. Dung subst mapping..." -ForegroundColor Yellow
        $tempRamFolder = Join-Path $env:TEMP "RamDisk_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -ItemType Directory -Path $tempRamFolder -Force | Out-Null
        
        subst "${availableLetter}:" $tempRamFolder
        if ($LASTEXITCODE -eq 0) {
            $Global:SubstDrive = "${availableLetter}:"
            $Global:SubstFolder = $tempRamFolder
            Write-Host "Da tao subst drive tai ${availableLetter}: -> $tempRamFolder" -ForegroundColor Green
            return "${availableLetter}:"
        }
        
        Write-Host "Khong the tao RAM Disk. Dung TEMP thuong." -ForegroundColor Yellow
        return $null
        
    } catch {
        Write-Host "Loi tao RAM Disk: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Remove-RamDisk {
    param([string]$DriveLetter)
    
    if (-not $DriveLetter) { return }
    
    Write-Host "Dang xoa RAM Disk $DriveLetter..." -ForegroundColor Yellow
    
    try {
        if (Get-Command imdisk -ErrorAction SilentlyContinue) {
            imdisk -d -m $DriveLetter 2>$null
        }
        
        if ($Global:SubstDrive) {
            subst $Global:SubstDrive /d 2>$null
            $Global:SubstDrive = $null
        }
        
        if ($Global:SubstFolder -and (Test-Path $Global:SubstFolder)) {
            Start-Sleep -Milliseconds 500
            Remove-Item $Global:SubstFolder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Da xoa thu muc: $($Global:SubstFolder)" -ForegroundColor Green
            $Global:SubstFolder = $null
        }
        
        Write-Host "Da xoa RAM Disk." -ForegroundColor Green
    } catch {}
}

# Khởi tạo RAM Disk
$RamDiskLetter = Create-RamDisk -SizeMB 1024
if ($RamDiskLetter) {
    $UseRamDisk = $true
    $Global:WorkingRoot = $RamDiskLetter
} else {
    $Global:WorkingRoot = $env:TEMP
}

Write-Host "Thu muc lam viec: $Global:WorkingRoot" -ForegroundColor Cyan
Start-Sleep -Seconds 2

# ================= BASE URL =================
$BaseURL = "https://github.com/dhz5/dhz5.github.io/raw/refs/heads/main/Software/"

# ================= APP LIST (26 APP) =================
$Apps = @(
    @{Ten="BOOTICE x86";File="BOOTICEx86.exe"},
    @{Ten="Acronis 2014 Portable";File="Acronis2014_portable.exe"},
    @{Ten="Brave Portable";File="Brave_portable.exe"},
    @{Ten="CocCoc Portable";File="CocCoc_portable.exe"},
    @{Ten="Driver Booster 13";File="Driver_Booster_13_free_portable.exe"},
    @{Ten="Everything Portable";File="Everything_portable.exe"},
    @{Ten="FastCopy Portable";File="FastCopy-portable.exe"},
    @{Ten="Hard Disk Sentinel Pro";File="HDSentinel_pro_portable.exe"},
    @{Ten="Hard Disk Sentinel Standard";File="Hard Disk Sentinel-portable.exe"},
    @{Ten="IDM Portable";File="IDM_portable.exe"},
    @{Ten="LocalSend 1.17";File="LocalSend_1.17_portable.exe"},
    @{Ten="PC Health Check";File="PCHealthCheck_protable.exe"},
    @{Ten="PartitionWizard 10";File="PartitionWizard10.exe"},
    @{Ten="PowerToys 0.98";File="PowerToys.v0.98_portable.exe"},
    @{Ten="PrimoCache Portable";File="PrimoCache_portable.exe"},
    @{Ten="QemuBootTester";File="QemuBootTester.exe"},
    @{Ten="Recuva x32";File="Recuva.exe"},
    @{Ten="Recuva x64";File="Recuva64.exe"},
    @{Ten="Revo Uninstaller";File="Revo Uninstaller_portable.exe"},
    @{Ten="TreeSize Free";File="TreeSize Free_portable.exe"},
    @{Ten="UltraISO Premium Portable";File="UltraISO Premium Portable.exe"},
    @{Ten="WinRAR Portable";File="WinRAR_portable.exe"},
    @{Ten="CPU-Z x32";File="cpuz_x32.exe"},
    @{Ten="CPU-Z x64";File="cpuz_x64.exe"},
    @{Ten="Lightshot Portable";File="lightshot-portable.exe"},
    @{Ten="Rufus 4.4";File="rufus-4.4p.exe"}
    @{Ten="Foxit PDF Editor Portable";File="Foxit PDF Editor _ portable.exe"},
    @{Ten="PDF24 Portable";File="PDF24_portable.exe"}
)

# ================= TEMP STORAGE =================
$Global:TempFolders = New-Object System.Collections.ArrayList
$Global:RunningProcesses = New-Object System.Collections.ArrayList

# ================= FORCE KILL PROCESS TREE =================
function Kill-ProcessTree {
    param([int]$ProcessId)
    
    if ($ProcessId -eq 0) { return }
    
    try {
        # Lấy tất cả process con
        $children = Get-WmiObject Win32_Process | Where-Object { $_.ParentProcessId -eq $ProcessId }
        
        # Kill process con trước
        foreach ($child in $children) {
            Kill-ProcessTree -ProcessId $child.ProcessId
        }
        
        # Kill process cha
        $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "  Killing PID $ProcessId ($($proc.ProcessName))..." -ForegroundColor Red
            
            # Thử kill bằng PowerShell
            Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 200
            
            # Nếu vẫn còn, dùng taskkill
            if (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue) {
                taskkill /F /PID $ProcessId /T 2>$null
                Start-Sleep -Milliseconds 200
            }
            
            # Nếu vẫn còn, dùng WMI
            if (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue) {
                $wmiProc = Get-WmiObject Win32_Process | Where-Object { $_.ProcessId -eq $ProcessId }
                if ($wmiProc) {
                    $wmiProc.Terminate() | Out-Null
                }
            }
        }
    } catch {}
}

# ================= FORCE DELETE FOLDER =================
function Force-DeleteFolder {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) { 
        Write-Host "  Thu muc khong ton tai: $Path" -ForegroundColor Gray
        return $true 
    }
    
    Write-Host "  Dang xoa: $Path" -ForegroundColor Yellow
    
    # Phương pháp 1: Remove-Item
    try {
        Remove-Item $Path -Recurse -Force -ErrorAction Stop
        if (-not (Test-Path $Path)) {
            Write-Host "    -> Xoa thanh cong (Remove-Item)" -ForegroundColor Green
            return $true
        }
    } catch {}
    
    Start-Sleep -Milliseconds 300
    
    # Phương pháp 2: CMD rd
    try {
        cmd /c "rd /s /q `"$Path`"" 2>$null
        if (-not (Test-Path $Path)) {
            Write-Host "    -> Xoa thanh cong (CMD)" -ForegroundColor Green
            return $true
        }
    } catch {}
    
    Start-Sleep -Milliseconds 300
    
    # Phương pháp 3: Robocopy empty folder
    try {
        $emptyFolder = Join-Path $env:TEMP "empty_$(Get-Random)"
        New-Item -ItemType Directory -Path $emptyFolder -Force | Out-Null
        
        robocopy $emptyFolder $Path /MIR /R:0 /W:0 /NFL /NDL /NJH /NJS /NC /NS /NP 2>$null | Out-Null
        Remove-Item $emptyFolder -Force -ErrorAction SilentlyContinue
        Remove-Item $Path -Force -ErrorAction SilentlyContinue
        
        if (-not (Test-Path $Path)) {
            Write-Host "    -> Xoa thanh cong (Robocopy)" -ForegroundColor Green
            return $true
        }
    } catch {}
    
    Start-Sleep -Milliseconds 300
    
    # Phương pháp 4: Xóa từng file rồi xóa folder
    try {
        Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $_.Delete()
            } catch {}
        }
        
        Remove-Item $Path -Force -ErrorAction SilentlyContinue
        
        if (-not (Test-Path $Path)) {
            Write-Host "    -> Xoa thanh cong (Manual)" -ForegroundColor Green
            return $true
        }
    } catch {}
    
    Write-Host "    -> KHONG THE XOA!" -ForegroundColor Red
    return $false
}

# ================= CLEANUP =================
function Cleanup-All {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "DANG DON DEP TAT CA..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""

    # === BƯỚC 1: Kill tất cả process ===
    Write-Host "[1/6] Kill tat ca process dang chay..." -ForegroundColor Cyan
    
    foreach ($proc in $Global:RunningProcesses) {
        try {
            if (-not $proc.HasExited) {
                Kill-ProcessTree -ProcessId $proc.Id
            }
        } catch {}
    }
    
    # Đợi process thực sự chết
    Write-Host "  Doi process chet..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
    
    # Force GC
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Start-Sleep -Milliseconds 500
    
    Write-Host ""

    # === BƯỚC 2: Xóa Sandbox folders ===
    Write-Host "[2/6] Xoa cac thu muc Sandbox..." -ForegroundColor Cyan
    foreach ($folder in ($Global:TempFolders | Select-Object -Unique)) {
        Force-DeleteFolder -Path $folder
    }
    Write-Host ""

    # === BƯỚC 3: Xóa RarSFX ===
    Write-Host "[3/6] Xoa RarSFX..." -ForegroundColor Cyan
    $rarFolders = Get-ChildItem $env:TEMP -Filter "Rar*" -Directory -ErrorAction SilentlyContinue
    foreach ($rarFolder in $rarFolders) {
        Force-DeleteFolder -Path $rarFolder.FullName
    }
    Write-Host ""

    # === BƯỚC 4: Xóa Sandbox_* trên TEMP ===
    Write-Host "[4/6] Xoa Sandbox tren TEMP..." -ForegroundColor Cyan
    $sandboxFolders = Get-ChildItem $env:TEMP -Filter "Sandbox_*" -Directory -ErrorAction SilentlyContinue
    foreach ($sbFolder in $sandboxFolders) {
        Force-DeleteFolder -Path $sbFolder.FullName
    }
    Write-Host ""

    # === BƯỚC 5: Xóa RamDisk_* ===
    Write-Host "[5/6] Xoa RamDisk folders..." -ForegroundColor Cyan
    $ramDiskFolders = Get-ChildItem $env:TEMP -Filter "RamDisk_*" -Directory -ErrorAction SilentlyContinue
    foreach ($rdFolder in $ramDiskFolders) {
        Force-DeleteFolder -Path $rdFolder.FullName
    }
    Write-Host ""

    # === BƯỚC 6: Xóa RAM Disk / Subst ===
    Write-Host "[6/6] Xoa RAM Disk / Subst..." -ForegroundColor Cyan
    if ($UseRamDisk -and $RamDiskLetter) {
        Remove-RamDisk $RamDiskLetter
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "DA DON DEP XONG!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Start-Sleep -Seconds 2
    
    return $true
}

function Exit-Program {
    $result = Cleanup-All
    exit
}

# ================= DOWNLOAD TỐC ĐỘ CAO =================
function Download-File($FileName, $Dest) {
    $Encoded = [System.Uri]::EscapeDataString($FileName)
    $Url = $BaseURL + $Encoded

    Write-Host "URL: $Url" -ForegroundColor Cyan
    Write-Host "Dang tai xuong RAM..." -ForegroundColor Yellow
    Write-Host ""

    try {
        Add-Type -AssemblyName System.Net.Http
        
        $httpClient = New-Object System.Net.Http.HttpClient
        $httpClient.Timeout = [TimeSpan]::FromMinutes(10)
        
        $response = $httpClient.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        
        if (-not $response.IsSuccessStatusCode) {
            Write-Host "Loi HTTP: $($response.StatusCode)" -ForegroundColor Red
            $httpClient.Dispose()
            return $false
        }

        $totalBytes = $response.Content.Headers.ContentLength
        $totalMB = [Math]::Round($totalBytes / 1MB, 2)
        
        $fileStream = [System.IO.File]::Create($Dest)
        $contentStream = $response.Content.ReadAsStreamAsync().Result
        
        $buffer = New-Object byte[] 1048576
        $totalRead = 0
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $lastUpdate = 0
        
        while ($true) {
            $read = $contentStream.Read($buffer, 0, $buffer.Length)
            if ($read -eq 0) { break }
            
            $fileStream.Write($buffer, 0, $read)
            $totalRead += $read
            
            if ($stopwatch.ElapsedMilliseconds - $lastUpdate -gt 100) {
                $percent = [Math]::Round(($totalRead / $totalBytes) * 100, 1)
                $downloadedMB = [Math]::Round($totalRead / 1MB, 2)
                
                $elapsedSeconds = $stopwatch.Elapsed.TotalSeconds
                if ($elapsedSeconds -gt 0) {
                    $speedMBps = [Math]::Round($totalRead / 1MB / $elapsedSeconds, 2)
                    $speedText = "$speedMBps MB/s"
                } else {
                    $speedText = "Calculating..."
                }
                
                Write-Progress -Activity "Dang tai vao RAM" `
                    -Status "$downloadedMB MB / $totalMB MB - $speedText" `
                    -PercentComplete $percent
                
                $lastUpdate = $stopwatch.ElapsedMilliseconds
            }
        }
        
        $stopwatch.Stop()
        $fileStream.Flush()
        $fileStream.Close()
        $contentStream.Close()
        $httpClient.Dispose()
        
        Write-Progress -Activity "Dang tai vao RAM" -Completed
        
        $finalSpeed = [Math]::Round($totalBytes / 1MB / $stopwatch.Elapsed.TotalSeconds, 2)
        Write-Host ""
        Write-Host "Tai thanh cong: $totalMB MB | $([Math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s | $finalSpeed MB/s" -ForegroundColor Green
        
    }
    catch {
        Write-Host "Loi khi tai file: $($_.Exception.Message)" -ForegroundColor Red
        if ($fileStream) { try{$fileStream.Close()}catch{} }
        if ($contentStream) { try{$contentStream.Close()}catch{} }
        if ($httpClient) { try{$httpClient.Dispose()}catch{} }
        return $false
    }

    if (-not (Test-Path $Dest)) { 
        Write-Host "File khong ton tai sau khi tai!" -ForegroundColor Red
        return $false 
    }

    $Size = (Get-Item $Dest).Length
    if ($Size -lt 1000) {
        Write-Host "File khong hop le." -ForegroundColor Red
        Remove-Item $Dest -Force -ErrorAction SilentlyContinue
        return $false
    }

    return $true
}

# ================= PAGING =================
$PageSize = 10
$CurrentPage = 0
$TotalPages = [Math]::Ceiling($Apps.Count / $PageSize)

function Show-Menu {
    Clear-Host
    
    if ($UseRamDisk) {
        Write-Host "========== CHAY HOAN TOAN TREN RAM =========" -ForegroundColor Green
        Write-Host "  RAM Disk: $RamDiskLetter" -ForegroundColor Green
    } else {
        Write-Host "========== CHAY TREN TEMP ==========" -ForegroundColor Yellow
    }
    
    $Start = $CurrentPage * $PageSize
    $End = [Math]::Min($Start + $PageSize - 1, $Apps.Count - 1)

    Write-Host "=========== APP TEST SANDBOX ===========" -ForegroundColor Cyan
    Write-Host "Trang $($CurrentPage+1)/$TotalPages" -ForegroundColor Yellow
    Write-Host ""

    for ($i=$Start; $i -le $End; $i++) {
        Write-Host ("{0:D2}. {1}" -f ($i+1), $Apps[$i].Ten)
    }

    Write-Host ""
    Write-Host "[N] Next  [B] Back  [Q] Quit + Clean All" -ForegroundColor Green
    Write-Host ""
    Write-Host -NoNewline "Nhap so va Enter: "
}

# ================= LAUNCH =================
function Launch-App($App) {

    $TempFolder = Join-Path $Global:WorkingRoot ("Sandbox_" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $TempFolder -Force | Out-Null
    $Global:TempFolders.Add($TempFolder) | Out-Null

    $Dest = Join-Path $TempFolder $App.File

    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Dang xu ly: $($App.Ten)" -ForegroundColor Cyan
    Write-Host "Thu muc RAM: $TempFolder" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Download-File $App.File $Dest)) {
        Write-Host ""
        Write-Host "Nhan phim bat ky de quay lai..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    # Set TEMP/TMP vào RAM
    $OriginalTEMP = $env:TEMP
    $OriginalTMP = $env:TMP
    $env:TEMP = $TempFolder
    $env:TMP = $TempFolder

    Write-Host ""
    Write-Host "Dang khoi dong ung dung tu RAM..." -ForegroundColor Yellow
    
    for ($i=0;$i -le 100;$i+=20){
        Write-Progress -Activity "Khoi dong" -Status "$i%" -PercentComplete $i
        Start-Sleep -Milliseconds 50
    }
    Write-Progress -Activity "Khoi dong" -Completed

    $process = $null
    try {
        $process = Start-Process -FilePath $Dest -WorkingDirectory $TempFolder -Verb RunAs -PassThru
        $Global:RunningProcesses.Add($process) | Out-Null
        
        Write-Host ""
        Write-Host "Ung dung da duoc mo TU RAM." -ForegroundColor Green
        Write-Host "PID: $($process.Id) | Thu muc: $TempFolder" -ForegroundColor Cyan
    } catch {
        Write-Host "Loi khi chay: $($_.Exception.Message)" -ForegroundColor Red
        $env:TEMP = $OriginalTEMP
        $env:TMP = $OriginalTMP
        Write-Host ""
        Write-Host "Nhan phim bat ky de quay lai..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    Write-Host ""
    Write-Host "[E] Quay lai menu (giu app chay)"
    Write-Host "[D] Dong app, don dep, quay lai"
    Write-Host "[Q] Dong app va thoat"

    while ($true) {
        $Key = [Console]::ReadKey($true)
        $Cmd = $Key.KeyChar.ToString().ToUpper()

        if ($Cmd -eq "E") {
            $env:TEMP = $OriginalTEMP
            $env:TMP = $OriginalTMP
            return 
        }
        
        if ($Cmd -eq "D") {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "DONG APP VA DON DEP..." -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            
            # Kill process tree
            if ($process) {
                Kill-ProcessTree -ProcessId $process.Id
            }
            
            Write-Host "Doi 2s cho process chet..." -ForegroundColor Gray
            Start-Sleep -Seconds 2
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            Start-Sleep -Milliseconds 500
            
            # Xóa folder
            Force-DeleteFolder -Path $TempFolder
            
            # Xóa RarSFX
            $rarFolders = Get-ChildItem $env:TEMP -Filter "Rar*" -Directory -ErrorAction SilentlyContinue
            foreach ($rarFolder in $rarFolders) {
                Force-DeleteFolder -Path $rarFolder.FullName
            }
            
            # Xóa RamDisk_*
            $ramDiskFolders = Get-ChildItem $env:TEMP -Filter "RamDisk_*" -Directory -ErrorAction SilentlyContinue
            foreach ($rdFolder in $ramDiskFolders) {
                Force-DeleteFolder -Path $rdFolder.FullName
            }
            
            $Global:TempFolders.Remove($TempFolder) | Out-Null
            $Global:RunningProcesses.Remove($process) | Out-Null
            
            $env:TEMP = $OriginalTEMP
            $env:TMP = $OriginalTMP
            
            Write-Host ""
            Write-Host "Da don dep xong!" -ForegroundColor Green
            Start-Sleep -Seconds 1
            return
        }
        
        if ($Cmd -eq "Q") { 
            $env:TEMP = $OriginalTEMP
            $env:TMP = $OriginalTMP
            Exit-Program 
        }
    }
}

# ================= MAIN LOOP =================
$InputBuffer=""
$NeedRedraw=$true

while ($true) {

    if ($NeedRedraw) {
        Show-Menu
        $NeedRedraw=$false
    }

    $Key=[Console]::ReadKey($true)

    if ($InputBuffer -eq "") {
        switch ($Key.KeyChar.ToString().ToUpper()) {
            "Q" { Exit-Program }
            "N" { if ($CurrentPage -lt $TotalPages-1){$CurrentPage++}; $NeedRedraw=$true; continue }
            "B" { if ($CurrentPage -gt 0){$CurrentPage--}; $NeedRedraw=$true; continue }
        }
    }

    if ($Key.KeyChar -match '[0-9]') {
        $InputBuffer+=$Key.KeyChar
        Write-Host $Key.KeyChar -NoNewline
    }

    elseif ($Key.Key -eq "Backspace") {
        if ($InputBuffer.Length -gt 0){
            $InputBuffer=$InputBuffer.Substring(0,$InputBuffer.Length-1)
            [Console]::SetCursorPosition([Console]::CursorLeft-1,[Console]::CursorTop)
            Write-Host " " -NoNewline
            [Console]::SetCursorPosition([Console]::CursorLeft-1,[Console]::CursorTop)
        }
    }

    elseif ($Key.Key -eq "Enter") {

        $Index=0
        if (-not [int]::TryParse($InputBuffer,[ref]$Index)){ $InputBuffer=""; continue }
        if ($Index -lt 1 -or $Index -gt $Apps.Count){ $InputBuffer=""; continue }

        $InputBuffer=""
        Launch-App $Apps[$Index-1]
        $NeedRedraw=$true
    }
}
