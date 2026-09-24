<?php
// super_admin/remove_admin.php
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
    
    // Check if target is actually an admin
    $stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
    $stmt->execute([$target_user_id]);
    $role = $stmt->fetchColumn();
    
    if ($role !== 'admin') {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Target user is not an admin']);
        exit;
    }
    
    $stmt = $pdo->prepare("UPDATE users SET role = 'user', assigned_admin_id = NULL WHERE id = ?");
    $stmt->execute([$target_user_id]);
    
    // Also unassign users assigned to this admin
    $stmt = $pdo->prepare("UPDATE users SET assigned_admin_id = NULL WHERE assigned_admin_id = ?");
    $stmt->execute([$target_user_id]);
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Admin demoted to user successfully'
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to demote admin: ' . $e->getMessage()]);
}
?>
