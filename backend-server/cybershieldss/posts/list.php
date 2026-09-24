<?php
// posts/list.php
require_once __DIR__ . '/../_core.php';
_auth();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$categoryId = isset($_GET['category_id']) ? intval($_GET['category_id']) : null;
$userId     = isset($_GET['user_id'])     ? intval($_GET['user_id'])     : null;

$sql    = 'SELECT p.*, u.username AS author_name, u.avatar AS author_avatar, u.`rank` AS author_rank, c.name AS category_name
           FROM posts p
           JOIN users u ON p.user_id = u.id
           LEFT JOIN categories c ON p.category_id = c.id';
$params = [];
$where  = [];

if ($categoryId) { $where[] = 'p.category_id = ?'; $params[] = $categoryId; }
if ($userId)     { $where[] = 'p.user_id = ?';     $params[] = $userId;     }
if ($where)      { $sql .= ' WHERE ' . implode(' AND ', $where); }
$sql .= ' ORDER BY p.created_at DESC';

try {
    $db   = _db();
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $posts = $stmt->fetchAll();

    foreach ($posts as &$post) {
        if ($post['is_anonymous'] == 1) {
            $post['user_id']       = 0;
            $post['author_name']   = 'Anonymous Agent';
            $post['author_avatar'] = 'anonymous_avatar.png';
            $post['author_rank']   = 'Ghost Protocol';
        }
    }
    echo json_encode(['status' => 'success', 'data' => $posts]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
