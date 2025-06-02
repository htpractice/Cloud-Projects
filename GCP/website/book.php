<?php
// Enable CORS and set response headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// Replace these values with your actual DB credentials
$host = "104.198.208.198"; // e.g., 127.0.0.1 or public IP
$user = "root";
$password = "M7rk|(`J&H1+*I>i";
$database = "eventsdb";

// Create DB connection
$conn = new mysqli($host, $user, $password, $database);

// Check connection
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["message" => "Connection failed: " . $conn->connect_error]);
    exit();
}

// Read JSON input
$data = json_decode(file_get_contents("php://input"), true);

// Extract event_id and user_email from input
$event_id = $data["event_id"];
$user_email = $data["user_email"];

// Prepare and execute insert query
$stmt = $conn->prepare("INSERT INTO bookings (event_id, user_email) VALUES (?, ?)");
$stmt->bind_param("is", $event_id, $user_email);

if ($stmt->execute()) {
    echo json_encode(["message" => "Booking confirmed"]);
} else {
    http_response_code(500);
    echo json_encode(["message" => "Booking failed: " . $stmt->error]);
}

// Close connections
$stmt->close();
$conn->close();
?>
