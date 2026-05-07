<?php
// backend/api/posts/like.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['post_id'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "post_id is required."]);
    exit;
}

$postId = intval($data['post_id']);
$userId = $userData['user_id'];

$db = new Database();
$conn = $db->getConnection();

try {
    // Check if post exists
    $stmt = $conn->prepare("SELECT id, user_id FROM posts WHERE id = ?");
    $stmt->execute([$postId]);
    $post = $stmt->fetch();

    if (!$post) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "Post not found."]);
        exit;
    }

    $conn->beginTransaction();

    // Check if already liked
    $stmt = $conn->prepare("SELECT id FROM likes WHERE user_id = ? AND post_id = ?");
    $stmt->execute([$userId, $postId]);
    $like = $stmt->fetch();

    if ($like) {
        // Unlike post
        $stmt = $conn->prepare("DELETE FROM likes WHERE user_id = ? AND post_id = ?");
        $stmt->execute([$userId, $postId]);

        // Decrement likes count
        $stmt = $conn->prepare("UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = ?");
        $stmt->execute([$postId]);

        $action = "unliked";
    } else {
        // Like post
        $stmt = $conn->prepare("INSERT INTO likes (user_id, post_id) VALUES (?, ?)");
        $stmt->execute([$userId, $postId]);

        // Increment likes count
        $stmt = $conn->prepare("UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?");
        $stmt->execute([$postId]);

        // Notify author if they liked it (and author is not the same user)
        if ($post['user_id'] !== $userId) {
            $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, type, title, message) VALUES (?, 'like', 'New Like!', ?)");
            $notifMessage = "User @{$userData['username']} liked your thread.";
            $notifStmt->execute([$post['user_id'], $notifMessage]);
        }

        $action = "liked";
    }

    $conn->commit();

    echo json_encode([
        "status" => "success",
        "action" => $action,
        "message" => "Post {$action} successfully."
    ]);
} catch (PDOException $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
