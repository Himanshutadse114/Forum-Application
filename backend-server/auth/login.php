<?php
// auth/login.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../config/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$username = $data['username'] ?? '';
$password = $data['password'] ?? '';

if (empty($username) || empty($password)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Username and password are required']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT id, username, email, password_hash, role, reputation_points, `rank`, avatar FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Invalid username or password']);
        exit;
    }

    $secret = $_ENV['JWT_SECRET'] ?? 'your_jwt_secret_here';

    $headers = ['alg' => 'HS256', 'typ' => 'JWT'];
    $payload = [
        'iss' => 'cybershield_api',
        'sub' => $user['id'],
        'username' => $user['username'],
        'role' => $user['role'],
        'iat' => time(),
        'exp' => time() + (86400 * 30) // 30 days
    ];

    $token = generateJWT($headers, $payload, $secret);

    // Remove password hash before returning user data
    unset($user['password_hash']);

    echo json_encode([
        'status' => 'success',
        'message' => 'Login successful',
        'data' => [
            'token' => $token,
            'user' => $user
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Exception: ' . $e->getMessage()]);
}
?>
