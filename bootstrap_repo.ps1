param(
    [string]$SourcePath = (
        'E:\' + (-join ([char[]]@(0x79FB, 0x52A8, 0x7AEF, 0x5F00, 0x53D1))) + '\' +
        (-join ([char[]]@(0x8BB0, 0x8D26, 0x7EDF, 0x8BA1)))
    ),
    [string]$RepoPath = (
        'E:\' + (-join ([char[]]@(0x79FB, 0x52A8, 0x7AEF, 0x5F00, 0x53D1))) +
        '\smart-ledger-app'
    ),
    [string]$RepoUrl = "https://github.com/wyg916/smart-ledger-app.git"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SourcePath)) { throw "Legacy source directory not found: $SourcePath" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git for Windows was not found." }

if (-not (Test-Path $RepoPath)) {
    git clone $RepoUrl $RepoPath
    if ($LASTEXITCODE -ne 0) { throw "git clone failed." }
} else {
    Write-Host "Repository directory already exists; clone skipped." -ForegroundColor Yellow
}

$dirs = @(
    "apps\mobile", "services\api", "packages\contracts",
    "legacy\android-kotlin", "docs\00_requirements",
    "docs\01_baseline", "docs\02_architecture", "docs\03_delivery",
    "docs\04_operations", "infra\docker", "infra\reverse-proxy",
    "infra\scripts", "scripts", "tests\fixtures", ".github\workflows"
)
foreach ($dir in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $RepoPath $dir) | Out-Null }

$legacyPath = Join-Path $RepoPath "legacy\android-kotlin"
$excludeDirs = @(
    ".git", ".gradle", ".idea", ".tmp", "docs", "build", ".kotlin",
    "captures", ".externalNativeBuild", ".cxx"
)
$excludeFiles = @(
    "local.properties", "*.jks", "*.keystore", ".env", ".env.*",
    "*.db", "*.sqlite", "*.sqlite3", "*.log",
    "*.apk", "*.aab", "*.apks", "*.ipa", "*.zip", "*.docx", "*.pdf"
)
$xdArgs = @(); foreach ($d in $excludeDirs) { $xdArgs += @("/XD", $d) }
$xfArgs = @(); foreach ($f in $excludeFiles) { $xfArgs += @("/XF", $f) }

& robocopy $SourcePath $legacyPath /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 @xdArgs @xfArgs
if ($LASTEXITCODE -gt 7) { throw "robocopy failed with exit code $LASTEXITCODE" }

$inventory = Join-Path $RepoPath "docs\01_baseline\LOCAL_FILE_INVENTORY.txt"
Get-ChildItem $legacyPath -Recurse -File |
    ForEach-Object { $_.FullName.Substring($legacyPath.Length + 1) } |
    Sort-Object | Set-Content -Path $inventory -Encoding UTF8

Write-Host "Bootstrap completed. The script did not commit or push." -ForegroundColor Green
Write-Host "Place requirement documents in docs\00_requirements and inspect git status."
