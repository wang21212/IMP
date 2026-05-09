$skillsSrc = Join-Path $PSScriptRoot "..\windsurf\skills"
$skillsDst = Join-Path $env:USERPROFILE ".codeium\windsurf\skills"

if (-not (Test-Path $skillsDst)) {
    New-Item -ItemType Directory -Path $skillsDst | Out-Null
}

Get-ChildItem -Path $skillsSrc -Directory | ForEach-Object {
    $dst = Join-Path $skillsDst $_.Name
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    New-Item -ItemType Directory -Path $dst | Out-Null
    Copy-Item -Path (Join-Path $_.FullName "*") -Destination $dst -Recurse -Force
    Write-Host "Deployed: $($_.Name)"
}

Write-Host "Done. Restart Windsurf to pick up changes."
