# Purpose: Sets timezone to UTC, sets hostname.
# Source: https://github.com/StefanScherer/adfs2

$ProfilePath = "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1"
$box = Get-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName -Name "ComputerName"
$box = $box.ComputerName.ToString().ToLower()

Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Setting timezone to UTC..."
c:\windows\system32\tzutil.exe /s "UTC"

Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Checking if Windows evaluation is expiring soon or expired..."
. c:\vagrant\scripts\fix-windows-expiration.ps1

If (!(Test-Path $ProfilePath)) {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Disabling the Invoke-WebRequest download progress bar globally for speed improvements." 
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) See https://github.com/PowerShell/PowerShell/issues/2138 for more info"
  New-Item -Path $ProfilePath | Out-Null
  If (!(Get-Content $Profilepath| % { $_ -match "SilentlyContinue" } )) {
    Add-Content -Path $ProfilePath -Value "$ProgressPreference = 'SilentlyContinue'"
  }
}

# Ping DetectionLab server for usage statistics
Try {
  curl -userAgent "DetectionLab-$box" "https://ping.detectionlab.network/$box" -UseBasicParsing | out-null
} Catch {
  Write-Host "Unable to connect to ping.detectionlab.network"
}

Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Disabling IPv6 on all network adatpers..."
Get-NetAdapterBinding -ComponentID ms_tcpip6 | ForEach-Object {Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6}
Get-NetAdapterBinding -ComponentID ms_tcpip6 
# https://support.microsoft.com/en-gb/help/929852/guidance-for-configuring-ipv6-in-windows-for-advanced-users
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 255 /f

Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Current domain is set to 'workgroup'."

if (!(Test-Path 'c:\Program Files\sysinternals\bginfo.exe')) {
  Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Installing bginfo..."
  . c:\vagrant\scripts\install-bginfo.ps1
  # Set background to be "fitted" instead of "tiled"
  Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'
  Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '6'
  # Set Task Manager prefs
  reg import "c:\vagrant\resources\windows\TaskManager.reg" 2>&1 | out-null
}
