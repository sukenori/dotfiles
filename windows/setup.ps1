# setup.ps1 — Windows 側の初期セットアップスクリプト（管理者 PowerShell で実行する）

# winget 共通オプション
$WingetArgs = "--exact --silent --accept-source-agreements --accept-package-agreements"

# 必要アプリを入れる
winget install --id 9WZDNCRFJ4MV $WingetArgs
winget install --id Microsoft.VisualStudioCode $WingetArgs
winget install --id Perplexity.Comet $WingetArgs
winget install --id Git.Git $WingetArgs
winget install --id Brave.Brave $WingetArgs
winget install --id Google.Chrome $WingetArgs
winget install --id Google.QuickShare $WingetArgs
winget install "Microsoft OneNote" $WingetArgs
winget install "Lenovo Vantage" $WingetArgs

# Windows Terminal の設定ファイルを配置する
$TerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$TerminalSettingsPath = "$TerminalDir\settings.json"
$GitHubSettingsUrl = "https://raw.githubusercontent.com/sukenori/dotfiles/main/windows/settings.json"

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

# VSCode 拡張を入れる
if (Get-Command code -ErrorAction SilentlyContinue) {
    code --install-extension asvetliakov.vscode-neovim
} else {
    Write-Host "code コマンドが見つからないため拡張機能インストールをスキップしました。"
}

# VSCode の共通設定を配置する
$VsCodeUserDir = "$env:APPDATA\Code\User"
$VsCodeSettingsPath = "$VsCodeUserDir\settings.json"
$DotfilesVsCodeSettings = Join-Path $PSScriptRoot "..\vscode\.config\Code\User\settings.json"

if (-not (Test-Path $VsCodeUserDir)) {
    New-Item -ItemType Directory -Force -Path $VsCodeUserDir | Out-Null
}

if (Test-Path $DotfilesVsCodeSettings) {
    Copy-Item -Path $DotfilesVsCodeSettings -Destination $VsCodeSettingsPath -Force
}

# WSL と Ubuntu を入れる（完了後に再起動が必要）
wsl --install -d Ubuntu
