[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$xml = @'
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>HW-24353859</name>
	<SSIDConfig>
		<SSID>
			<name>HW-24353859</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>manual</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA2PSK</authentication>
				<encryption>AES</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
			<sharedKey>
				<keyType>passPhrase</keyType>
				<protected>false</protected>
				<keyMaterial>hiwonder</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
</WLANProfile>
'@
$xmlPath = "C:\Users\Public\HW-24353859.xml"
Set-Content -Path $xmlPath -Value $xml -Encoding ASCII
netsh wlan add profile filename=$xmlPath user=all
netsh wlan connect name="HW-24353859"
Start-Sleep -Seconds 6
Write-Output "=== WLAN status ==="
netsh wlan show interfaces
