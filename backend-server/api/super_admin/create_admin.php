<?php
// backend/api/super_admin/create_admin.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

// Ensure the caller is a super_admin
if ($userData['role'] !== 'super_admin') {
    http_response_code(403);
    echo json_encode(["status" => "error", "message" => "Forbidden. Only super admins can create admin accounts."]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['username']) || empty($data['email']) || empty($data['password'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing required fields (username, email, password)."]);
    exit;
}

$username = trim($data['username']);
$email = filter_var(trim($data['email']), FILTER_VALIDATE_EMAIL);
$password = $data['password'];

if (!$email) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Invalid email address format."]);
    exit;
}

$db = new Database();
$conn = $db->getConnection();

try {
    // Check if user already exists
    $stmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
    $stmt->execute([$username, $email]);
    if ($stmt->fetch()) {
        http_response_code(409);
        echo json_encode(["status" => "error", "message" => "Username or Email already registered."]);
        exit;
    }

    // Secure password hashing
    $passwordHash = password_hash($password, PASSWORD_BCRYPT);

    // Insert new admin
    $stmt = $conn->prepare("INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, 'admin')");
    $stmt->execute([$username, $email, $passwordHash]);
    $adminId = $conn->lastInsertId();

    echo json_encode([
        "status" => "success",
        "message" => "Admin created successfully.",
        "data" => [
            "id" => $adminId,
            "username" => $username,
            "role" => "admin"
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
