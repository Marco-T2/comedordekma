<?php
// Insert a test card directly into SQLite DB used by the app.
$dbPath = __DIR__ . '/../database/database.sqlite';
if (!file_exists($dbPath)) {
    echo "ERROR: database file not found: $dbPath\n";
    exit(1);
}
try {
    $db = new PDO('sqlite:' . $dbPath);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $code = $argv[1] ?? '0001';
    $nombre = $argv[2] ?? 'Test Card';
    $tipo = $argv[3] ?? 'normal';
    $activo = isset($argv[4]) ? (int)$argv[4] : 1;

    $stmt = $db->prepare("INSERT INTO cards (code,nombre,tipo,activo,created_at,updated_at) VALUES (:code,:nombre,:tipo,:activo,datetime('now'),datetime('now'))");
    $stmt->execute([':code' => $code, ':nombre' => $nombre, ':tipo' => $tipo, ':activo' => $activo]);
    echo "Inserted card: code=$code nombre=$nombre\n";
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
