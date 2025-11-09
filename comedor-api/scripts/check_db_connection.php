<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

try {
    $conn = DB::connection();
    $pdo = $conn->getPdo();

    $driver = config('database.default');
    $cfg = config("database.connections.$driver");
    $host = $cfg['host'] ?? ($cfg['url'] ?? '');
    $port = $cfg['port'] ?? '3306';
    $user = $cfg['username'] ?? '';
    $dbName = $conn->getDatabaseName();

    $versionRow = $conn->selectOne('select version() as v');
    $version = $versionRow->v ?? '(unknown)';

    $exists = $conn->select("select schema_name from information_schema.schemata where schema_name = ?", [$dbName]);

    echo "Connected using driver: $driver\n";
    echo "Host: $host\n";
    echo "Port: $port\n";
    echo "User: $user\n";
    echo "Database (configured): $dbName\n";
    echo "Server version: $version\n";
    echo "Database exists: " . (count($exists) ? 'yes' : 'no') . "\n";
    exit(0);
} catch (Exception $e) {
    echo "ERROR connecting to DB: " . $e->getMessage() . "\n";
    exit(1);
}
