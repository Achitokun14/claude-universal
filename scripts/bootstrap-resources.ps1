#!/usr/bin/env pwsh
# One-shot: mines ~/.claude/projects/*/*.jsonl for URLs, packages, GitHub repos,
# and seeds ~/Desktop/ACTIVITIES/useful-resources.md with deduplicated findings.
#
# Delegates heavy lifting to python3 for byte-identical parity with the bash twin.
# Falls back to a pure-pwsh miner if python3 is missing (Windows without Python).

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$ResourcesFile = Join-Path $HOME 'Desktop/ACTIVITIES/useful-resources.md'
$SessionsDir   = Join-Path $HOME '.claude/projects'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ResourcesFile) | Out-Null

if (-not (Test-Path $SessionsDir)) {
    Write-Host "no sessions at $SessionsDir"
    exit 0
}

Write-Host "▸ Mining session logs from $SessionsDir ..."
$fileCount = (Get-ChildItem -Path $SessionsDir -Recurse -File -Filter '*.jsonl' -ErrorAction SilentlyContinue).Count
Write-Host "  Found $fileCount session files"

$today = (Get-Date).ToString('yyyy-MM-dd')
$header = @"
# Useful Resources — Auto-collected

Auto-maintained by ``track-resources.sh`` hook. Bootstrapped from all historical Claude Code sessions on this machine on $today.

Each row is a URL, package name, or GitHub repo mentioned in some past tool call, deduplicated. The hook appends new entries as you work.

| Date | Source | Category | Resource | Context |
|---|---|---|---|---|
"@
Set-Content -Path $ResourcesFile -Value $header -Encoding UTF8

$py = $null
foreach ($cand in 'python3','python') {
    if (Get-Command $cand -ErrorAction SilentlyContinue) { $py = $cand; break }
}

