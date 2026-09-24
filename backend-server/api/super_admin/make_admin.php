<?php
// backend/api/super_admin/make_admin.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

// Ensure the caller is a super_admin
if ($userData['role'] !== 'super_admin') {
    http_response_code(403);
    echo json_encode(["status" => "error", "message" => "Forbidden. Super Admin access required."]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed. Use POST."]);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['user_id'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing user_id parameter."]);
    exit;
}

$targetUserId = intval($input['user_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    // Check if user exists
    $stmtCheck = $conn->prepare("SELECT id, role FROM users WHERE id = ?");
    $stmtCheck->execute([$targetUserId]);
    $user = $stmtCheck->fetch();

    if (!$user) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found."]);
        exit;
    }

    if ($user['role'] === 'admin' || $user['role'] === 'super_admin') {
        echo json_encode(["status" => "error", "message" => "User is already an admin or super admin."]);
        exit;
    }

    // Update role
    $stmtUpdate = $conn->prepare("UPDATE users SET role = 'admin' WHERE id = ?");
    $stmtUpdate->execute([$targetUserId]);

    echo json_encode(["status" => "success", "message" => "User successfully promoted to Admin."]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
