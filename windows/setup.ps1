# 各種アプリケーションのインストール
winget install --id 9WZDNCRFJ4MV --exact --silent --accept-source-agreements --accept-package-agreements
winget install --id Perplexity.Comet  --exact --silent --accept-source-agreements --accept-package-agreements
winget install --id Git.Git  --exact --silent --accept-source-agreements --accept-package-agreements
winget install --id Brave.Brave  --exact --silent --accept-source-agreements --accept-package-agreements
winget install --id Google.QuickShare  --exact --silent --accept-source-agreements --accept-package-agreements
winget install "Microsoft OneNote"  --exact --silent --accept-source-agreements --accept-package-agreements
winget install --id 9MVLWT5DMSKR  --exact --silent --accept-source-agreements --accept-package-agreements
winget install --id Tailscale.Tailscale  --exact --silent --accept-source-agreements --accept-package-agreements

# Windows Terminalの設定ファイルの保存先パスを定義
$TerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$TerminalSettingsPath = "$TerminalDir\settings.json"

$GitHubSettingsUrl = "https://raw.githubusercontent.com/sukenori/dotfiles/main/windows/settings.json"

# フォルダが存在しない場合は作成
if (-not (Test-Path $TerminalDir)) {
    New-Item -ItemType Directory -Force -Path $TerminalDir
}

# GitHubから設定ファイルをダウンロードして所定の場所に配置（上書き）
Invoke-WebRequest -Uri $GitHubSettingsUrl -OutFile $TerminalSettingsPath

# --- HackGen Console NF フォントの自動インストール ---

# 1. 一時的な作業フォルダを作成
$TempDir = "$env:TEMP\HackGenFont"
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

# 2. GitHubのAPIを叩いて、最新版のリリース情報からZIPのURLを取得
$ReleaseUrl = "https://api.github.com/repos/yuru7/HackGen/releases/latest"
$ReleaseInfo = Invoke-RestMethod -Uri $ReleaseUrl
$ZipUrl = ($ReleaseInfo.assets | Where-Object { $_.name -match "HackGen_NF_.*\.zip" }).browser_download_url

# 3. ZIPファイルをダウンロードして解凍
$ZipPath = "$TempDir\HackGen_NF.zip"
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

# 4. 解凍したフォルダの中から、必要なttfファイルをWindowsのFontsフォルダにコピーしてレジストリに登録
$FontFiles = Get-ChildItem -Path $TempDir -Recurse -Filter "*.ttf"
$FontsFolder = "$env:windir\Fonts"

foreach ($Font in $FontFiles) {
    $DestinationPath = Join-Path -Path $FontsFolder -ChildPath $Font.Name
    # まだインストールされていなければインストール
    if (-not (Test-Path $DestinationPath)) {
        Copy-Item -Path $Font.FullName -Destination $FontsFolder
        # Windowsにフォントを認識させるためのレジストリ登録
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $Font.Name -Value $Font.Name -PropertyType String -Force | Out-Null
    }
}

# 5. 後片付け（一時フォルダの削除）
Remove-Item -Path $TempDir -Recurse -Force

# 最後にWSLとUbuntuをインストール（※この後PCの再起動が必要になります）
wsl --install -d Ubuntu

