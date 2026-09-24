<?php
// super_admin/assign_user.php
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

$user_id = $data['user_id'] ?? 0;
$admin_id = $data['admin_id'] ?? null; // Can be null to unassign

if (empty($user_id)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'User ID is required']);
    exit;
}

try {
    global $pdo;
    
    // Verify admin_id exists and is an admin (if not null)
    if ($admin_id) {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND role = 'admin'");
        $stmt->execute([$admin_id]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Invalid Admin ID']);
            exit;
        }
    }
    
    $stmt = $pdo->prepare("UPDATE users SET assigned_admin_id = ? WHERE id = ?");
    $stmt->execute([$admin_id, $user_id]);
    
    echo json_encode([
        'status' => 'success',
        'message' => 'User assigned successfully'
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to assign user: ' . $e->getMessage()]);
}
?>
