param(
    [Parameter(Mandatory = $true)]
    [string] $Tag
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if ($Tag -notmatch '^v') {
    $Tag = "v$Tag"
}
$version = $Tag.TrimStart('v')

$docs = Join-Path $root "docs"
New-Item -ItemType Directory -Force -Path $docs | Out-Null

$tagUrl = "https://gitverse.ru/ilexa/MTProSearch/releases/tag/$Tag"
$listUrl = "https://gitverse.ru/ilexa/MTProSearch/releases"
$pointerUrl = "https://gitverse.ru/ilexa/MTProSearch/content/main/docs/latest.md"
$githubLatest = "https://github.com/ilexahub/MTProSearch/releases/latest"

@"
# Текущая сборка: $version

На GitVerse **нет** постоянной ссылки вида GitHub ``/releases/latest``. Такая страница даёт 404, в публичном API метода ``releases/latest`` тоже нет (список релизов через API только с токеном).

## Какую ссылку давать

| Кому | Ссылка |
| --- | --- |
| Людям на GitVerse | $listUrl |
| Тем же, но с номером версии | $tagUrl |
| Постоянная памятка (этот файл) | $pointerUrl |
| Тем, у кого открывается GitHub | $githubLatest |

Список релизов GitVerse открывается без входа. Сверху всегда новая сборка, у неё бейдж **«Последний»**. Скачивайте файл ``MTProSearch.$version.apk``.

Прямую ссылку на файл с ``api/attachments/…`` не копируйте: UUID меняется при каждой загрузке APK.

Как поставить: [Как установить](kak-ustanovit.md)
"@ | Set-Content -Path (Join-Path $docs "latest.md") -Encoding utf8

@{
    version        = $version
    tag            = $Tag
    gitverse_page  = $tagUrl
    gitverse_list  = $listUrl
    github_latest  = $githubLatest
} | ConvertTo-Json | Set-Content -Path (Join-Path $docs "latest.json") -Encoding utf8

Write-Output "Updated docs/latest.md and docs/latest.json for $Tag"
