<?php
// users/submit_score.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../helpers/rank.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$user = authenticate();
$data = json_decode(file_get_contents("php://input"), true);

$game_id = $data['game_id'] ?? '';
$score = isset($data['score']) ? (int)$data['score'] : 0;

if (empty($game_id) || $score <= 0) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Game ID and valid score are required']);
    exit;
}

// Anti-cheat: Validate max score
$max_scores = [
    'cyber_match' => 1000,
    'firewall_drone' => 500,
    'shield_maze' => 100,
    'patrol' => 30,
    'trivia' => 30,
    'password' => 30
];

if (isset($max_scores[$game_id]) && $score > $max_scores[$game_id]) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Score exceeds maximum allowed limit']);
    exit;
}

try {
    global $pdo;
    $pdo->beginTransaction();
    
    // 1. Insert into game_scores
    $stmt = $pdo->prepare("INSERT INTO game_scores (user_id, game_id, score) VALUES (?, ?, ?)");
    $stmt->execute([$user['id'], $game_id, $score]);
    
    // 2. Update/Insert into game_leaderboard
    $stmt = $pdo->prepare("INSERT INTO game_leaderboard (user_id, game_id, best_score, play_count) 
                            VALUES (?, ?, ?, 1) 
                            ON DUPLICATE KEY UPDATE 
                            best_score = IF(? > best_score, ?, best_score),
                            play_count = play_count + 1");
    $stmt->execute([$user['id'], $game_id, $score, $score, $score]);
    
    // 3. Update user reputation and rank
    $newReputation = $user['reputation_points'] + $score;
    $newRank = calculateRank($newReputation);
    
    $stmt = $pdo->prepare("UPDATE users SET reputation_points = ?, `rank` = ? WHERE id = ?");
    $stmt->execute([$newReputation, $newRank, $user['id']]);
    
    // Check if it was a new best score
    $stmt = $pdo->prepare("SELECT best_score FROM game_leaderboard WHERE user_id = ? AND game_id = ?");
    $stmt->execute([$user['id'], $game_id]);
    $best_score = $stmt->fetchColumn();
    $is_new_best = ($score >= $best_score);
    
    $pdo->commit();
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Score submitted successfully',
        'data' => [
            'new_reputation' => $newReputation,
            'new_rank' => $newRank,
            'is_new_best' => $is_new_best,
            'best_score' => $best_score
        ]
    ]);
} catch (PDOException $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to submit score: ' . $e->getMessage()]);
}
?>
