# 1. SSHサーバーの起動
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# 2. 鍵の場所を変数に格納
$sourceKey = "$env:USERPROFILE\.ssh\authorized_keys"
$targetKey = "$env:ProgramData\ssh\administrators_authorized_keys"

# 3. Termuxから送られた鍵を、管理者専用のフォルダに移動
if (Test-Path $sourceKey) {
    Get-Content $sourceKey | Add-Content -Force $targetKey
    Remove-Item $sourceKey
}

# 4. 鍵ファイルの権限を厳格に設定（この処理が必須です）
icacls.exe $targetKey /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"

# 5. 設定を確実に反映するためにSSHサーバーを再起動
Restart-Service sshd
