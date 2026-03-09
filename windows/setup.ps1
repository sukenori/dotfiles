# ===========================================================================
# setup.ps1 — Windows 側の初期セットアップスクリプト（PowerShell で実行）
#
# 実行順序:
#   1. このスクリプトを管理者権限の PowerShell で実行する
#   2. PC を再起動する（WSL のインストール完了に必要）
#   3. WSL の Ubuntu を起動し、dotfiles/linux/setup.sh を実行する
#
# このスクリプトが行うこと:
#   - winget で必要なアプリケーションをインストールする
#   - Windows Terminal の設定ファイルを GitHub から取得して配置する
#   - HackGen Console NF フォントをインストールする
#   - WSL と Ubuntu をインストールする
# ===========================================================================

# ---------------------------------------------------------------------------
# 1. アプリケーションのインストール（winget を使用）
# ---------------------------------------------------------------------------
$WingetArgs = "--exact --silent --accept-source-agreements --accept-package-agreements"

# Windows Terminal
winget install --id 9WZDNCRFJ4MV $WingetArgs
# Perplexity（AI 検索）
winget install --id Perplexity.Comet $WingetArgs
# Git for Windows（WSL から Credential Manager を呼ぶために必要）
winget install --id Git.Git $WingetArgs
# Brave ブラウザ
winget install --id Brave.Brave $WingetArgs
# Google Quick Share（ファイル共有）
winget install --id Google.QuickShare $WingetArgs
# Microsoft OneNote
winget install "Microsoft OneNote" $WingetArgs
# Copilot（Windows 版）
winget install --id 9MVLWT5DMSKR $WingetArgs
# Tailscale（VPN）
winget install --id Tailscale.Tailscale $WingetArgs

# ---------------------------------------------------------------------------
# 2. Windows Terminal の設定ファイルを配置する
# ---------------------------------------------------------------------------
$TerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$TerminalSettingsPath = "$TerminalDir\settings.json"
$GitHubSettingsUrl = "https://raw.githubusercontent.com/sukenori/dotfiles/main/windows/settings.json"

if (-not (Test-Path $TerminalDir)) {
    New-Item -ItemType Directory -Force -Path $TerminalDir
}

# GitHub から最新の設定ファイルをダウンロードして上書き配置する
Invoke-WebRequest -Uri $GitHubSettingsUrl -OutFile $TerminalSettingsPath

# ---------------------------------------------------------------------------
# 3. HackGen Console NF フォントのインストール
#    Neovim / ターミナルでアイコンや記号を正しく表示するために必要
# ---------------------------------------------------------------------------

# 一時フォルダを作成
$TempDir = "$env:TEMP\HackGenFont"
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

# GitHub API で最新リリースの ZIP ファイルの URL を取得
$ReleaseUrl = "https://api.github.com/repos/yuru7/HackGen/releases/latest"
$ReleaseInfo = Invoke-RestMethod -Uri $ReleaseUrl
$ZipUrl = ($ReleaseInfo.assets | Where-Object { $_.name -match "HackGen_NF_.*\.zip" }).browser_download_url

# ZIP をダウンロードして解凍
$ZipPath = "$TempDir\HackGen_NF.zip"
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

# ttf ファイルを Fonts フォルダにコピーし、レジストリに登録する
$FontFiles = Get-ChildItem -Path $TempDir -Recurse -Filter "*.ttf"
$FontsFolder = "$env:windir\Fonts"

foreach ($Font in $FontFiles) {
    $DestinationPath = Join-Path -Path $FontsFolder -ChildPath $Font.Name
    if (-not (Test-Path $DestinationPath)) {
        Copy-Item -Path $Font.FullName -Destination $FontsFolder
        # Windows がフォントを認識するようにレジストリに登録する
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $Font.Name -Value $Font.Name -PropertyType String -Force | Out-Null
    }
}

# 一時フォルダを削除
Remove-Item -Path $TempDir -Recurse -Force

# ---------------------------------------------------------------------------
# 4. WSL と Ubuntu のインストール（※完了後に PC の再起動が必要）
# ---------------------------------------------------------------------------
wsl --install -d Ubuntu
