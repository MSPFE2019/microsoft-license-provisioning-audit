param(
    [string]$SolutionName = "microsoft-license-provisioning-audit",
    [string]$SourceFolder = "src/solutions/microsoft-license-provisioning-audit",
    [string]$OutputFolder = "out",
    [string]$TempFolder = "out/tmp"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    throw "Power Platform CLI (pac) is required."
}

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
New-Item -ItemType Directory -Path $TempFolder -Force | Out-Null

$unmanagedZip = Join-Path $OutputFolder "${SolutionName}_unmanaged.zip"
$managedZip = Join-Path $OutputFolder "${SolutionName}_managed.zip"
$managedSourceFolder = Join-Path $TempFolder "${SolutionName}-managed-src"

pac solution pack --folder $SourceFolder --zipfile $unmanagedZip --packagetype Unmanaged --errorlevel Info
if ($LASTEXITCODE -ne 0) {
    throw "Unmanaged pack failed."
}

if (Test-Path $managedSourceFolder) {
    Remove-Item -Path $managedSourceFolder -Recurse -Force
}
New-Item -ItemType Directory -Path $managedSourceFolder -Force | Out-Null
Copy-Item -Path (Join-Path $SourceFolder "*") -Destination $managedSourceFolder -Recurse -Force

$solutionXmlPath = Join-Path $managedSourceFolder "Other/Solution.xml"
$solutionXml = Get-Content -Path $solutionXmlPath -Raw
$solutionXml = $solutionXml -replace "<Managed>0</Managed>", "<Managed>1</Managed>"
Set-Content -Path $solutionXmlPath -Value $solutionXml

pac solution pack --folder $managedSourceFolder --zipfile $managedZip --packagetype Managed --errorlevel Info
if ($LASTEXITCODE -ne 0) {
    throw "Managed pack failed."
}


Write-Host "Built:"
Write-Host " - $unmanagedZip"
Write-Host " - $managedZip"
