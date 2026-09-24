<?php
// backend/api/comments/list.php

require_once __DIR__ . '/../../middleware/auth.php';

AuthMiddleware::getCorsHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

if (empty($_GET['post_id'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "post_id is required."]);
    exit;
}

$postId = intval($_GET['post_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    $stmt = $conn->prepare("SELECT c.*, u.username as author_name, u.avatar as author_avatar, u.`rank` as author_rank 
                            FROM comments c
                            JOIN users u ON c.user_id = u.id
                            WHERE c.post_id = ?
                            ORDER BY c.created_at ASC");
    $stmt->execute([$postId]);
    $comments = $stmt->fetchAll();

    // Sanitize anonymous comments
    foreach ($comments as &$comment) {
        if ($comment['is_anonymous'] == 1) {
            $comment['user_id'] = 0;
            $comment['author_name'] = 'Anonymous Agent';
            $comment['author_avatar'] = 'anonymous_avatar.png';
            $comment['author_rank'] = 'Ghost Protocol';
        }
    }

    echo json_encode([
        "status" => "success",
        "data" => $comments
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
