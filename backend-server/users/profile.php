<?php
// users/profile.php
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
    
    // Fetch user profile
    $stmt = $pdo->prepare("SELECT id, username, email, role, reputation_points, `rank`, avatar, created_at FROM users WHERE id = ?");
    $stmt->execute([$target_user_id]);
    $profile = $stmt->fetch();
    
    if (!$profile) {
        http_response_code(404);
        echo json_encode(['status' => 'error', 'message' => 'User not found']);
        exit;
    }
    
    // Fetch follower/following counts
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM follows WHERE following_id = ?");
    $stmt->execute([$target_user_id]);
    $followers_count = $stmt->fetchColumn();
    
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM follows WHERE follower_id = ?");
    $stmt->execute([$target_user_id]);
    $following_count = $stmt->fetchColumn();
    
    // Check if current user is following this user
    $stmt = $pdo->prepare("SELECT id FROM follows WHERE follower_id = ? AND following_id = ?");
    $stmt->execute([$user['id'], $target_user_id]);
    $is_following = $stmt->fetch() ? true : false;
    
    $profile['followers_count'] = $followers_count;
    $profile['following_count'] = $following_count;
    $profile['is_following'] = $is_following;
    
    echo json_encode([
        'status' => 'success',
        'data' => $profile
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to fetch profile: ' . $e->getMessage()]);
}
?>
