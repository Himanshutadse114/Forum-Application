<?php
// posts/create.php
require_once __DIR__ . '/../_core.php';
$user = _auth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$data        = json_decode(file_get_contents('php://input'), true) ?? [];
$categoryId  = intval($data['category_id']  ?? 0);
$title       = trim($data['title']          ?? '');
$content     = trim($data['content']        ?? '');
$isAnonymous = intval($data['is_anonymous'] ?? 0);

if (!$categoryId || !$title || !$content) {
    http_response_code(400); echo json_encode(['status' => 'error', 'message' => 'category_id, title and content are required']); exit;
}

try {
    $db = _db();

    // Auto-create Security Advisories category if needed
    if ($categoryId === 9999) {
        $db->prepare("INSERT IGNORE INTO categories (id, name, description, icon) VALUES (9999, 'Security Advisories & Fraud Alerts', 'Daily AI-curated safety warnings.', 'security')")->execute();
    } else {
        $chk = $db->prepare('SELECT id FROM categories WHERE id = ?');
        $chk->execute([$categoryId]);
        if (!$chk->fetch()) { http_response_code(404); echo json_encode(['status' => 'error', 'message' => 'Category not found']); exit; }
    }

    $db->prepare('INSERT INTO posts (user_id, category_id, title, content, is_anonymous) VALUES (?,?,?,?,?)')->execute([$user['id'], $categoryId, $title, $content, $isAnonymous]);
    echo json_encode(['status' => 'success', 'message' => 'Post created successfully', 'data' => ['post_id' => $db->lastInsertId()]]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
