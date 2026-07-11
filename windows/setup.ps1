# setup.ps1 — Windows 側の初期セットアップスクリプト（管理者 PowerShell で実行する）

$WingetArgs = @(
    "--exact", "--silent", "--accept-source-agreements", "--accept-package-agreements"
)
winget source update
winget install --id 9WZDNCRFJ4MV @WingetArgs #Lenovo Vantage
winget install --id 9MVLWT5DMSKR @WingetArgs #Lenovo Pen Settings
winget install --id Tailscale.Tailscale @WingetArgs
winget install --id Git.Git @WingetArgs
winget install --id Google.Chrome @WingetArgs
# winget install --id Perplexity.Comet @WingetArgs → https://perplexity.sng.link/Bot2p/kkat?_smtype=3 でインストールする
winget install --id Brave.Brave @WingetArgs
winget install --id Google.ChromeRemoteDesktop @WingetArgs
winget install --id Obsidian.Obsidian @WingetArgs
winget install --id Bitwarden.Bitwarden @WingetArgs
winget install --id Google.QuickShare @WingetArgs
# winget install --id XPFFZHVGQWWLHB @WingetArgs → https://go.microsoft.com/fwlink/?linkid=2110341 でインストールする

# AdGuard Home を導入
$AdGuardDir = "$env:ProgramFiles\AdGuardHome"
if (-not (Test-Path $AdGuardDir)) {
    New-Item -ItemType Directory -Path $AdGuardDir -Force | Out-Null
    $AgTempDir = "$env:TEMP\AdGuardHomeTemp"
    New-Item -ItemType Directory -Path $AgTempDir -Force | Out-Null
    $AgReleaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest"
    $AgZipUrl = ($AgReleaseInfo.assets | Where-Object { $_.name -match "AdGuardHome_windows_amd64.zip" }).browser_download_url
    Invoke-WebRequest -Uri $AgZipUrl -OutFile "$AgTempDir\AdGuardHome.zip"
    Expand-Archive -Path "$AgTempDir\AdGuardHome.zip" -DestinationPath $AgTempDir -Force
    Copy-Item -Path "$AgTempDir\AdGuardHome\*" -Destination $AdGuardDir -Recurse -Force
    Start-Process -FilePath "$AdGuardDir\AdGuardHome.exe" -ArgumentList "-s install" -Wait -NoNewWindow
    Start-Process -FilePath "$AdGuardDir\AdGuardHome.exe" -ArgumentList "-s start" -Wait -NoNewWindow
    New-NetFirewallRule -DisplayName "AdGuard Home DNS UDP" -Direction Inbound -LocalPort 53 -Protocol UDP -Action Allow | Out-Null
    New-NetFirewallRule -DisplayName "AdGuard Home DNS TCP" -Direction Inbound -LocalPort 53 -Protocol TCP -Action Allow | Out-Null
    New-NetFirewallRule -DisplayName "AdGuard Home WebUI" -Direction Inbound -LocalPort 3000,80 -Protocol TCP -Action Allow | Out-Null
    Remove-Item -Path $AgTempDir -Recurse -Force
    # http://localhost:3000 にて初期設定を行う
    # Tailscale 管理画面の DNS / Nameservers / Global nameservers を Windows PC の Tailscale IP アドレスに設定（Override local DNS をオン）
}

# .gitconfig を配置
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sukenori/dotfiles/main/git/.gitconfig" -OutFile "$env:USERPROFILE\.gitconfig"
# GitHub への初回 push 時: Username=sukenori / Password=PAT (https://github.com/settings/tokens)"

# HackGen Console NF フォントを導入
$TempDir = "$env:TEMP\HackGenFont"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
$ReleaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/yuru7/HackGen/releases/latest"
$ZipUrl = ($ReleaseInfo.assets | Where-Object { $_.name -match "HackGen_NF_.*\.zip" }).browser_download_url
Invoke-WebRequest -Uri $ZipUrl -OutFile "$TempDir\HackGen_NF.zip"
Expand-Archive -Path "$TempDir\HackGen_NF.zip" -DestinationPath $TempDir -Force
foreach ($Font in (Get-ChildItem -Path $TempDir -Recurse -Filter "*.ttf")) {
    $dest = Join-Path "$env:windir\Fonts" $Font.Name
    if (-not (Test-Path $dest)) {
        Copy-Item -Path $Font.FullName -Destination "$env:windir\Fonts"
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $Font.Name -Value $Font.Name -PropertyType String -Force | Out-Null
    }
}
Remove-Item -Path $TempDir -Recurse -Force

# Windows Terminal の設定ファイルを配置
$TerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (-not (Test-Path $TerminalDir)) { New-Item -ItemType Directory -Force -Path $TerminalDir | Out-Null }
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sukenori/dotfiles/main/windows/settings.json" -OutFile "$TerminalDir\settings.json" -ErrorAction Stop
} catch {
    Write-Warning "Windows Terminal settings.json の取得に失敗しました。"
}

# WSL（Ubuntu）をインストール → 初回はリブート後に再実行
$UbuntuExists = (wsl -l -q 2>$null) -contains "Ubuntu"
if (-not $UbuntuExists) {
    wsl --install -d Ubuntu
    Write-Host "再起動後にこのスクリプトを再実行してください。"
    exit 0
}

# WSL 内の設定
wsl -- git config --global credential.helper store
$dotfilesExists = wsl -- sh -c "test -d ~/dotfiles && echo yes || echo no"
if ($dotfilesExists -ne "yes") {
    wsl -- git clone https://github.com/sukenori/dotfiles.git ~/dotfiles
} else {
    Write-Host "dotfiles は既に存在するためスキップします。"
}

# linux/setup.sh を実行
wsl -- bash ~/dotfiles/linux/setup.sh
