<?php
// backend/api/auth/login.php

require_once __DIR__ . '/../../middleware/auth.php';

AuthMiddleware::getCorsHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['username']) || empty($data['password'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing username or password."]);
    exit;
}

$username = trim($data['username']);
$password = $data['password'];

$db = new Database();
$conn = $db->getConnection();

try {
    // Fetch user details
    $stmt = $conn->prepare("SELECT * FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        http_response_code(401);
        echo json_encode(["status" => "error", "message" => "Invalid username or password."]);
        exit;
    }

    // Generate JWT token
    $tokenPayload = [
        "user_id" => $user['id'],
        "username" => $user['username'],
        "email" => $user['email'],
        "role" => $user['role']
    ];
    $token = JWT::generate($tokenPayload);

    // Filter out password hash before sending user info
    unset($user['password_hash']);

    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "message" => "Login successful.",
        "token" => $token,
        "user" => $user
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
