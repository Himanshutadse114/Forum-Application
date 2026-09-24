<?php
// backend/api/reports/list.php

require_once __DIR__ . '/../../middleware/auth.php';

AuthMiddleware::getCorsHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$db = new Database();
$conn = $db->getConnection();

try {
    // Standard public threat list
    $stmt = $conn->prepare("SELECT r.*, u.username as reporter_name 
                            FROM reports r
                            LEFT JOIN users u ON r.user_id = u.id
                            ORDER BY r.created_at DESC");
    $stmt->execute();
    $reports = $stmt->fetchAll();

    foreach ($reports as &$report) {
        if (!$report['user_id']) {
            $report['reporter_name'] = 'Anonymous Sentinel';
        }
    }

    echo json_encode([
        "status" => "success",
        "data" => $reports
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
