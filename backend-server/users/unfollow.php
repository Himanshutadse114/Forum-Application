<?php
// users/unfollow.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$target_user_id = $data['target_user_id'] ?? 0;

if (empty($target_user_id)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Target user ID is required']);
    exit;
}

try {
    global $pdo;
    
    $stmt = $pdo->prepare("DELETE FROM follows WHERE follower_id = ? AND following_id = ?");
    $stmt->execute([$user['id'], $target_user_id]);
    
    if ($stmt->rowCount() > 0) {
        echo json_encode([
            'status' => 'success',
            'message' => 'User unfollowed successfully'
        ]);
    } else {
        http_response_code(404);
        echo json_encode(['status' => 'error', 'message' => 'You were not following this user']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to unfollow user: ' . $e->getMessage()]);
}
?>
