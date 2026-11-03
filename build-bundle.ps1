# PowerShell Bundler – összefűzi a src/**/*.js ES modulokat a dist/bundle.js
# fájlba, hogy az index.html közvetlenül (file:// protokollról, dupla kattintással)
# is működjön bármilyen böngészőben, helyi webszerver nélkül.

$ErrorActionPreference = 'Stop'
$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcDir = Join-Path $rootDir 'src'
$distDir = Join-Path $rootDir 'dist'

if (-not (Test-Path $distDir)) {
  New-Item -ItemType Directory -Path $distDir | Out-Null
}

function Resolve-ModuleId([string]$fromDir, [string]$spec) {
  $combined = Join-Path $fromDir $spec
  $full = [IO.Path]::GetFullPath($combined)
  $rel = $full.Substring($srcDir.Length + 1).Replace('\', '/')
  return $rel
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('/* Automatikusan generált bundle a file:// alapú (dupla kattintásos) futtatáshoz. */')
[void]$sb.AppendLine('(function () {')
[void]$sb.AppendLine('  "use strict";')
[void]$sb.AppendLine('  const __factories = Object.create(null);')
[void]$sb.AppendLine('  const __cache = Object.create(null);')
[void]$sb.AppendLine('  function __define(id, factory) { __factories[id] = factory; }')
[void]$sb.AppendLine('  function __require(id) {')
[void]$sb.AppendLine('    if (__cache[id]) return __cache[id];')
[void]$sb.AppendLine('    const exports = Object.create(null);')
[void]$sb.AppendLine('    __cache[id] = exports;')
[void]$sb.AppendLine('    __factories[id](exports, __require);')
[void]$sb.AppendLine('    return exports;')
[void]$sb.AppendLine('  }')

$files = Get-ChildItem -Path $srcDir -Recurse -Filter *.js | Sort-Object FullName

foreach ($file in $files) {
  $modId = $file.FullName.Substring($srcDir.Length + 1).Replace('\', '/')
  $fileDir = Split-Path -Parent $file.FullName
  $code = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)

  # 1. import { ... } from '...';
  $code = [regex]::Replace($code, '(?m)^\s*import\s*\{([^}]+)\}\s*from\s*[''"]([^''"]+)[''"]\s*;?', {
    param($m)
    $names = $m.Groups[1].Value.Trim() -replace '\s+as\s+', ': '
    $targetId = Resolve-ModuleId $fileDir $m.Groups[2].Value
    return "const { $names } = __require('$targetId');"
  })

  # 2. export { ... };
  $code = [regex]::Replace($code, '(?m)^\s*export\s*\{([^}]+)\}\s*;?', {
    param($m)
    $names = $m.Groups[1].Value.Trim()
    return "Object.assign(__exports, { $names });"
  })

  # 3. export function / export const / export class
  $exported = [System.Collections.Generic.List[string]]::new()
  $code = [regex]::Replace($code, '(?m)^(\s*)export\s+(function|const|let|class)\s+([A-Za-z0-9_$]+)', {
    param($m)
    $exported.Add($m.Groups[3].Value)
    return "$($m.Groups[1].Value)$($m.Groups[2].Value) $($m.Groups[3].Value)"
  })

  [void]$sb.AppendLine("  __define('$modId', function (__exports, __require) {")
  [void]$sb.AppendLine($code)
  if ($exported.Count -gt 0) {
    $list = ($exported | Select-Object -Unique) -join ', '
    [void]$sb.AppendLine("    Object.assign(__exports, { $list });")
  }
  [void]$sb.AppendLine('  });')
}

[void]$sb.AppendLine('  __require("main.js");')
[void]$sb.AppendLine('})();')

$outPath = Join-Path $distDir 'bundle.js'
[IO.File]::WriteAllText($outPath, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
Write-Host "Bundle elkészült: $outPath"
