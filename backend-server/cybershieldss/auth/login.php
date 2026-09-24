<?php
// auth/login.php
require_once __DIR__ . '/../_core.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$data     = json_decode(file_get_contents('php://input'), true) ?? [];
$username = trim($data['username'] ?? '');
$password = $data['password'] ?? '';

if (!$username || !$password) {
    http_response_code(400); echo json_encode(['status' => 'error', 'message' => 'Username and password are required']); exit;
}

try {
    $db   = _db();
    $stmt = $db->prepare('SELECT id, username, email, password_hash, role, reputation_points, `rank`, avatar FROM users WHERE username = ?');
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        http_response_code(401); echo json_encode(['status' => 'error', 'message' => 'Invalid username or password']); exit;
    }

    $token = _jwtGenerate([
        'iss'      => 'cybershield_api',
        'sub'      => $user['id'],
        'username' => $user['username'],
        'role'     => $user['role'],
        'iat'      => time(),
        'exp'      => time() + (86400 * 30),
    ]);

    unset($user['password_hash']);
    echo json_encode(['status' => 'success', 'message' => 'Login successful', 'data' => ['token' => $token, 'user' => $user]]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
