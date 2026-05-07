<?php
// backend/api/users/profile.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

if (empty($_GET['user_id'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing user_id parameter."]);
    exit;
}

$targetUserId = intval($_GET['user_id']);
$loggedInUserId = intval($userData['user_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    $stmt = $conn->prepare("SELECT id, username, email, reputation_points, `rank` FROM users WHERE id = ?");
    $stmt->execute([$targetUserId]);
    $user = $stmt->fetch();

    if (!$user) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found."]);
        exit;
    }

    // Count posts
    $stmt = $conn->prepare("SELECT COUNT(*) FROM posts WHERE user_id = ?");
    $stmt->execute([$targetUserId]);
    $postsCount = intval($stmt->fetchColumn());

    // Count followers
    $stmt = $conn->prepare("SELECT COUNT(*) FROM follows WHERE followed_id = ?");
    $stmt->execute([$targetUserId]);
    $followersCount = intval($stmt->fetchColumn());

    // Count following
    $stmt = $conn->prepare("SELECT COUNT(*) FROM follows WHERE follower_id = ?");
    $stmt->execute([$targetUserId]);
    $followingCount = intval($stmt->fetchColumn());

    // Is following
    $stmt = $conn->prepare("SELECT COUNT(*) FROM follows WHERE follower_id = ? AND followed_id = ?");
    $stmt->execute([$loggedInUserId, $targetUserId]);
    $isFollowing = intval($stmt->fetchColumn()) > 0 ? 1 : 0;

    echo json_encode([
        "status" => "success",
        "data" => [
            "id" => intval($user['id']),
            "username" => $user['username'],
            "email" => $user['email'],
            "reputation_points" => intval($user['reputation_points']),
            "rank" => $user['rank'],
            "posts_count" => $postsCount,
            "followers_count" => $followersCount,
            "following_count" => $followingCount,
            "is_following" => $isFollowing
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
