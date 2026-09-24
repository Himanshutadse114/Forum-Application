<?php
// auth/profile.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    echo json_encode([
        'status' => 'success',
        'data' => $user
    ]);
} elseif ($method === 'PUT') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    $username = $data['username'] ?? $user['username'];
    $avatar = $data['avatar'] ?? $user['avatar'];
    
    // Validate if username is being changed and if it's unique
    if ($username !== $user['username']) {
        global $pdo;
        $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? AND id != ?");
        $stmt->execute([$username, $user['id']]);
        if ($stmt->fetch()) {
            http_response_code(409);
            echo json_encode(['status' => 'error', 'message' => 'Username already exists']);
            exit;
        }
    }
    
    try {
        global $pdo;
        $stmt = $pdo->prepare("UPDATE users SET username = ?, avatar = ? WHERE id = ?");
        $stmt->execute([$username, $avatar, $user['id']]);
        
        // Fetch updated user
        $stmt = $pdo->prepare("SELECT id, username, email, role, reputation_points, `rank`, avatar FROM users WHERE id = ?");
        $stmt->execute([$user['id']]);
        $updatedUser = $stmt->fetch();
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Profile updated successfully',
            'data' => $updatedUser
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Update failed: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
}
?>
