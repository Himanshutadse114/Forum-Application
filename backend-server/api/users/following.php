<?php
// backend/api/users/following.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

if (empty($_GET['user_id'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing user_id parameter."]);
    exit;
}

$userId = intval($_GET['user_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    $stmt = $conn->prepare("
        SELECT u.id, u.username, u.`rank`, u.reputation_points 
        FROM follows f 
        JOIN users u ON f.followed_id = u.id 
        WHERE f.follower_id = ?
        ORDER BY f.created_at DESC
    ");
    $stmt->execute([$userId]);
    $following = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => $following
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
