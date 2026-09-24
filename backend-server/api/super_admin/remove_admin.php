<?php
// backend/api/super_admin/remove_admin.php

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
    // Prevent the super admin from demoting themselves or the master super admin
    if ($targetUserId === intval($userData['user_id'])) {
        echo json_encode(["status" => "error", "message" => "You cannot demote yourself."]);
        exit;
    }

    $stmtCheck = $conn->prepare("SELECT role FROM users WHERE id = ?");
    $stmtCheck->execute([$targetUserId]);
    $user = $stmtCheck->fetch();

    if (!$user) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found."]);
        exit;
    }

    if ($user['role'] === 'super_admin') {
        echo json_encode(["status" => "error", "message" => "You cannot demote another super admin."]);
        exit;
    }

    if ($user['role'] !== 'admin') {
        echo json_encode(["status" => "error", "message" => "User is not an admin."]);
        exit;
    }

    // 1. Demote the admin back to a standard user
    $stmtUpdate = $conn->prepare("UPDATE users SET role = 'user' WHERE id = ?");
    $stmtUpdate->execute([$targetUserId]);

    // 2. Unassign any users that were assigned to this admin so they are orphaned back to the pool
    $stmtUnassign = $conn->prepare("UPDATE users SET assigned_admin_id = NULL WHERE assigned_admin_id = ?");
    $stmtUnassign->execute([$targetUserId]);

    echo json_encode(["status" => "success", "message" => "Admin successfully demoted to standard User."]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