if ($py) {
    # Delegate to Python — produces output identical to the bash twin.
    $script = @'
import sys, os, re, json
from collections import OrderedDict

sessions_dir, out_path = sys.argv[1:3]

url_re    = re.compile(r'https?://[^\s\)"\'<>\\`]+')
npm_re    = re.compile(r'(?:npx?|pnpm|bun|yarn)\s+(?:-y\s+|install\s+|add\s+|run\s+|exec\s+)?(@?[\w\-./]+)')
pip_re    = re.compile(r'(?:pip|pipx|uv|uvx)\s+(?:install\s+|run\s+|tool\s+)?([\w\-.]+)')
cargo_re  = re.compile(r'cargo\s+install\s+([\w\-]+)')
brew_re   = re.compile(r'brew\s+install\s+([\w\-./]+)')
apt_re    = re.compile(r'apt(?:-get)?\s+install\s+(?:-y\s+)?([\w\-]+)')
go_re     = re.compile(r'go\s+install\s+([\w\-./@]+)')
gh_repo_re= re.compile(r'github\.com/([\w\-]+/[\w\-.]+)')

NOISE_URL_SUBS = ['localhost','127.0.0.1','0.0.0.0','example.com','test.com','/tmp/','file:///']
NOISE_PKGS = {'-g','-y','-D','--','install','add','run','-','&','|','\\'}

resources = OrderedDict()
def add(cat, resource, context):
    k = (cat, resource)
    if k in resources: return
    if not resource or len(resource) < 4 or len(resource) > 200: return
    if resource.strip() in NOISE_PKGS: return
    resources[k] = context[:60]

files = []
for root, _, fnames in os.walk(sessions_dir):
    for f in fnames:
        if f.endswith('.jsonl'):
            files.append(os.path.join(root, f))

for fp in files:
    proj = os.path.basename(os.path.dirname(fp)).replace('-home-taran-','').replace('-','/')
    try:
        with open(fp, errors='ignore') as f:
            for line in f:
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                haystack = json.dumps(rec)[:50000]
                for m in url_re.findall(haystack):
                    m = m.rstrip('.,);:\\"\'')
                    if any(bad in m for bad in NOISE_URL_SUBS): continue
                    add('url', m, proj)
                for m in npm_re.findall(haystack):   add('npm',         m, proj)
                for m in pip_re.findall(haystack):   add('pypi',        m, proj)
                for m in cargo_re.findall(haystack): add('cargo',       m, proj)
                for m in brew_re.findall(haystack):  add('brew',        m, proj)
                for m in apt_re.findall(haystack):   add('apt',         m, proj)
                for m in go_re.findall(haystack):    add('go',          m, proj)
                for m in gh_repo_re.findall(haystack):add('github-repo', m, proj)
    except Exception:
        continue

print(f"  Found {len(resources)} unique resources", file=sys.stderr)

import datetime
today = datetime.date.today().isoformat()
with open(out_path, 'a') as out:
    for (cat, resource), proj in resources.items():
        res_esc  = resource.replace('|', '\\|')
        proj_esc = (proj or '').replace('|', '\\|')[:30]
        out.write(f"| {today} | {proj_esc} | {cat} | {res_esc} | historical |\n")
'@

    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("bootstrap-" + [guid]::NewGuid().ToString('N') + '.py')
    Set-Content -Path $tmp -Value $script -Encoding UTF8
    try {
        & $py $tmp $SessionsDir $ResourcesFile
    } finally {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    }
}
else {
    Write-Host '⚠ python3 not found — falling back to native pwsh miner (slightly different output).'

    # Pure-pwsh fallback for Windows without Python
    $reUrl    = [regex]'https?://[^\s\)"''<>\\`]+'
    $reNpm    = [regex]'(?:npx?|pnpm|bun|yarn)\s+(?:-y\s+|install\s+|add\s+|run\s+|exec\s+)?(@?[\w\-./]+)'
    $rePip    = [regex]'(?:pip|pipx|uv|uvx)\s+(?:install\s+|run\s+|tool\s+)?([\w\-.]+)'
    $reCargo  = [regex]'cargo\s+install\s+([\w\-]+)'
    $reBrew   = [regex]'brew\s+install\s+([\w\-./]+)'
    $reApt    = [regex]'apt(?:-get)?\s+install\s+(?:-y\s+)?([\w\-]+)'
    $reGo     = [regex]'go\s+install\s+([\w\-./@]+)'
    $reGh     = [regex]'github\.com/([\w\-]+/[\w\-.]+)'

    $noiseUrlSubs = @('localhost','127.0.0.1','0.0.0.0','example.com','test.com','/tmp/','file:///')
    $noisePkgs    = @('-g','-y','-D','--','install','add','run','-','&','|','\')
    $trimChars    = '.,);:"''\'.ToCharArray()
    $resources    = [ordered]@{}

    function Add-Res([string]$Cat, [string]$Res, [string]$Ctx) {
        if (-not $Res) { return }
        $trim = $Res.TrimEnd($script:trimChars)
        if (-not $trim -or $trim.Length -lt 4 -or $trim.Length -gt 200) { return }
        if ($script:noisePkgs -contains $trim.Trim()) { return }
        $k = "$Cat|$trim"
        if ($script:resources.Contains($k)) { return }
        $ctxShort = if ($Ctx) { $Ctx.Substring(0, [Math]::Min(60, $Ctx.Length)) } else { '' }
        $script:resources[$k] = $ctxShort
    }

    $files = Get-ChildItem -Path $SessionsDir -Recurse -File -Filter '*.jsonl' -ErrorAction SilentlyContinue
    foreach ($fp in $files) {
        $proj = ($fp.Directory.Name) -replace '^-home-taran-','' -replace '-','/'
        try {
            $reader = [IO.StreamReader]::new($fp.FullName)
            try {
                while (-not $reader.EndOfStream) {
                    $line = $reader.ReadLine()
                    if (-not $line) { continue }
                    $hay = if ($line.Length -gt 50000) { $line.Substring(0, 50000) } else { $line }
                    foreach ($m in $reUrl.Matches($hay)) {
                        $u = $m.Value.TrimEnd($trimChars)
                        $bad = $false
                        foreach ($b in $noiseUrlSubs) { if ($u.Contains($b)) { $bad = $true; break } }
                        if (-not $bad) { Add-Res 'url' $u $proj }
                    }
                    foreach ($m in $reNpm.Matches($hay))   { Add-Res 'npm'         $m.Groups[1].Value $proj }
                    foreach ($m in $rePip.Matches($hay))   { Add-Res 'pypi'        $m.Groups[1].Value $proj }
                    foreach ($m in $reCargo.Matches($hay)) { Add-Res 'cargo'       $m.Groups[1].Value $proj }
                    foreach ($m in $reBrew.Matches($hay))  { Add-Res 'brew'        $m.Groups[1].Value $proj }
                    foreach ($m in $reApt.Matches($hay))   { Add-Res 'apt'         $m.Groups[1].Value $proj }
                    foreach ($m in $reGo.Matches($hay))    { Add-Res 'go'          $m.Groups[1].Value $proj }
                    foreach ($m in $reGh.Matches($hay))    { Add-Res 'github-repo' $m.Groups[1].Value $proj }
                }
            } finally { $reader.Dispose() }
        } catch { continue }
    }

    [Console]::Error.WriteLine("  Found $($resources.Count) unique resources")

    $sw = [IO.StreamWriter]::new($ResourcesFile, $true, [System.Text.UTF8Encoding]::new($false))
    try {
        foreach ($k in $resources.Keys) {
            $parts    = $k -split '\|', 2
            $cat      = $parts[0]
            $resource = $parts[1]
            $ctx      = $resources[$k]
            $resEsc   = $resource -replace '\|', '\|'
            $ctxEsc   = $ctx -replace '\|', '\|'
            if ($ctxEsc.Length -gt 30) { $ctxEsc = $ctxEsc.Substring(0, 30) }
            $sw.WriteLine("| $today | $ctxEsc | $cat | $resEsc | historical |")
        }
    } finally { $sw.Dispose() }
}

$lineCount = (Get-Content -LiteralPath $ResourcesFile).Count
Write-Host "✓ Wrote $ResourcesFile ($lineCount lines)"
