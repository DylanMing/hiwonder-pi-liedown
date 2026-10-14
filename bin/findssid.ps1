[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$found = @()
foreach ($root in 'HKLM:\SYSTEM\CurrentControlSet\Services\icssvc','HKLM:\SOFTWARE\Microsoft\WlanSvc','HKLM:\SYSTEM\CurrentControlSet\Control\Network\Hotspot') {
  if (Test-Path $root) {
    Get-ChildItem $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      $k = $_
      $k.GetValueNames() | ForEach-Object {
        $v = $k.GetValue($_)
        if ($v -is [string] -and $v.Length -gt 3 -and $v.Length -lt 40) { if ($v -match '^[A-Za-z0-9\-_\.]+$') { $script:found += ($k.Name + "  ::  " + $_ + " = " + $v) } }
      }
    }
  }
}
$found | Where-Object { $_ -notmatch 'System|CurrentControlSet|ControlSet|Parameters|Config|ServiceDll|ImagePath|DisplayName|ObjectName|Description|DependOnService|ErrorControl|Start|Type|RequiredPrivileges|ServiceSidType' } | Select-Object -First 25
Write-Output "=== computer name (default hotspot SSID candidate) ==="
$env:COMPUTERNAME
