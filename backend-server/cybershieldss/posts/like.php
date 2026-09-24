<?php
// posts/like.php
require_once __DIR__ . '/../_core.php';
$user = _auth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$data   = json_decode(file_get_contents('php://input'), true) ?? [];
$postId = intval($data['post_id'] ?? 0);

if (!$postId) {
    http_response_code(400); echo json_encode(['status' => 'error', 'message' => 'post_id is required']); exit;
}

try {
    $db  = _db();
    $chk = $db->prepare('SELECT id FROM likes WHERE user_id = ? AND post_id = ?');
    $chk->execute([$user['id'], $postId]);
    $existing = $chk->fetch();

    if ($existing) {
        $db->prepare('DELETE FROM likes WHERE id = ?')->execute([$existing['id']]);
        $db->prepare('UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = ?')->execute([$postId]);
        $action = 'unliked';
    } else {
        $db->prepare('INSERT INTO likes (user_id, post_id) VALUES (?,?)')->execute([$user['id'], $postId]);
        $db->prepare('UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?')->execute([$postId]);
        $action = 'liked';
    }

    $cnt = $db->prepare('SELECT likes_count FROM posts WHERE id = ?');
    $cnt->execute([$postId]);
    echo json_encode(['status' => 'success', 'message' => "Post $action", 'data' => ['action' => $action, 'likes_count' => $cnt->fetchColumn()]]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
