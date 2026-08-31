param(
    [string] $Tag,
    [string] $ApkPath = "",
    [string] $Notes = "",
    [string] $Owner = "ilexa",
    [string] $Repo = "MTProSearch"
)

$ErrorActionPreference = "Stop"

$token = $env:GITVERSE_TOKEN
if (-not $token) {
    $token = [Environment]::GetEnvironmentVariable("GITVERSE_TOKEN", "User")
}
if (-not $token) {
    throw "Set GITVERSE_TOKEN (user env or session). Token needs repository Write permission."
}

if (-not $Tag) {
    throw "Usage: publish-release-gitverse.ps1 -Tag v1.4.0 [-ApkPath path] [-Notes text]"
}
if ($Tag -notmatch '^v') {
    $Tag = "v$Tag"
}

if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $version = $Tag.TrimStart('v')
    $candidates = @(
        (Join-Path $PSScriptRoot "..\app\build\outputs\apk\release\MTProSearch.$version.apk"),
        (Join-Path $PSScriptRoot "..\.release-cache\MTProSearch.$version.apk")
    )
    $ApkPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $ApkPath -or -not (Test-Path $ApkPath)) {
    throw "APK not found for $Tag"
}

$apkName = [IO.Path]::GetFileName($ApkPath)
if ([string]::IsNullOrWhiteSpace($Notes)) {
    $Notes = "MTProSearch $Tag"
}

$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.gitverse.object+json;version=latest"
}

$release = $null
try {
    $release = Invoke-RestMethod -Method Get -Uri "https://api.gitverse.ru/repos/$Owner/$Repo/releases/tags/$Tag" -Headers $headers
} catch {
    $payload = @{
        tag_name         = $Tag
        name             = $Tag.TrimStart('v')
        body             = $Notes
        draft            = $false
        prerelease       = $false
        target_commitish = "main"
    } | ConvertTo-Json -Depth 4
    $release = Invoke-RestMethod -Method Post -Uri "https://api.gitverse.ru/repos/$Owner/$Repo/releases" -Headers ($headers + @{ "Content-Type" = "application/json" }) -Body $payload
}

$releaseId = $release.id
$uploadUrl = "https://api.gitverse.ru/repos/$Owner/$Repo/releases/$releaseId/assets?name=$apkName"
$curl = Get-Command curl.exe -ErrorAction Stop
& $curl.Source -sS -f -X POST `
    -H "Authorization: Bearer $token" `
    -H "Accept: application/vnd.gitverse.object+json;version=latest" `
    -F "attachment=@$ApkPath" `
    $uploadUrl | Out-Null

Write-Output "Uploaded $apkName to https://gitverse.ru/$Owner/$Repo/releases/tag/$Tag"
