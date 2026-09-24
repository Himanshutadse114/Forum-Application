<?php
// backend/api/super_admin/assign_user.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

// Ensure the caller is a super_admin
if ($userData['role'] !== 'super_admin') {
    http_response_code(403);
    echo json_encode(["status" => "error", "message" => "Forbidden. Only super admins can assign users."]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['user_id']) || !isset($data['admin_id'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing user_id or admin_id."]);
    exit;
}

$targetUserId = intval($data['user_id']);
$targetAdminId = intval($data['admin_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    // Verify the target admin actually has the 'admin' role
    $stmtAdmin = $conn->prepare("SELECT role FROM users WHERE id = ?");
    $stmtAdmin->execute([$targetAdminId]);
    $adminInfo = $stmtAdmin->fetch();

    if (!$adminInfo || ($adminInfo['role'] !== 'admin' && $adminInfo['role'] !== 'super_admin')) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Target admin_id does not belong to a valid admin."]);
        exit;
    }

    // Update the assigned_admin_id for the user
    $stmt = $conn->prepare("UPDATE users SET assigned_admin_id = ? WHERE id = ?");
    $stmt->execute([$targetAdminId, $targetUserId]);

    if ($stmt->rowCount() > 0 || $stmt->errorCode() == '00000') {
        echo json_encode([
            "status" => "success",
            "message" => "User successfully assigned to admin.",
            "data" => [
                "user_id" => $targetUserId,
                "assigned_admin_id" => $targetAdminId
            ]
        ]);
    } else {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found."]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
