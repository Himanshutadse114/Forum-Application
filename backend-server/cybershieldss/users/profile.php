<?php
// users/profile.php
require_once __DIR__ . '/../_core.php';
$me = _auth();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$targetId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
if (!$targetId) {
    http_response_code(400); echo json_encode(['status' => 'error', 'message' => 'user_id is required']); exit;
}

try {
    $db   = _db();
    $stmt = $db->prepare('SELECT id, username, email, role, reputation_points, `rank`, avatar, created_at FROM users WHERE id = ?');
    $stmt->execute([$targetId]);
    $profile = $stmt->fetch();

    if (!$profile) { http_response_code(404); echo json_encode(['status' => 'error', 'message' => 'User not found']); exit; }

    $fcnt = $db->prepare('SELECT COUNT(*) FROM follows WHERE following_id = ?'); $fcnt->execute([$targetId]);
    $gcnt = $db->prepare('SELECT COUNT(*) FROM follows WHERE follower_id = ?');  $gcnt->execute([$targetId]);
    $iflw = $db->prepare('SELECT id FROM follows WHERE follower_id = ? AND following_id = ?'); $iflw->execute([$me['id'], $targetId]);

    $profile['followers_count'] = $fcnt->fetchColumn();
    $profile['following_count'] = $gcnt->fetchColumn();
    $profile['is_following']    = (bool)$iflw->fetch();

    echo json_encode(['status' => 'success', 'data' => $profile]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
