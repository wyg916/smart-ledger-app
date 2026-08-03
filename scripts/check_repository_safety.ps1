[CmdletBinding()]
param(
    [int64]$MaxFileBytes = 20MB
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Get-RepoRelativePath([string]$FullPath) {
    return $FullPath.Substring($repoRoot.Length).TrimStart([char[]]@('\', '/'))
}
Push-Location $repoRoot
try {
    $relativePaths = @(
        git -c core.quotepath=false ls-files --cached --others --exclude-standard |
            Where-Object { $_ -and $_ -notmatch '^(?:\.git/|build/|\.gradle/)' }
    )
    if ($LASTEXITCODE -ne 0) { throw "git ls-files failed." }

    $files = @(
        foreach ($relativePath in $relativePaths) {
            $fullPath = Join-Path $repoRoot $relativePath
            if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                Get-Item -LiteralPath $fullPath -Force
            }
        }
    )

    $forbiddenNamePattern = '(?i)(^\.env($|\.)|local\.properties$|\.(jks|keystore|p12|pfx|pem|key|mobileprovision|db|sqlite|sqlite3|apk|aab|apks|ipa|zip|log)$)'
    $forbidden = @($files | Where-Object { $_.Name -match $forbiddenNamePattern -and $_.Name -ne ".env.example" })
    $large = @($files | Where-Object { $_.Length -gt $MaxFileBytes })

    $textExtensions = @(
        ".md", ".txt", ".kt", ".kts", ".java", ".dart", ".py", ".ps1",
        ".json", ".yaml", ".yml", ".toml", ".xml", ".properties", ".gradle"
    )
    $secretPatterns = @(
        'AKIA[0-9A-Z]{16}',
        'AIza[0-9A-Za-z_-]{30,}',
        'gh[pousr]_[0-9A-Za-z_]{20,}',
        'sk-[0-9A-Za-z_-]{20,}',
        'Authorization\s*:\s*Bearer\s+[0-9A-Za-z_-]{20,}',
        'MOONSHOT_API_KEY\s*=\s*[0-9A-Za-z_-]{20,}',
        '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
    )
    $secretFindings = New-Object System.Collections.Generic.List[string]
    foreach ($file in $files) {
        if ($textExtensions -notcontains $file.Extension.ToLowerInvariant() -and $file.Name -ne ".env.example") {
            continue
        }
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) {
                $relative = Get-RepoRelativePath $file.FullName
                $secretFindings.Add("$relative matches $pattern")
            }
        }
    }

    if ($forbidden.Count -gt 0) {
        Write-Error ("Forbidden files found:`n" + (($forbidden.FullName | ForEach-Object { Get-RepoRelativePath $_ }) -join "`n"))
    }
    if ($large.Count -gt 0) {
        Write-Error ("Files larger than $MaxFileBytes bytes found:`n" + (($large | ForEach-Object { "{0} ({1} bytes)" -f (Get-RepoRelativePath $_.FullName), $_.Length }) -join "`n"))
    }
    if ($secretFindings.Count -gt 0) {
        Write-Error ("High-confidence secret patterns found:`n" + ($secretFindings -join "`n"))
    }

    if ($forbidden.Count -gt 0 -or $large.Count -gt 0 -or $secretFindings.Count -gt 0) {
        exit 1
    }
    Write-Host "Repository safety check passed: $($files.Count) candidate files scanned."
}
finally {
    Pop-Location
}
