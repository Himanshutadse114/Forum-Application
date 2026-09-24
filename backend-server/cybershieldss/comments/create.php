<?php
// comments/create.php
require_once __DIR__ . '/../_core.php';
$user = _auth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$data        = json_decode(file_get_contents('php://input'), true) ?? [];
$postId      = intval($data['post_id']      ?? 0);
$content     = trim($data['content']        ?? '');
$isAnonymous = intval($data['is_anonymous'] ?? 0);

if (!$postId || !$content) {
    http_response_code(400); echo json_encode(['status' => 'error', 'message' => 'post_id and content are required']); exit;
}

try {
    $db = _db();
    $db->prepare('INSERT INTO comments (post_id, user_id, content, is_anonymous) VALUES (?,?,?,?)')->execute([$postId, $user['id'], $content, $isAnonymous]);
    $commentId = $db->lastInsertId();
    $db->prepare('UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?')->execute([$postId]);
    echo json_encode(['status' => 'success', 'message' => 'Comment added successfully', 'data' => ['comment_id' => $commentId]]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
