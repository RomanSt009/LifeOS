[CmdletBinding()]
param(
  [string]$Version,
  [string]$ReleaseDirectory,
  [string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FullPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  return [System.IO.Path]::GetFullPath($Path)
}

function Assert-ChildPath {
  param(
    [Parameter(Mandatory = $true)][string]$Parent,
    [Parameter(Mandatory = $true)][string]$Child
  )

  $parentPath = Get-FullPath $Parent
  $childPath = Get-FullPath $Child
  $prefix = $parentPath.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  ) + [System.IO.Path]::DirectorySeparatorChar

  if (-not $childPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to modify a path outside the packaging directory: $childPath"
  }

  return $childPath
}

$repoRoot = Get-FullPath (Join-Path $PSScriptRoot '..')

if ([string]::IsNullOrWhiteSpace($Version)) {
  $pubspecPath = Join-Path $repoRoot 'pubspec.yaml'
  $versionLine = Select-String -LiteralPath $pubspecPath -Pattern '^version:\s*(\S+)\s*$' |
    Select-Object -First 1
  if ($null -eq $versionLine) {
    throw 'Unable to read version from pubspec.yaml.'
  }
  $Version = $versionLine.Matches[0].Groups[1].Value
}

if ($Version -notmatch '^[0-9A-Za-z][0-9A-Za-z.+-]*$') {
  throw "Version contains unsupported filename characters: $Version"
}

if ([string]::IsNullOrWhiteSpace($ReleaseDirectory)) {
  $releaseCandidates = @(
    (Join-Path $repoRoot 'build\windows\x64\runner\Release'),
    (Join-Path $repoRoot 'build\windows\runner\Release')
  )
  $ReleaseDirectory = $releaseCandidates |
    Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
    Select-Object -First 1
  if ([string]::IsNullOrWhiteSpace($ReleaseDirectory)) {
    throw "Windows Release output is missing. Run 'flutter build windows --release' first."
  }
}

$releasePath = Get-FullPath $ReleaseDirectory
if (-not (Test-Path -LiteralPath $releasePath -PathType Container)) {
  throw "Windows Release directory does not exist: $releasePath"
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $OutputDirectory = Join-Path $repoRoot 'build\distributions'
}
$outputPath = Get-FullPath $OutputDirectory
[System.IO.Directory]::CreateDirectory($outputPath) | Out-Null

$artifactName = "LifeOS-$Version-windows-x64.zip"
$artifactPath = Assert-ChildPath -Parent $outputPath -Child (Join-Path $outputPath $artifactName)
if (Test-Path -LiteralPath $artifactPath) {
  throw "Release artifact already exists: $artifactPath"
}

$stagingRoot = Assert-ChildPath -Parent $outputPath -Child (
  Join-Path $outputPath ('.lifeos-package-' + [System.Guid]::NewGuid().ToString('N'))
)
$bundlePath = Join-Path $stagingRoot 'LifeOS'
$artifactCreated = $false

try {
  [System.IO.Directory]::CreateDirectory($bundlePath) | Out-Null
  Copy-Item -Path (Join-Path $releasePath '*') -Destination $bundlePath -Recurse -Force

  $requiredPaths = @(
    'LifeOS.exe',
    'flutter_windows.dll',
    'data\icudtl.dat',
    'data\flutter_assets',
    'data\app.so'
  )
  foreach ($requiredPath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $bundlePath $requiredPath))) {
      throw "Release runtime is incomplete; missing: $requiredPath"
    }
  }

  $prohibited = Get-ChildItem -LiteralPath $bundlePath -Recurse -Force |
    Where-Object {
      $_.Name -eq '.obsidian' -or
      $_.Name -eq 'test' -or
      $_.Extension -in @('.db', '.sqlite', '.sqlite3', '.zip', '.bak') -or
      $_.Name -match '(?i)(api[_-]?key|secret|token)'
    }
  if ($prohibited) {
    $names = ($prohibited | ForEach-Object FullName) -join ', '
    throw "Release runtime contains prohibited data: $names"
  }

  Compress-Archive -LiteralPath $bundlePath -DestinationPath $artifactPath
  $artifactCreated = $true

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [System.IO.Compression.ZipFile]::OpenRead($artifactPath)
  try {
    $entries = @(
      $archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') }
    )
    foreach ($requiredEntry in @(
      'LifeOS/LifeOS.exe',
      'LifeOS/flutter_windows.dll',
      'LifeOS/data/icudtl.dat',
      'LifeOS/data/app.so'
    )) {
      if ($entries -notcontains $requiredEntry) {
        throw "ZIP validation failed; missing: $requiredEntry"
      }
    }
    $invalidEntry = $entries |
      Where-Object {
        $_ -notmatch '^LifeOS/' -or
        $_ -match '(?i)(^|/)(\.obsidian|test)(/|$)' -or
        $_ -match '(?i)\.(db|sqlite|sqlite3|bak)$' -or
        $_ -match '(?i)(api[_-]?key|secret|token)'
      } |
      Select-Object -First 1
    if ($null -ne $invalidEntry) {
      throw "ZIP validation found a prohibited entry: $invalidEntry"
    }
  } finally {
    $archive.Dispose()
  }

  Write-Output $artifactPath
} catch {
  $originalError = $_
  if ($artifactCreated -or (Test-Path -LiteralPath $artifactPath)) {
    try {
      Remove-Item -LiteralPath $artifactPath -Force
    } catch {
      Write-Warning "Could not remove incomplete artifact: $artifactPath"
    }
  }
  throw $originalError
} finally {
  if (Test-Path -LiteralPath $stagingRoot) {
    try {
      $safeStagingRoot = Assert-ChildPath -Parent $outputPath -Child $stagingRoot
      Remove-Item -LiteralPath $safeStagingRoot -Recurse -Force
    } catch {
      Write-Warning "Could not remove packaging staging directory: $stagingRoot"
    }
  }
}
