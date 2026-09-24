<?php
// backend/api/users/leaderboard.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once __DIR__ . '/../../config/database.php';

$db = new Database();
$conn = $db->getConnection();

try {
    // Automatically ensure the leaderboard table or view is not strictly needed since we can query users directly
    $stmt = $conn->prepare("SELECT id, username, reputation_points, `rank`, avatar FROM users ORDER BY reputation_points DESC LIMIT 10");
    $stmt->execute();
    $users = $stmt->fetchAll();

    echo json_encode([
        "status" => "success",
        "data" => $users
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
?>
