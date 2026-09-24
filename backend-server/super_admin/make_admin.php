<?php
// super_admin/make_admin.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();
requireRole($user, ['super_admin']);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$target_user_id = $data['user_id'] ?? 0;

if (empty($target_user_id)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'User ID is required']);
    exit;
}

try {
    global $pdo;
    $stmt = $pdo->prepare("UPDATE users SET role = 'admin' WHERE id = ?");
    $stmt->execute([$target_user_id]);
    
    echo json_encode([
        'status' => 'success',
        'message' => 'User promoted to admin successfully'
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to promote user: ' . $e->getMessage()]);
}
?>
