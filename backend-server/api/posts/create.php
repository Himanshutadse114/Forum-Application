<?php
// backend/api/posts/create.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['category_id']) || empty($data['title']) || empty($data['content'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing required fields (category_id, title, content)."]);
    exit;
}

$categoryId = intval($data['category_id']);
$title = trim($data['title']);
$content = trim($data['content']);
$isAnonymous = !empty($data['is_anonymous']) ? 1 : 0;
$userId = $userData['user_id'];

if (strlen($title) < 5 || strlen($title) > 150) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Title must be between 5 and 150 characters."]);
    exit;
}

if (strlen($content) < 10) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Content must be at least 10 characters."]);
    exit;
}

$db = new Database();
$conn = $db->getConnection();

try {
    // Check if category exists
    $stmt = $conn->prepare("SELECT id FROM categories WHERE id = ?");
    $stmt->execute([$categoryId]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "Category not found."]);
        exit;
    }

    $conn->beginTransaction();

    // Create post
    $stmt = $conn->prepare("INSERT INTO posts (user_id, category_id, title, content, is_anonymous) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$userId, $categoryId, $title, $content, $isAnonymous]);
    $postId = $conn->lastInsertId();

    // Gamification: Reward +15 reputation points for posting cybersecurity content!
    $pointsAwarded = 15;
    $stmt = $conn->prepare("UPDATE users SET reputation_points = reputation_points + ? WHERE id = ?");
    $stmt->execute([$pointsAwarded, $userId]);

    // Fetch current reputation points to determine Rank promotion
    $stmt = $conn->prepare("SELECT reputation_points, `rank` FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $userStats = $stmt->fetch();
    $currentPoints = $userStats['reputation_points'];
    $currentRank = $userStats['rank'];

    // Rank evaluation logic
    $newRank = 'WhiteHat Trainee';
    if ($currentPoints >= 500) {
        $newRank = 'Elite Cyber Commander';
    } elseif ($currentPoints >= 250) {
        $newRank = 'Threat Hunter';
    } elseif ($currentPoints >= 100) {
        $newRank = 'Security Analyst';
    } elseif ($currentPoints >= 40) {
        $newRank = 'Cyber Scout';
    }

    if ($newRank !== $currentRank) {
        // Upgrade Rank
        $stmt = $conn->prepare("UPDATE users SET `rank` = ? WHERE id = ?");
        $stmt->execute([$newRank, $userId]);

        // Unlock achievement badge
        $badgeName = $newRank;
        $badgeIcon = 'military_tech';
        $badgeDesc = "Promoted to the rank of {$newRank} for outstanding contributions to community digital safety.";
        
        $badgeStmt = $conn->prepare("INSERT INTO achievements (user_id, badge_name, badge_icon, description) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE unlocked_at = CURRENT_TIMESTAMP");
        $badgeStmt->execute([$userId, $badgeName, $badgeIcon, $badgeDesc]);

        // Create notification for promotion
        $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, type, title, message) VALUES (?, 'achievement', 'Promoted!', 'Congratulations! You have been promoted to: {$newRank}. Badge unlocked!')");
        $notifStmt->execute([$userId]);
    }

    $conn->commit();

    echo json_encode([
        "status" => "success",
        "message" => "Post created successfully! Reputation rewarded: +{$pointsAwarded} XP.",
        "data" => [
            "id" => $postId,
            "title" => $title,
            "is_anonymous" => $isAnonymous,
            "reputation_points" => $currentPoints + $pointsAwarded,
            "rank" => $newRank
        ]
    ]);
} catch (PDOException $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
