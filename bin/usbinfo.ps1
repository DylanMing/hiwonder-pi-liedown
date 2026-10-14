[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$devs = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'USB\*' }
foreach ($d in $devs) {
  $desc = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_BusReportedDeviceDesc' -ErrorAction SilentlyContinue).Data
  Write-Output ("--- " + $d.InstanceId)
  Write-Output ("    Class: " + $d.Class + "  Status: " + $d.Status + "  BusDesc: " + $desc)
}
