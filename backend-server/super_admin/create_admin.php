<?php
// super_admin/create_admin.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();
requireRole($user, ['super_admin']);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$username = $data['username'] ?? '';
$email = $data['email'] ?? '';
$password = $data['password'] ?? '';

if (empty($username) || empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Username, email, and password are required']);
    exit;
}

// Check if username or email already exists
$stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
$stmt->execute([$username, $email]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(['status' => 'error', 'message' => 'Username or email already exists']);
    exit;
}

$password_hash = password_hash($password, PASSWORD_BCRYPT);

try {
    $stmt = $pdo->prepare("INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, 'admin')");
    $stmt->execute([$username, $email, $password_hash]);
    
    http_response_code(201);
    echo json_encode(['status' => 'success', 'message' => 'Admin account created successfully']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to create admin: ' . $e->getMessage()]);
}
?>
