<?php
// comments/list.php
require_once __DIR__ . '/../_core.php';
_auth();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$postId = isset($_GET['post_id']) ? intval($_GET['post_id']) : 0;
if (!$postId) {
    http_response_code(400); echo json_encode(['status' => 'error', 'message' => 'post_id is required']); exit;
}

try {
    $db   = _db();
    $stmt = $db->prepare('SELECT c.*, u.username AS author_name, u.avatar AS author_avatar, u.`rank` AS author_rank FROM comments c JOIN users u ON c.user_id = u.id WHERE c.post_id = ? ORDER BY c.created_at ASC');
    $stmt->execute([$postId]);
    $comments = $stmt->fetchAll();

    foreach ($comments as &$c) {
        if ($c['is_anonymous'] == 1) {
            $c['user_id']       = 0;
            $c['author_name']   = 'Anonymous Agent';
            $c['author_avatar'] = 'avatar_anon';
            $c['author_rank']   = 'Ghost Protocol';
        }
    }
    echo json_encode(['status' => 'success', 'data' => $comments]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
