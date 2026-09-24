<?php
// auth/profile.php
require_once __DIR__ . '/../_core.php';
$user = _auth();
$db   = _db();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    echo json_encode(['status' => 'success', 'data' => $user]);

} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $data     = json_decode(file_get_contents('php://input'), true) ?? [];
    $username = trim($data['username'] ?? $user['username']);
    $avatar   = $data['avatar'] ?? $user['avatar'];

    if ($username !== $user['username']) {
        $chk = $db->prepare('SELECT id FROM users WHERE username = ? AND id != ?');
        $chk->execute([$username, $user['id']]);
        if ($chk->fetch()) { http_response_code(409); echo json_encode(['status' => 'error', 'message' => 'Username already exists']); exit; }
    }

    try {
        $db->prepare('UPDATE users SET username = ?, avatar = ? WHERE id = ?')->execute([$username, $avatar, $user['id']]);
        $stmt = $db->prepare('SELECT id, username, email, role, reputation_points, `rank`, avatar FROM users WHERE id = ?');
        $stmt->execute([$user['id']]);
        echo json_encode(['status' => 'success', 'message' => 'Profile updated', 'data' => $stmt->fetch()]);
    } catch (PDOException $e) {
        http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    }
} else {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
}
