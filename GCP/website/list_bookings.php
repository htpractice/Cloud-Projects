<?php
// Allow CORS
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// DB config
$host = '104.198.208.198';
$db = 'eventsdb';
$user = 'root';
$pass = 'M7rk|(`J&H1+*I>i';

try {
    // DB connection
    $pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Fetch bookings with event titles
    $sql = "SELECT b.id, b.user_email, b.timestamp, e.title AS event_title
            FROM bookings b
            JOIN events e ON b.event_id = e.id
            ORDER BY b.timestamp DESC";

    $stmt = $pdo->query($sql);
    $bookings = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($bookings);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "DB Error: " . $e->getMessage()]);
}
// Close connection