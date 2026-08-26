# IMP memory 迁移脚本：.windsurf/memory/ → .imp/memory/（跨工具统一状态根）
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File migrate-memory.ps1 -Project C:\path\to\project
# 说明: 复制旧状态根的全部文件到新状态根 .imp/memory/，不删除原文件；已存在 .imp/memory/ 时跳过同名文件。
param(
    [Parameter(Mandatory = $true)][string]$Project
)

$ErrorActionPreference = 'Stop'
$oldRoot = Join-Path $Project '.windsurf\memory'
$newRoot = Join-Path $Project '.imp\memory'

if (-not (Test-Path $oldRoot)) {
    Write-Host "no old state root: $oldRoot (skip)"
    exit 0
}
if (-not (Test-Path $newRoot)) {
    New-Item -ItemType Directory -Path $newRoot | Out-Null
}

$copied = 0
Get-ChildItem -Path $oldRoot -File -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($oldRoot.Length).TrimStart('\')
    $dst = Join-Path $newRoot $rel
    if (-not (Test-Path $dst)) {
        $dstDir = Split-Path -Parent $dst
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir | Out-Null }
        Copy-Item $_.FullName -Destination $dst
        $copied++
    }
}
Write-Host "migrated $copied file(s) from $oldRoot -> $newRoot"
if ($copied -eq 0) { Write-Host '(nothing new copied; .imp/memory/ already up to date)' }
