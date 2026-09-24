<?php
// auth/update_reputation.php
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

$points = isset($data['reputation_points']) ? (int)$data['reputation_points'] : 0;
$action = $data['action'] ?? 'add';

if ($points <= 0) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Points must be greater than 0']);
    exit;
}

$newReputation = $user['reputation_points'];
if ($action === 'add') {
    $newReputation += $points;
} elseif ($action === 'subtract') {
    $newReputation -= $points;
    if ($newReputation < 0) $newReputation = 0;
} else {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Invalid action']);
    exit;
}

$newRank = calculateRank($newReputation);

try {
    global $pdo;
    $stmt = $pdo->prepare("UPDATE users SET reputation_points = ?, `rank` = ? WHERE id = ?");
    $stmt->execute([$newReputation, $newRank, $user['id']]);
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Reputation updated successfully',
        'data' => [
            'new_reputation' => $newReputation,
            'new_rank' => $newRank
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Update failed: ' . $e->getMessage()]);
}
?>
