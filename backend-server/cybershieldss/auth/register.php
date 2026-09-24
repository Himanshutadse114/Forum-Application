<?php
// auth/register.php
require_once __DIR__ . '/../_core.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$data     = json_decode(file_get_contents('php://input'), true) ?? [];
$username = trim($data['username'] ?? '');
$email    = trim($data['email']    ?? '');
$password = $data['password'] ?? '';

if (!$username || !$email || !$password) {
    http_response_code(400); echo json_encode(['status' => 'error', 'message' => 'Username, email, and password are required']); exit;
}

try {
    $db   = _db();
    $stmt = $db->prepare('SELECT id FROM users WHERE username = ? OR email = ?');
    $stmt->execute([$username, $email]);
    if ($stmt->fetch()) {
        http_response_code(409); echo json_encode(['status' => 'error', 'message' => 'Username or email already exists']); exit;
    }

    $db->prepare('INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)')->execute([$username, $email, password_hash($password, PASSWORD_BCRYPT)]);
    http_response_code(201);
    echo json_encode(['status' => 'success', 'message' => 'User registered successfully']);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
