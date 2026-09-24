<?php
// admin/user_detail.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();
requireRole($user, ['admin', 'super_admin']);

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
    
    // Verify assignment (unless super_admin)
    if ($user['role'] !== 'super_admin') {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND assigned_admin_id = ?");
        $stmt->execute([$target_user_id, $user['id']]);
        if (!$stmt->fetch()) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Access denied: user not assigned to you']);
            exit;
        }
    }
    
    // Fetch user profile
    $stmt = $pdo->prepare("SELECT id, username, email, role, reputation_points, `rank`, avatar, created_at FROM users WHERE id = ?");
    $stmt->execute([$target_user_id]);
    $profile = $stmt->fetch();
    
    if (!$profile) {
        http_response_code(404);
        echo json_encode(['status' => 'error', 'message' => 'User not found']);
        exit;
    }
    
    // Game Score Progress
    $stmt = $pdo->prepare("SELECT game_id, score, played_at FROM game_scores WHERE user_id = ? ORDER BY played_at ASC");
    $stmt->execute([$target_user_id]);
    $score_progress = $stmt->fetchAll();
    
    // Forum Activity
    $stmt = $pdo->prepare("SELECT id, title, created_at,
                            (SELECT COUNT(*) FROM likes WHERE post_id = posts.id) as likes_count,
                            (SELECT COUNT(*) FROM comments WHERE post_id = posts.id) as comments_count
                            FROM posts 
                            WHERE user_id = ? 
                            ORDER BY created_at DESC LIMIT 5");
    $stmt->execute([$target_user_id]);
    $posts = $stmt->fetchAll();
    
    // Comments by user
    $stmt = $pdo->prepare("SELECT c.id, c.content, c.created_at, p.title as post_title, p.id as post_id 
                            FROM comments c 
                            JOIN posts p ON c.post_id = p.id 
                            WHERE c.user_id = ? 
                            ORDER BY c.created_at DESC LIMIT 10");
    $stmt->execute([$target_user_id]);
    $comments = $stmt->fetchAll();

    // Likes by user
    $stmt = $pdo->prepare("SELECT l.created_at, p.title as post_title, p.id as post_id 
                            FROM likes l 
                            JOIN posts p ON l.post_id = p.id 
                            WHERE l.user_id = ? 
                            ORDER BY l.created_at DESC LIMIT 10");
    $stmt->execute([$target_user_id]);
    $likes = $stmt->fetchAll();

    echo json_encode([
        'status' => 'success',
        'data' => [
            'profile' => $profile,
            'game_scores' => $score_progress,
            'recent_posts' => $posts,
            'achievements' => [], // Fallback since we don't have an achievements table yet
            'comments' => $comments,
            'likes' => $likes
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to fetch user details: ' . $e->getMessage()]);
}
?>
