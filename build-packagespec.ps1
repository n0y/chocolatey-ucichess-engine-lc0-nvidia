$Props = convertfrom-stringdata (get-content versions.properties | Select-String -pattern "^#" -NotMatch)
$UpstreamVersion = $Props.UPSTREAM_VERSION

$FileUrl = "https://github.com/LeelaChessZero/lc0/releases/download/v$UpstreamVersion/lc0-v$UpstreamVersion-windows-gpu-nvidia-cuda11.zip"

"Building Upstream Version: $UpstreamVersion from url $FileUrl"
""

try {
    # Erstellt eine HTTP-Anfrage
    $request = [System.Net.WebRequest]::Create($FileUrl)
    $request.Method = "GET"

    # Sendet die Anfrage und erhält den Antwort-Stream
    $response = $request.GetResponse()
    $stream = $response.GetResponseStream()

    # Erstellt ein SHA256-Objekt
    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    # Berechnet den Hash direkt aus dem Stream
    # Die Daten werden in Blöcken gelesen und verarbeitet, nicht auf einmal
    $hashBytes = $sha256.ComputeHash($stream)

    # Konvertiert das Hash-Byte-Array in einen hexadezimalen String
    $UpstreamChecksum = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
} finally {
    # Schließt den Stream und die Antwort, um Ressourcen freizugeben
    if ($stream) { $stream.Close() }
    if ($response) { $response.Close() }
}

if (Test-Path -LiteralPath .\target) {
    Remove-Item -LiteralPath .\target -Recurse
}
New-Item -ItemType Directory -Force -Path .\target\tools | Out-Null
#
(Get-Content .\src\tools\chocolateyinstall.template.ps1) `
    -replace '%%VERSION%%', $UpstreamVersion `
    -replace '%%CHECKSUM%%', $UpstreamChecksum  |
        Out-File -Encoding utf8 ".\target\tools\chocolateyInstall.ps1"
(Get-Content .\src\tools\chocolateyUninstall.template.ps1) `
    -replace '%%VERSION%%', $UpstreamVersion `
    -replace '%%CHECKSUM%%', $UpstreamChecksum  |
        Out-File -Encoding utf8 ".\target\tools\chocolateyUninstall.ps1"
(Get-Content .\src\ucichess-engine-lc0-nvidia.template.nuspec.xml) -replace '%%VERSION%%', $UpstreamVersion | Out-File -Encoding utf8 ".\target\ucichess-engine-lc0-nvidia.nuspec"

