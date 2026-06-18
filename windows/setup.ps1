# setup.ps1 — Windows 側の初期セットアップスクリプト（管理者 PowerShell で実行する）

# winget 共通オプション
$WingetArgs = @(
    "--exact",
    "--silent",
    "--accept-source-agreements",
    "--accept-package-agreements"
)
# 必要アプリを入れる
winget source update 
winget install --id 9WZDNCRFJ4MV @WingetArgs #Lenobo Vantage
winget install --id 9MVLWT5DMSKR @WingetArgs #Lenovo Pen Settings
winget install --id Tailscale.Tailscale @WingetArgs
winget install --id Git.Git @WingetArgs
winget install --id Google.Chrome @WingetArgs
# winget install --id Perplexity.Comet @WingetArgs Comet は winget 経由だとインストーラーが落ちるので、https://perplexity.sng.link/Bot2p/kkat?_smtype=3 でインストールする
winget install --id Brave.Brave @WingetArgs
winget install --id Google.ChromeRemoteDesktop @WingetArgs
winget install --id Obsidian.Obsidian @WingetArgs
winget install --id Bitwarden.Bitwarden @WingetArgs
winget install --id Google.QuickShare @WingetArgs
# winget install --id XPFFZHVGQWWLHB @WingetArgs #OneNote はフランス語版がインストールされてしまうので、https://go.microsoft.com/fwlink/?linkid=2110341 を用いてインストールする

# AdGuard Home を導入
$AdGuardDir = "$env:ProgramFiles\AdGuardHome"
if (-not (Test-Path $AdGuardDir)) {
    New-Item -ItemType Directory -Path $AdGuardDir -Force | Out-Null
    
    $AgTempDir = "$env:TEMP\AdGuardHomeTemp"
    if (-not (Test-Path $AgTempDir)) { New-Item -ItemType Directory -Path $AgTempDir | Out-Null }
    
    # GitHub の最新リリースから Windows 64bit 用 ZIP ファイルを取得
    $AgReleaseUrl = "https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest"
    $AgReleaseInfo = Invoke-RestMethod -Uri $AgReleaseUrl
    $AgZipUrl = ($AgReleaseInfo.assets | Where-Object { $_.name -match "AdGuardHome_windows_amd64.zip" }).browser_download_url
    
    $AgZipPath = "$AgTempDir\AdGuardHome.zip"
    Invoke-WebRequest -Uri $AgZipUrl -OutFile $AgZipPath
    Expand-Archive -Path $AgZipPath -DestinationPath $AgTempDir -Force
    
    # 解凍したファイルを Program Files のフォルダにコピー
    Copy-Item -Path "$AgTempDir\AdGuardHome\*" -Destination $AdGuardDir -Recurse -Force
    
    # Windows のバックグラウンドサービスとしてインストール、起動
    Start-Process -FilePath "$AdGuardDir\AdGuardHome.exe" -ArgumentList "-s install" -Wait -NoNewWindow
    Start-Process -FilePath "$AdGuardDir\AdGuardHome.exe" -ArgumentList "-s start" -Wait -NoNewWindow
    
    # Tailscaleなど外部から DNS と管理画面を使えるようにファイアウォールを開放する
    New-NetFirewallRule -DisplayName "AdGuard Home DNS UDP" -Direction Inbound -LocalPort 53 -Protocol UDP -Action Allow | Out-Null
    New-NetFirewallRule -DisplayName "AdGuard Home DNS TCP" -Direction Inbound -LocalPort 53 -Protocol TCP -Action Allow | Out-Null
    New-NetFirewallRule -DisplayName "AdGuard Home WebUI" -Direction Inbound -LocalPort 3000,80 -Protocol TCP -Action Allow | Out-Null
    
    # 一時フォルダを削除
    Remove-Item -Path $AgTempDir -Recurse -Force
    
# Windows 上のブラウザで http://localhost:3000 にアクセスし、初期設定（管理者ユーザー名とパスワードの作成）を行う
# ブラウザで Tailscale の管理画面を開き、DNS 設定の Global nameservers に、Windows マシンの Tailscale IP アドレスを追加して Override local DNS をオンにする
}

# Windows が外部からの SSH 接続を受け入れられるようにする
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Where-Object State -ne 'Installed' | Add-WindowsCapability -Online
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# SSH 管理者用鍵ファイルの枠組み作成と権限設定（スマホからの安全な接続用）
$targetDir = "$env:ProgramData\ssh"
$targetKey = "$targetDir\administrators_authorized_keys"
if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
if (-not (Test-Path $targetKey)) { New-Item -ItemType File -Path $targetKey -Force | Out-Null }
icacls.exe $targetKey /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
Restart-Service sshd

# .gitconfig を配置する
$GitConfigSrc = "https://raw.githubusercontent.com/sukenori/dotfiles/main/git/.gitconfig"
$GitConfigDest = "$env:USERPROFILE\.gitconfig"
Invoke-WebRequest -Uri $GitConfigSrc -OutFile $GitConfigDest

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

# Windows Terminal の設定ファイルを配置する
$TerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$TerminalSettingsPath = "$TerminalDir\settings.json"
$GitHubSettingsUrls = "https://raw.githubusercontent.com/sukenori/dotfiles/main/windows/settings.json"
if (-not (Test-Path $TerminalDir)) {
    New-Item -ItemType Directory -Force -Path $TerminalDir
}

# settings.json → -UseBasicParsing を追加（プロキシ・TLS問題を回避）
Invoke-WebRequest -Uri $GitHubSettingsUrls -OutFile $TerminalSettingsPath -UseBasicParsing -ErrorAction Stop

# git clone → 既存チェックを追加
$dotfilesPath = wsl -- echo '$HOME/dotfiles'
$exists = wsl -- test -d '$HOME/dotfiles' "&&" echo "yes"
if ($exists -ne "yes") {
    wsl -- git clone https://github.com/sukenori/dotfiles.git '~/dotfiles'
} else {
    Write-Host "dotfiles は既に存在するためスキップします。"
}

# WSL内で git の credential.helper を store に設定
wsl -- git config --global credential.helper store

# WSL内で dotfiles を HTTPS でクローン
wsl -- git clone https://github.com/sukenori/dotfiles.git ~/dotfiles

# 案内メッセージ（初回push時にPATを入力するよう促す）
Write-Host "GitHubへの初回push時にPATの入力が必要です："
Write-Host "https://github.com/settings/tokens"
Write-Host "（scopes: repo にチェック）"

# WSL で Ubuntu をセットアップ
$UbuntuExists = (wsl -l -q 2>$null) -contains "Ubuntu"
if (-not $UbuntuExists) {
    wsl --install -d Ubuntu
}
else {
    Write-Host "Ubuntu は既にインストール済みのためスキップします。"
}
