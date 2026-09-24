<?php
// users/following.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$target_user_id = $_GET['user_id'] ?? null;

if (!$target_user_id) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'User ID is required']);
    exit;
}

try {
    global $pdo;
    $stmt = $pdo->prepare("SELECT u.id, u.username, u.avatar, u.`rank` 
                            FROM follows f 
                            JOIN users u ON f.following_id = u.id 
                            WHERE f.follower_id = ?");
    $stmt->execute([$target_user_id]);
    $following = $stmt->fetchAll();
    
    echo json_encode([
        'status' => 'success',
        'data' => $following
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to fetch following: ' . $e->getMessage()]);
}
?>
