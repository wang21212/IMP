$src = Join-Path $PSScriptRoot "..\windsurf\global_rules.md"
$memoriesDst = Join-Path $env:USERPROFILE ".codeium\windsurf\memories\global_rules.md"
$workflowsDir = Join-Path $env:USERPROFILE ".codeium\windsurf\global_workflows"
$workflowsDst = Join-Path $workflowsDir "imp-globalrule.md"

$newContent = Get-Content $src -Raw -Encoding UTF8
$marker = "# IMP"

# --- 1. upsert into memories/global_rules.md ---
if (Test-Path $memoriesDst) {
    $existing = Get-Content $memoriesDst -Raw -Encoding UTF8
    $idx = $existing.IndexOf($marker)
    if ($idx -ge 0) {
        # replace from marker to end
        $before = $existing.Substring(0, $idx).TrimEnd()
        if ($before.Length -gt 0) {
            $merged = $before + "`n`n" + $newContent.TrimStart()
        } else {
            $merged = $newContent
        }
    } else {
        # append
        $merged = $existing.TrimEnd() + "`n`n" + $newContent.TrimStart()
    }
    [System.IO.File]::WriteAllText($memoriesDst, $merged, [System.Text.Encoding]::UTF8)
    Write-Host "Updated: memories/global_rules.md (IMP section upserted)"
} else {
    [System.IO.File]::WriteAllText($memoriesDst, $newContent, [System.Text.Encoding]::UTF8)
    Write-Host "Created: memories/global_rules.md"
}

# --- 2. write global_workflows/imp-globalrule.md ---
if (-not (Test-Path $workflowsDir)) {
    New-Item -ItemType Directory -Path $workflowsDir | Out-Null
}
[System.IO.File]::WriteAllText($workflowsDst, $newContent, [System.Text.Encoding]::UTF8)
Write-Host "Updated: global_workflows/imp-globalrule.md"
