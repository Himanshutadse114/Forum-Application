<?php
// backend/api/comments/create.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['post_id']) || empty($data['content'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing required fields (post_id, content)."]);
    exit;
}

$postId = intval($data['post_id']);
$content = trim($data['content']);
$isAnonymous = !empty($data['is_anonymous']) ? 1 : 0;
$userId = $userData['user_id'];

if (strlen($content) < 3) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Comment content must be at least 3 characters."]);
    exit;
}

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

    // Create comment
    $stmt = $conn->prepare("INSERT INTO comments (post_id, user_id, content, is_anonymous) VALUES (?, ?, ?, ?)");
    $stmt->execute([$postId, $userId, $content, $isAnonymous]);
    $commentId = $conn->lastInsertId();

    // Increment comments count on post
    $stmt = $conn->prepare("UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?");
    $stmt->execute([$postId]);

    // Gamification: Reward +5 reputation points for commenting
    $stmt = $conn->prepare("UPDATE users SET reputation_points = reputation_points + 5 WHERE id = ?");
    $stmt->execute([$userId]);

    // Notify post author (if author is not the commenter)
    if ($post['user_id'] !== $userId) {
        $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, type, title, message) VALUES (?, 'comment', 'New Comment!', ?)");
        $authorName = $isAnonymous ? 'An anonymous agent' : "@{$userData['username']}";
        $notifMessage = "{$authorName} commented on your thread.";
        $notifStmt->execute([$post['user_id'], $notifMessage]);
    }

    $conn->commit();

    echo json_encode([
        "status" => "success",
        "message" => "Comment posted successfully! Reward: +5 XP.",
        "data" => [
            "id" => $commentId,
            "post_id" => $postId,
            "content" => $content,
            "is_anonymous" => $isAnonymous
        ]
    ]);
} catch (PDOException $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
