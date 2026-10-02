# ==============================================================================
# ZeroScroll Sideload Release & Deployment Automation (PowerShell)
# Builds the sideload release APK, tracks version & build number, computes SHA-256,
# and deploys artifacts to the website download placeholder.
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("patch", "minor", "major", "build")]
    [string]$Bump,

    [Parameter(Mandatory = $false)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [int]$BuildNumber,

    [Parameter(Mandatory = $false)]
    [string]$Notes,

    [Parameter(Mandatory = $false)]
    [int]$MinSupportedBuild = 1,

    [Parameter(Mandatory = $false)]
    [string]$PublicUrl,

    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild,

    [Parameter(Mandatory = $false)]
    [switch]$NoBump,

    [Parameter(Mandatory = $false)]
    [switch]$Deploy,

    [Parameter(Mandatory = $false)]
    [switch]$NoWebsiteBuild,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NodeScript = Join-Path $ScriptDir "release.js"

$NodeArgs = @()

if ($Help) {
    $NodeArgs += "--help"
}
if ($PSBoundParameters.ContainsKey('Bump')) {
    $NodeArgs += @("--bump", $Bump)
}
if ($PSBoundParameters.ContainsKey('Version')) {
    $NodeArgs += @("--version", $Version)
}
if ($PSBoundParameters.ContainsKey('BuildNumber')) {
    $NodeArgs += @("--build-number", $BuildNumber)
}
if ($PSBoundParameters.ContainsKey('Notes')) {
    $NodeArgs += @("--notes", $Notes)
}
if ($PSBoundParameters.ContainsKey('MinSupportedBuild')) {
    $NodeArgs += @("--min-supported-build", $MinSupportedBuild)
}
if ($PSBoundParameters.ContainsKey('PublicUrl')) {
    $NodeArgs += @("--public-url", $PublicUrl)
}
if ($SkipBuild) {
    $NodeArgs += "--skip-build"
}
if ($NoBump) {
    $NodeArgs += "--no-bump"
}
if ($Deploy) {
    $NodeArgs += "--deploy"
}
if ($NoWebsiteBuild) {
    $NodeArgs += "--no-website-build"
}

node $NodeScript @NodeArgs
exit $LASTEXITCODE
