Write-Output "=== [1] ssh.exe available? ==="
where.exe ssh
Write-Output "=== [2] generate Windows keypair (if missing) ==="
if (!(Test-Path "$env:USERPROFILE\.ssh\id_ed25519")) {
  ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519" -N '""' -q
  Write-Output "generated new key"
} else { Write-Output "key already exists" }
Write-Output "=== [3] Windows pubkey ==="
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
