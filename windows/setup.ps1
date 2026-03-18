# setup.ps1 — Windows 側の初期セットアップスクリプト（管理者 PowerShell で実行する）

# winget 共通オプション
$WingetArgs = "--exact --silent --accept-source-agreements --accept-package-agreements"
# 必要アプリを入れる
winget install --id 9WZDNCRFJ4MV $WingetArgs #Lenobo Vantage
winget install --id 9MVLWT5DMSKR $WingetArgs #Lenovo Pen Settings
winget install --id Git.Git $WingetArgs
winget install --id Google.Chrome $WingetArgs
winget install --id Perplexity.Comet $WingetArgs
winget install --id Brave.Brave $WingetArgs
winget install --id XPFFZHVGQWWLHB $WingetArgs #OneNote
winget install --id Tailscale.Tailscale $WingetArgs
winget install --id Google.QuickShare $WingetArgs

# Windows が外部からの SSH 接続を受け入れられるようにする
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Where-Object State -ne 'Installed' | Add-WindowsCapability -Online
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Windows Terminal の設定ファイルを配置する
$TerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$TerminalSettingsPath = "$TerminalDir\settings.json"
$GitHubSettingsUrl = "https://raw.githubusercontent.com/sukenori/dotfiles/windows/settings.json"
if (-not (Test-Path $TerminalDir)) {
    New-Item -ItemType Directory -Force -Path $TerminalDir
}
# GitHub から最新設定を取得して上書きする
Invoke-WebRequest -Uri $GitHubSettingsUrl -OutFile $TerminalSettingsPath

# HackGen Console NF フォントを入れる
$TempDir = "$env:TEMP\HackGenFont"
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }
# 最新リリースから ZIP URL を取得する
$ReleaseUrl = "https://api.github.com/repos/yuru7/HackGen/releases/latest"
$ReleaseInfo = Invoke-RestMethod -Uri $ReleaseUrl
$ZipUrl = ($ReleaseInfo.assets | Where-Object { $_.name -match "HackGen_NF_.*\.zip" }).browser_download_url
# ZIP をダウンロードして解凍する
$ZipPath = "$TempDir\HackGen_NF.zip"
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force
# ttf ファイルを Fonts フォルダへコピーしてレジストリ登録する
$FontFiles = Get-ChildItem -Path $TempDir -Recurse -Filter "*.ttf"
$FontsFolder = "$env:windir\Fonts"
foreach ($Font in $FontFiles) {
    $DestinationPath = Join-Path -Path $FontsFolder -ChildPath $Font.Name
    if (-not (Test-Path $DestinationPath)) {
        Copy-Item -Path $Font.FullName -Destination $FontsFolder
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $Font.Name -Value $Font.Name -PropertyType String -Force | Out-Null
    }
}
# 一時フォルダを削除する
Remove-Item -Path $TempDir -Recurse -Force

# WSL で Ubuntu をセットアップ
wsl --install -d Ubuntu
