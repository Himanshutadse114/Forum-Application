<?php
// backend/api/admin/my_users.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

// Ensure the caller is an admin or super_admin
if ($userData['role'] !== 'admin' && $userData['role'] !== 'super_admin') {
    http_response_code(403);
    echo json_encode(["status" => "error", "message" => "Forbidden. Admin access required."]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$adminId = intval($userData['user_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    $stmt = $conn->prepare("SELECT id, username, email, reputation_points, `rank`, avatar, created_at FROM users WHERE assigned_admin_id = ?");
    $stmt->execute([$adminId]);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => $users
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
