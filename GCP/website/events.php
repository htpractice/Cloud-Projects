<?php
// Allow CORS (for local dev, you can tighten for prod)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// DB config
$host = '104.198.208.198';
$db = 'eventsdb';
$user = 'root';
$pass = 'M7rk|(`J&H1+*I>i';

try {
    // Connect to MySQL using PDO
    $pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Fetch all events
    $stmt = $pdo->query("SELECT id, title, date, location FROM events ORDER BY date ASC");
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($events);
} catch (PDOException $e) {
    // Handle error
    http_response_code(500);
    echo json_encode(["error" => "Database error: " . $e->getMessage()]);
}
