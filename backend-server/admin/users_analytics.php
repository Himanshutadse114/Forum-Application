<?php
// admin/users_analytics.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();
requireRole($user, ['admin', 'super_admin']);

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

try {
    global $pdo;
    
    // Fetch users (Super Admin sees all users, Admin sees only assigned users)
    if ($user['role'] === 'super_admin') {
        $stmt = $pdo->query("SELECT id FROM users WHERE role = 'user'");
        $assigned_users = $stmt->fetchAll(PDO::FETCH_COLUMN);
    } else {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE assigned_admin_id = ?");
        $stmt->execute([$user['id']]);
        $assigned_users = $stmt->fetchAll(PDO::FETCH_COLUMN);
    }
    
    if (empty($assigned_users)) {
        echo json_encode([
            'status' => 'success',
            'data' => [
                'total_assigned_users' => 0,
                'total_reputation_points' => 0,
                'total_posts_by_users' => 0,
                'game_stats' => [],
                'recent_activity' => []
            ]
        ]);
        exit;
    }
    
    $user_ids_placeholder = implode(',', array_fill(0, count($assigned_users), '?'));
    
    // Total Reputation
    $stmt = $pdo->prepare("SELECT SUM(reputation_points) as total FROM users WHERE id IN ($user_ids_placeholder)");
    $stmt->execute($assigned_users);
    $rep_stats = $stmt->fetch();
    
    // Total Posts by Users
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM posts WHERE user_id IN ($user_ids_placeholder)");
    $stmt->execute($assigned_users);
    $total_posts = $stmt->fetchColumn();
    
    // Game Stats (Average scores)
    $stmt = $pdo->prepare("SELECT game_id, AVG(score) as avg_score FROM game_scores WHERE user_id IN ($user_ids_placeholder) GROUP BY game_id");
    $stmt->execute($assigned_users);
    $game_stats = $stmt->fetchAll();
    
    // Recent Activity (Posts)
    $stmt = $pdo->prepare("SELECT p.id, p.title, p.created_at, u.username 
                            FROM posts p 
                            JOIN users u ON p.user_id = u.id 
                            WHERE p.user_id IN ($user_ids_placeholder) 
                            ORDER BY p.created_at DESC LIMIT 10");
    $stmt->execute($assigned_users);
    $recent_activity = $stmt->fetchAll();
    
    // Fetch users list with details
    $stmt = $pdo->prepare("SELECT id, username FROM users WHERE id IN ($user_ids_placeholder)");
    $stmt->execute($assigned_users);
    $assigned_users_list = $stmt->fetchAll();
    
    echo json_encode([
        'status' => 'success',
        'data' => [
            'total_assigned_users' => count($assigned_users),
            'total_reputation_points' => (int)$rep_stats['total'],
            'total_posts_by_users' => (int)$total_posts,
            'game_stats' => $game_stats,
            'recent_activity' => $recent_activity,
            'assigned_users_list' => $assigned_users_list
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to fetch analytics: ' . $e->getMessage()]);
}
?>
