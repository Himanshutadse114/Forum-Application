<?php
// backend/api/users/submit_score.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once __DIR__ . '/../../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['user_id']) || !isset($data['game_id']) || !isset($data['score'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Incomplete parameters. user_id, game_id, and score are required."]);
    exit;
}

$userId = intval($data['user_id']);
$gameId = trim($data['game_id']);
$score = intval($data['score']);

// Map game IDs to clean, separate table names
$tableMapping = [
    'shield_maze'  => 'scores_shield_maze',
    'patrol'       => 'scores_phishing_patrol',
    'trivia'       => 'scores_cyber_trivia',
    'flappy'       => 'scores_flying_shield',
    'password'     => 'scores_password_cracker',
    'cyber_match'  => 'scores_cyber_match'
];

$tableName = isset($tableMapping[$gameId]) ? $tableMapping[$gameId] : 'scores_game_' . preg_replace('/[^a-zA-Z0-9_]/', '', $gameId);

$database = new Database();
$conn = $database->getConnection();

try {
    // Automatically ensure the separate table for this specific game exists in the MySQL database on-the-fly
    $createTableQuery = "CREATE TABLE IF NOT EXISTS `$tableName` (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        score INT NOT NULL,
        submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";
    $conn->exec($createTableQuery);

    // Automatically ensure the leaderboard table exists in the MySQL database on-the-fly
    $createLeaderboardQuery = "CREATE TABLE IF NOT EXISTS leaderboard (
        user_id INT PRIMARY KEY,
        total_score INT DEFAULT 0,
        rank VARCHAR(50) DEFAULT 'Recruit',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";
    $conn->exec($createLeaderboardQuery);

    // Automatically ensure the central game_scores table exists in the MySQL database on-the-fly
    $createGameScoresQuery = "CREATE TABLE IF NOT EXISTS `game_scores` (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        game_id VARCHAR(50) NOT NULL,
        score INT NOT NULL,
        submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";
    $conn->exec($createGameScoresQuery);

    // 1. Insert detailed game score entry into the separate table
    $query = "INSERT INTO `$tableName` (user_id, score) VALUES (:user_id, :score)";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $userId);
    $stmt->bindParam(':score', $score);
    
    if ($stmt->execute()) {
        // 1b. Insert into the central game_scores table for admin timeline
        $queryCentral = "INSERT INTO `game_scores` (user_id, game_id, score) VALUES (:user_id, :game_id, :score)";
        $stmtCentral = $conn->prepare($queryCentral);
        $stmtCentral->bindParam(':user_id', $userId);
        $stmtCentral->bindParam(':game_id', $gameId);
        $stmtCentral->bindParam(':score', $score);
        $stmtCentral->execute();
        // 2. Automatically update the user's total reputation points inside the users table
        $queryUser = "SELECT reputation_points FROM users WHERE id = :user_id";
        $stmtUser = $conn->prepare($queryUser);
        $stmtUser->bindParam(':user_id', $userId);
        $stmtUser->execute();
        $user = $stmtUser->fetch();
        
        if ($user) {
            $newRep = intval($user['reputation_points']) + $score;
            
            // Determine rank based on new reputation points
            $rank = 'Recruit';
            if ($newRep >= 1000) {
                $rank = 'Cyber Commander';
            } elseif ($newRep >= 500) {
                $rank = 'Security Expert';
            } elseif ($newRep >= 250) {
                $rank = 'Security Analyst';
            }
            
            // 2a. Update the main users table
            $queryUpdate = "UPDATE users SET reputation_points = :rep, rank = :rank WHERE id = :user_id";
            $stmtUpdate = $conn->prepare($queryUpdate);
            $stmtUpdate->bindParam(':rep', $newRep);
            $stmtUpdate->bindParam(':rank', $rank);
            $stmtUpdate->bindParam(':user_id', $userId);
            $stmtUpdate->execute();

            // 2b. Automatically insert or update the dedicated leaderboard table
            $queryLeaderboard = "INSERT INTO leaderboard (user_id, total_score, rank) VALUES (:user_id, :rep, :rank)
                ON DUPLICATE KEY UPDATE total_score = :rep, rank = :rank";
            $stmtLeaderboard = $conn->prepare($queryLeaderboard);
            $stmtLeaderboard->bindParam(':user_id', $userId);
            $stmtLeaderboard->bindParam(':rep', $newRep);
            $stmtLeaderboard->bindParam(':rank', $rank);
            $stmtLeaderboard->execute();
        }

        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "message" => "Score submitted successfully and total reputation updated.",
            "data" => [
                "game_id" => $gameId,
                "score" => $score,
                "total_reputation" => isset($newRep) ? $newRep : 0,
                "rank" => isset($rank) ? $rank : 'Recruit'
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Failed to write score to database."]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
