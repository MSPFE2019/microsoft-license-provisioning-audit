param(
    [string]$SourceFolder = "src/solutions/microsoft-license-provisioning-audit",
    [string]$TempFolder = "out/validate"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    throw "Power Platform CLI (pac) is required."
}

New-Item -ItemType Directory -Path $TempFolder -Force | Out-Null

$validateZip = Join-Path $TempFolder "validate-unmanaged.zip"
$roundTripFolder = Join-Path $TempFolder "roundtrip-src"

if (Test-Path $roundTripFolder) {
    Remove-Item -Path $roundTripFolder -Recurse -Force
}

pac solution pack --folder $SourceFolder --zipfile $validateZip --packagetype Unmanaged --errorlevel Info
if ($LASTEXITCODE -ne 0) {
    throw "Validation pack failed."
}
pac solution unpack --zipfile $validateZip --folder $roundTripFolder --packagetype Unmanaged --allowDelete true --allowWrite true --clobber true
if ($LASTEXITCODE -ne 0) {
    throw "Validation unpack failed."
}

Write-Host "Validation complete. Pack/unpack succeeded."
