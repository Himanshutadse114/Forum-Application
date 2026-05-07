<?php
// backend/api/auth/register.php

require_once __DIR__ . '/../../middleware/auth.php';

AuthMiddleware::getCorsHeaders();

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

if (strlen($username) < 3 || strlen($username) > 50) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Username must be between 3 and 50 characters."]);
    exit;
}

if (strlen($password) < 6) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Password must be at least 6 characters long."]);
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

    // Insert user
    $stmt = $conn->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
    $stmt->execute([$username, $email, $passwordHash]);
    $userId = $conn->lastInsertId();

    // Reward registration achievement
    $badgeStmt = $conn->prepare("INSERT INTO achievements (user_id, badge_name, badge_icon, description) VALUES (?, ?, ?, ?)");
    $badgeStmt->execute([$userId, 'Initiated', 'verified_user', 'Welcome to the CyberShield Forum! You have taken your first step in securing the digital frontier.']);

    // Create automatic welcome notification
    $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, type, title, message) VALUES (?, ?, ?, ?)");
    $notifStmt->execute([$userId, 'achievement', 'Welcome to CyberShield!', 'Achievement Unlocked: Initiated. Check out the forum and help report active digital scams!']);

    http_response_code(201);
    echo json_encode([
        "status" => "success",
        "message" => "User registered successfully.",
        "data" => [
            "id" => $userId,
            "username" => $username,
            "email" => $email
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
