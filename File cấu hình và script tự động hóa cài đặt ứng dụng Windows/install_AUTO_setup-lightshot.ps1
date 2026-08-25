$wshell = New-Object -ComObject WScript.Shell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


# Chạy file cần cài
Start-Process ".\setup-lightshot.exe"

# Chờ SmartScreen xuất hiện
Start-Sleep -Seconds 2

# Kích hoạt cửa sổ SmartScreen
$wshell.AppActivate("Windows protected your PC")

Start-Sleep -Milliseconds 500

# More info
$wshell.SendKeys("{SHIFT}{TAB}")
$wshell.SendKeys("{ENTER}")

Start-Sleep -Milliseconds 500

# Run anyway
$wshell.SendKeys("{TAB}")
$wshell.SendKeys("{ENTER}")

Start-Sleep -Seconds 1

# Enter
$wshell.SendKeys("{ENTER}")

Start-Sleep -Milliseconds 500

# Tab x3
$wshell.SendKeys("{TAB}")
$wshell.SendKeys("{TAB}")
$wshell.SendKeys("{TAB}")

# Mũi tên lên
$wshell.SendKeys("{UP}")

# Enter
$wshell.SendKeys("{ENTER}")

# Chờ app cài đặt xuất hiện
Start-Sleep -Seconds 2

$wshell.SendKeys("%{F4}")

Start-Sleep -Seconds 1

$wshell.SendKeys("{ENTER}")