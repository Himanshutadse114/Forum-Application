<?php
// reports/list.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

try {
    global $pdo;
    $stmt = $pdo->query("SELECT r.*, u.username, u.avatar 
                         FROM threat_reports r 
                         LEFT JOIN users u ON r.user_id = u.id 
                         ORDER BY r.created_at DESC");
    $reports = $stmt->fetchAll();
    
    echo json_encode([
        'status' => 'success',
        'data' => $reports
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to fetch reports: ' . $e->getMessage()]);
}
?>
