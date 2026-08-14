param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $PSScriptRoot 'jlcpcb_sourcing.csv'
$schematicPath = Join-Path $ProjectRoot 'cryobelt.kicad_sch'
$pcbPath = Join-Path $ProjectRoot 'cryobelt.kicad_pcb'
$bomPath = Join-Path $PSScriptRoot 'jlcpcb_bom.csv'
$cplPath = Join-Path $PSScriptRoot 'jlcpcb_cpl.csv'
$rawPosPath = Join-Path ([System.IO.Path]::GetTempPath()) 'cryobelt_jlc_pos.csv'
$rawNetlistPath = Join-Path ([System.IO.Path]::GetTempPath()) 'cryobelt_jlc_netlist.xml'

$kicadCli = (Get-Command kicad-cli -ErrorAction SilentlyContinue).Source
if (-not $kicadCli) {
    $kicadCli = Get-ChildItem 'C:\Program Files\KiCad' -Recurse -Filter kicad-cli.exe -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $kicadCli) { throw 'kicad-cli.exe was not found.' }

$source = Import-Csv $sourcePath
$assembled = @($source | Where-Object { $_.Assembly -ne 'DNP' })

$allRefs = @{}
foreach ($row in $source) {
    $refs = @(($row.Designators -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ([int]$row.Quantity -ne $refs.Count) {
        throw "Quantity mismatch for $($row.Designators): declared $($row.Quantity), found $($refs.Count) references."
    }
    foreach ($ref in $refs) {
        if ($allRefs.ContainsKey($ref)) { throw "Duplicate sourcing reference: $ref" }
        $allRefs[$ref] = $row
    }
    if ($row.Assembly -ne 'DNP') {
        if ([string]::IsNullOrWhiteSpace($row.'Manufacturer Part Number')) {
            throw "Missing manufacturer part number for $($row.Designators)."
        }
        if ($row.'LCSC Part Number' -notmatch '^C[0-9]+$') {
            throw "Invalid LCSC part number for $($row.Designators): $($row.'LCSC Part Number')"
        }
    }
}

& $kicadCli sch export netlist --format kicadxml --output $rawNetlistPath $schematicPath | Out-Host
if ($LASTEXITCODE -ne 0) { throw "kicad-cli netlist export failed with exit code $LASTEXITCODE." }
$netlist = [xml](Get-Content $rawNetlistPath -Raw)
$netlistRefs = @($netlist.export.components.comp | ForEach-Object { $_.ref } | Sort-Object)
$sourceRefs = @($allRefs.Keys | Sort-Object)
$missingSource = @($netlistRefs | Where-Object { $_ -notin $sourceRefs })
$extraSource = @($sourceRefs | Where-Object { $_ -notin $netlistRefs })
if ($missingSource.Count -or $extraSource.Count) {
    throw "Sourcing reference mismatch. Missing: $($missingSource -join ', '); unexpected: $($extraSource -join ', ')"
}

$bom = foreach ($row in $assembled) {
    [pscustomobject]@{
        Designator          = $row.Designators
        Footprint           = $row.'Target Footprint'
        Quantity            = $row.Quantity
        Value               = $row.Value
        'LCSC Part #'       = $row.'LCSC Part Number'
    }
}
$bom | Export-Csv -NoTypeInformation -Encoding utf8 $bomPath

& $kicadCli pcb export pos --format csv --units mm --side both --output $rawPosPath $pcbPath | Out-Host
if ($LASTEXITCODE -ne 0) { throw "kicad-cli position export failed with exit code $LASTEXITCODE." }

$assemblyByRef = @{}
foreach ($row in $assembled) {
    foreach ($ref in ($row.Designators -split ',')) {
        $assemblyByRef[$ref.Trim()] = $row
    }
}

$positions = Import-Csv $rawPosPath
$cpl = foreach ($pos in $positions) {
    if (-not $assemblyByRef.ContainsKey($pos.Ref)) { continue }
    $rotation = [double]$pos.Rot
    # The WS2812B-2427-V6 pinout is the former SK6805 footprint pinout rotated
    # by 180 degrees. The adapter footprint preserves the routed pad locations,
    # so the physical part requires the same correction in JLC's CPL.
    if ($assemblyByRef[$pos.Ref].'Manufacturer Part Number' -eq 'WS2812B-2427-V6') {
        $rotation += 180
    }
    while ($rotation -lt 0) { $rotation += 360 }
    while ($rotation -ge 360) { $rotation -= 360 }
    [pscustomobject]@{
        Designator = $pos.Ref
        'Mid X'     = ('{0:0.0000}mm' -f [double]$pos.PosX)
        'Mid Y'     = ('{0:0.0000}mm' -f [double]$pos.PosY)
        Layer       = if ($pos.Side -eq 'top') { 'Top' } else { 'Bottom' }
        Rotation    = ('{0:0.00}' -f $rotation)
    }
}
$cpl | Sort-Object Designator | Export-Csv -NoTypeInformation -Encoding utf8 $cplPath

$expectedRefs = @($assemblyByRef.Keys | Sort-Object)
$actualRefs = @($cpl.Designator | Sort-Object)
$missing = @($expectedRefs | Where-Object { $_ -notin $actualRefs })
$unexpected = @($actualRefs | Where-Object { $_ -notin $expectedRefs })
if ($missing.Count -or $unexpected.Count) {
    throw "CPL reference mismatch. Missing: $($missing -join ', '); unexpected: $($unexpected -join ', ')"
}

Write-Host "Generated $($bom.Count) BOM rows and $($cpl.Count) CPL rows."
Write-Host "Validated $($allRefs.Count) unique source references."
Write-Host "BOM: $bomPath"
Write-Host "CPL: $cplPath"

$unresolved = @($source | Where-Object { $_.Status -notin @('READY', 'EXCLUDED') })
if ($unresolved.Count) {
    Write-Warning "Not order-ready: $($unresolved.Count) sourcing rows remain unresolved: $((($unresolved | ForEach-Object { "$($_.Designators) [$($_.Status)]" })) -join '; ')"
}
