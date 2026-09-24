<?php
// backend/api/admin/user_detail.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

// Ensure the caller is an admin or super_admin
if ($userData['role'] !== 'admin' && $userData['role'] !== 'super_admin') {
    http_response_code(403);
    echo json_encode(["status" => "error", "message" => "Forbidden. Admin access required."]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

if (!isset($_GET['user_id'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing user_id parameter."]);
    exit;
}

$targetUserId = intval($_GET['user_id']);
$adminId = intval($userData['user_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    // 1. Verify this user is assigned to this admin (or caller is super_admin)
    if ($userData['role'] !== 'super_admin') {
        $stmtCheck = $conn->prepare("SELECT id FROM users WHERE id = ? AND assigned_admin_id = ?");
        $stmtCheck->execute([$targetUserId, $adminId]);
        if (!$stmtCheck->fetch()) {
            http_response_code(403);
            echo json_encode(["status" => "error", "message" => "Forbidden. You can only view details of users assigned to you."]);
            exit;
        }
    }

    // 2. Fetch User Profile
    $stmtProfile = $conn->prepare("SELECT id, username, email, avatar, reputation_points, `rank`, created_at FROM users WHERE id = ?");
    $stmtProfile->execute([$targetUserId]);
    $userProfile = $stmtProfile->fetch(PDO::FETCH_ASSOC);

    if (!$userProfile) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found."]);
        exit;
    }

    // Automatically ensure the central game_scores table exists
    $createGameScoresQuery = "CREATE TABLE IF NOT EXISTS `game_scores` (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        game_id VARCHAR(50) NOT NULL,
        score INT NOT NULL,
        submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";
    $conn->exec($createGameScoresQuery);

    // 3. Fetch Game Scores (timeline)
    $stmtScores = $conn->prepare("SELECT game_id, score, submitted_at FROM game_scores WHERE user_id = ? ORDER BY submitted_at ASC");
    $stmtScores->execute([$targetUserId]);
    $gameScores = $stmtScores->fetchAll(PDO::FETCH_ASSOC);

    // 4. Fetch Recent Posts
    $stmtPosts = $conn->prepare("SELECT title, created_at, likes_count, comments_count FROM posts WHERE user_id = ? ORDER BY created_at DESC LIMIT 5");
    $stmtPosts->execute([$targetUserId]);
    $recentPosts = $stmtPosts->fetchAll(PDO::FETCH_ASSOC);

    // 5. Fetch Achievements
    $stmtAchievements = $conn->prepare("SELECT badge_name, badge_icon, unlocked_at FROM achievements WHERE user_id = ? ORDER BY unlocked_at DESC");
    $stmtAchievements->execute([$targetUserId]);
    $achievements = $stmtAchievements->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => [
            "profile" => $userProfile,
            "game_scores" => $gameScores,
            "recent_posts" => $recentPosts,
            "achievements" => $achievements
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
