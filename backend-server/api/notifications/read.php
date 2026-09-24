<?php
// backend/api/notifications/read.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$notificationId = isset($data['notification_id']) ? intval($data['notification_id']) : null;
$userId = $userData['user_id'];

$db = new Database();
$conn = $db->getConnection();

try {
    if ($notificationId) {
        $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
        $stmt->execute([$notificationId, $userId]);
    } else {
        $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
        $stmt->execute([$userId]);
    }

    echo json_encode([
        "status" => "success",
        "message" => "Notifications marked as read."
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
