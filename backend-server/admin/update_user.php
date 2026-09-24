<?php
// admin/update_user.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();
requireRole($user, ['admin', 'super_admin']);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$target_user_id = $data['user_id'] ?? null;
$action = $data['action'] ?? null;

if (!$target_user_id || !$action) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'User ID and action are required']);
    exit;
}

try {
    global $pdo;
    
    // Verify assignment (unless super_admin)
    if ($user['role'] !== 'super_admin') {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND assigned_admin_id = ?");
        $stmt->execute([$target_user_id, $user['id']]);
        if (!$stmt->fetch()) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'You are not authorized to manage this user']);
            exit;
        }
    }
    
    switch ($action) {
        case 'ban':
            // Prevent banning super admins
            $stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
            $stmt->execute([$target_user_id]);
            $target_role = $stmt->fetchColumn();
            if ($target_role === 'super_admin') {
                http_response_code(403);
                echo json_encode(['status' => 'error', 'message' => 'You cannot ban a Super Admin!']);
                exit;
            }

            $stmt = $pdo->prepare("UPDATE users SET role = 'banned' WHERE id = ?");
            $stmt->execute([$target_user_id]);
            break;
        case 'unban':
            $stmt = $pdo->prepare("UPDATE users SET role = 'user' WHERE id = ?");
            $stmt->execute([$target_user_id]);
            break;
        case 'promote_admin':
            $stmt = $pdo->prepare("UPDATE users SET role = 'admin' WHERE id = ?");
            $stmt->execute([$target_user_id]);
            break;
        case 'demote_user':
            $stmt = $pdo->prepare("UPDATE users SET role = 'user' WHERE id = ?");
            $stmt->execute([$target_user_id]);
            break;
        case 'reset_reputation':
            $stmt = $pdo->prepare("UPDATE users SET reputation_points = 0, `rank` = 'Recruit' WHERE id = ?");
            $stmt->execute([$target_user_id]);
            break;
        default:
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Invalid action']);
            exit;
    }
    
    echo json_encode(['status' => 'success', 'message' => 'User updated successfully']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to update user: ' . $e->getMessage()]);
}
?>
