# 鍵の場所を変数に格納
$sourceKey = "$env:USERPROFILE\.ssh\authorized_keys"
$targetKey = "$env:ProgramData\ssh\administrators_authorized_keys"

# Termux から送られた鍵を、管理者専用のフォルダに移動
if (Test-Path $sourceKey) {
    Get-Content $sourceKey | Add-Content -Force $targetKey
    Remove-Item $sourceKey
}

# 設定を確実に反映するために SSH サーバーを再起動
Restart-Service sshd
