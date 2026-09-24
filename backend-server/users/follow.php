<?php
// users/follow.php
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

if ($user['id'] == $target_user_id) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'You cannot follow yourself']);
    exit;
}

try {
    global $pdo;
    
    // Check if already following
    $stmt = $pdo->prepare("SELECT id FROM follows WHERE follower_id = ? AND following_id = ?");
    $stmt->execute([$user['id'], $target_user_id]);
    if ($stmt->fetch()) {
        http_response_code(409);
        echo json_encode(['status' => 'error', 'message' => 'You are already following this user']);
        exit;
    }
    
    $stmt = $pdo->prepare("INSERT INTO follows (follower_id, following_id) VALUES (?, ?)");
    $stmt->execute([$user['id'], $target_user_id]);
    
    echo json_encode([
        'status' => 'success',
        'message' => 'User followed successfully'
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to follow user: ' . $e->getMessage()]);
}
?>
