# =========================================================
# 1. Konfiguration
# =========================================================

# Pfad zur ausführbaren Datei (Passe diesen an!)
$exePath = "$env:ProgramData\UCI-Chess\Engine\lc0-nvidia\lc0.exe"
$expectedOutput = "id name Lc0" # Erwartet, dass die Engine einen Zug vorschlägt
$timeoutSeconds = 15

# Die Befehle, die nacheinander gesendet werden sollen
$commands = @(
    "uci",                      # 1. Initialisierung
    "quit"                      # 7. Beenden
)

# =========================================================
# 2. Prozess konfigurieren und starten (Ohne Start-Process)
# =========================================================
Write-Host "Starte Prozess '$exePath' und bereite Befehlssendung vor..."

# 1. Prozess-Startinformationen erstellen
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $exePath
$startInfo.UseShellExecute = $false # Wichtig: Muss False sein, um I/O umzuleiten
$startInfo.RedirectStandardInput = $true  # Aktiviere die Input-Umleitung
$startInfo.RedirectStandardOutput = $true # Aktiviere die Output-Umleitung
$startInfo.CreateNoWindow = $true

# 2. Prozess-Objekt erstellen und starten
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo
$process.Start() | Out-Null # Starten

# Warte kurz, bis die Engine initialisiert ist
Start-Sleep -Milliseconds 400
$process.StandardInput.WriteLine('')

# =========================================================
# 3. Befehle senden und Ergebnis lesen (Identisch zur alten Logik)
# =========================================================
$outputContent = ""

try {
    # Alle Befehle durchlaufen und senden
    foreach ($cmd in $commands) {
        Write-Host "Sende Kommando: $cmd" -ForegroundColor Yellow
        $process.StandardInput.WriteLine($cmd)
        Start-Sleep -Milliseconds 100
    }

    # Lese die gesamte Ausgabe von STDOUT (blockiert, bis der Prozess beendet ist)
    $outputContent = $process.StandardOutput.ReadToEnd()

    # Warte auf das Beenden des Prozesses
    $process.WaitForExit($timeoutSeconds * 1000) # WaitForExit nimmt Millisekunden

} catch {
    Write-Host "❌ Fehler während der Kommunikation oder Timeout erreicht: $($_.Exception.Message)" -ForegroundColor Red
    $process | Stop-Process -Force -ErrorAction SilentlyContinue
    exit 1
} finally {
    # Stelle sicher, dass der Prozess beendet wird, falls er noch läuft
    if (-not $process.HasExited) {
        $process.Kill()
    }
}

# =========================================================
# 4. Ergebnis prüfen
# =========================================================

Write-Host "--- STDOUT der EXE ---"
Write-Host $outputContent
Write-Host "----------------------"

if ($outputContent -match $expectedOutput) {
    Write-Host "✅ TEST ERFOLGREICH: '$expectedOutput' gefunden." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ TEST FEHLGESCHLAGEN: '$expectedOutput' NICHT gefunden." -ForegroundColor Red
    exit 1
}