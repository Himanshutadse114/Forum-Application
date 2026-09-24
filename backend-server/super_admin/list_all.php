<?php
// super_admin/list_all.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();
requireRole($user, ['super_admin']);

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

try {
    global $pdo;
    
    // Fetch all admins
    $stmt = $pdo->query("SELECT id, username, email FROM users WHERE role = 'admin'");
    $admins = $stmt->fetchAll();
    
    // Fetch all users
    $stmt = $pdo->query("SELECT id, username, email, assigned_admin_id FROM users WHERE role = 'user'");
    $users = $stmt->fetchAll();
    
    echo json_encode([
        'status' => 'success',
        'data' => [
            'admins' => $admins,
            'users' => $users
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to fetch data: ' . $e->getMessage()]);
}
?>
