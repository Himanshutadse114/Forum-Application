<?php
// backend/api/notifications/list.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$userId = $userData['user_id'];
$db = new Database();
$conn = $db->getConnection();

try {
    $stmt = $conn->prepare("SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50");
    $stmt->execute([$userId]);
    $notifications = $stmt->fetchAll();

    echo json_encode([
        "status" => "success",
        "data" => $notifications
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
