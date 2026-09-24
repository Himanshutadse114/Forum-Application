<?php
// backend/api/users/follow.php

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

if ($followerId === $followedId) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "You cannot follow yourself."]);
    exit;
}

$db = new Database();
$conn = $db->getConnection();

try {
    // Check if user to follow exists
    $stmt = $conn->prepare("SELECT id FROM users WHERE id = ?");
    $stmt->execute([$followedId]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User to follow not found."]);
        exit;
    }

    // Insert follow relation (ignore duplicate errors)
    $stmt = $conn->prepare("INSERT IGNORE INTO follows (follower_id, followed_id) VALUES (?, ?)");
    $stmt->execute([$followerId, $followedId]);

    echo json_encode([
        "status" => "success",
        "message" => "Successfully followed user."
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
