<?php
// backend/api/users/unfollow.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['target_user_id'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing target_user_id."]);
    exit;
}

$followerId = intval($userData['user_id']);
$followedId = intval($data['target_user_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    $stmt = $conn->prepare("DELETE FROM follows WHERE follower_id = ? AND followed_id = ?");
    $stmt->execute([$followerId, $followedId]);

    echo json_encode([
        "status" => "success",
        "message" => "Successfully unfollowed user."
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
