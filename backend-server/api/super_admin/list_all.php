<?php
// backend/api/super_admin/list_all.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

// Ensure the caller is a super_admin
if ($userData['role'] !== 'super_admin') {
    http_response_code(403);
    echo json_encode(["status" => "error", "message" => "Forbidden. Only super admins can view this list."]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$db = new Database();
$conn = $db->getConnection();

try {
    // Fetch all Admins
    $stmtAdmins = $conn->prepare("SELECT id, username, email FROM users WHERE role = 'admin' OR role = 'super_admin'");
    $stmtAdmins->execute();
    $admins = $stmtAdmins->fetchAll(PDO::FETCH_ASSOC);

    // Fetch all standard Users
    $stmtUsers = $conn->prepare("SELECT id, username, email, assigned_admin_id FROM users WHERE role = 'user'");
    $stmtUsers->execute();
    $users = $stmtUsers->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => [
            "admins" => $admins,
            "users" => $users
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
