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

function Create-RamDisk {
    param([int]$SizeMB = 512)
    
    Write-Host "Dang tao RAM Disk $SizeMB MB..." -ForegroundColor Yellow
    
    try {
        # Tìm ổ đĩa trống
        $usedLetters = (Get-Volume | Select-Object -ExpandProperty DriveLetter) + 
                       (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name)
        
        $availableLetter = (67..90 | ForEach-Object {[char]$_}) | 
            Where-Object {$usedLetters -notcontains $_} | 
            Select-Object -First 1
        
        if (-not $availableLetter) {
            Write-Host "Khong tim thay o dia trong! Dung TEMP thuong." -ForegroundColor Red
            return $null
        }
        
        # Tạo ImDisk RAM Disk nếu có cài
        if (Get-Command imdisk -ErrorAction SilentlyContinue) {
            $null = imdisk -a -s "$($SizeMB)M" -m "$($availableLetter):" -p "/fs:ntfs /q /y"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Da tao RAM Disk tai ${availableLetter}:" -ForegroundColor Green
                return "${availableLetter}:"
            }
        }
        
        # Fallback: Dùng subst với TEMP (vẫn trên RAM nếu TEMP trên RAM)
        Write-Host "ImDisk khong co. Dung subst mapping..." -ForegroundColor Yellow
        $tempRamFolder = Join-Path $env:TEMP "RamDisk_$(Get-Random)"
        New-Item -ItemType Directory -Path $tempRamFolder -Force | Out-Null
        
        subst "${availableLetter}:" $tempRamFolder
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Da tao subst drive tai ${availableLetter}:" -ForegroundColor Green
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
        # Xóa ImDisk
        if (Get-Command imdisk -ErrorAction SilentlyContinue) {
            imdisk -d -m $DriveLetter 2>$null
        }
        
        # Xóa subst
        subst $DriveLetter /d 2>$null
        
        Write-Host "Da xoa RAM Disk." -ForegroundColor Green
    } catch {
        # Ignore errors
    }
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
)

# ================= TEMP STORAGE =================
$Global:TempFolders = New-Object System.Collections.ArrayList
$Global:RunningProcesses = New-Object System.Collections.ArrayList

function Cleanup-All {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "DANG DON DEP TAT CA..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    # 1. Đóng tất cả process đang chạy
    Write-Host "1. Dang dong cac ung dung..." -ForegroundColor Cyan
    foreach ($proc in $Global:RunningProcesses) {
        try {
            if (-not $proc.HasExited) {
                $proc.Kill()
                $proc.WaitForExit(2000)
            }
        } catch {}
    }
    
    # 2. Xóa các folder temp
    Write-Host "2. Dang xoa cac thu muc tam..." -ForegroundColor Cyan
    foreach ($folder in ($Global:TempFolders | Select-Object -Unique)) {
        if (Test-Path $folder) {
            Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    # 3. Xóa các folder RarSFX
    Write-Host "3. Dang xoa cac thu muc RarSFX..." -ForegroundColor Cyan
    $rarFolders = Get-ChildItem $env:TEMP -Filter "Rar*" -Directory -ErrorAction SilentlyContinue
    foreach ($rarFolder in $rarFolders) {
        Remove-Item $rarFolder.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # 4. Xóa RAM Disk nếu có
    if ($UseRamDisk -and $RamDiskLetter) {
        Write-Host "4. Dang xoa RAM Disk..." -ForegroundColor Cyan
        Remove-RamDisk $RamDiskLetter
    }
    
    Write-Host ""
    Write-Host "Da don dep xong!" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

function Exit-Program {
    Cleanup-All
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
        
        $buffer = New-Object byte[] 1048576  # 1MB buffer
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
        $fileStream.Close()
        $contentStream.Close()
        $httpClient.Dispose()
        
        Write-Progress -Activity "Dang tai vao RAM" -Completed
        
        $finalSpeed = [Math]::Round($totalBytes / 1MB / $stopwatch.Elapsed.TotalSeconds, 2)
        Write-Host ""
        Write-Host "Tai thanh cong vao RAM: $totalMB MB trong $([Math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s" -ForegroundColor Green
        Write-Host "Toc do trung binh: $finalSpeed MB/s" -ForegroundColor Green
        
    }
    catch {
        Write-Host "Loi khi tai file: $($_.Exception.Message)" -ForegroundColor Red
        if ($fileStream) { $fileStream.Close() }
        if ($contentStream) { $contentStream.Close() }
        if ($httpClient) { $httpClient.Dispose() }
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
    
    # Hiển thị trạng thái RAM Disk
    if ($UseRamDisk) {
        Write-Host "========== CHAY HOAN TOAN TREN RAM =========" -ForegroundColor Green
        Write-Host "RAM Disk: $RamDiskLetter" -ForegroundColor Green
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

    Write-Host ""
    Write-Host "Dang khoi dong ung dung tu RAM..." -ForegroundColor Yellow
    
    # Set biến môi trường TEMP và TMP để app giải nén vào RAM
    $env:TEMP = $TempFolder
    $env:TMP = $TempFolder
    
    for ($i=0;$i -le 100;$i+=20){
        Write-Progress -Activity "Khoi dong" -Status "$i%" -PercentComplete $i
        Start-Sleep -Milliseconds 50
    }
    Write-Progress -Activity "Khoi dong" -Completed

    # Chạy app và theo dõi process
    try {
        $process = Start-Process -FilePath $Dest -WorkingDirectory $TempFolder -Verb RunAs -PassThru
        $Global:RunningProcesses.Add($process) | Out-Null
        
        Write-Host ""
        Write-Host "Ung dung da duoc mo TU RAM voi quyen Administrator." -ForegroundColor Green
        Write-Host "Process ID: $($process.Id)" -ForegroundColor Cyan
    } catch {
        Write-Host "Loi khi chay: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "[E] Quay lai menu"
    Write-Host "[Q] Thoat va don dep tat ca"

    while ($true) {
        $Key = [Console]::ReadKey($true)
        $Cmd = $Key.KeyChar.ToString().ToUpper()

        if ($Cmd -eq "E") { return }
        if ($Cmd -eq "Q") { Exit-Program }
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