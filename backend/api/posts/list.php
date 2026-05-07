<?php
// backend/api/posts/list.php

require_once __DIR__ . '/../../middleware/auth.php';

AuthMiddleware::getCorsHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$categoryId = isset($_GET['category_id']) ? intval($_GET['category_id']) : null;
$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;

$db = new Database();
$conn = $db->getConnection();

try {
    $sql = "SELECT p.*, u.username as author_name, u.avatar as author_avatar, u.`rank` as author_rank, c.name as category_name 
            FROM posts p
            JOIN users u ON p.user_id = u.id
            JOIN categories c ON p.category_id = c.id";
            
    $params = [];
    $conditions = [];
    if ($categoryId) {
        $conditions[] = "p.category_id = ?";
        $params[] = $categoryId;
    }
    if ($userId) {
        $conditions[] = "p.user_id = ?";
        $params[] = $userId;
    }
    
    if (!empty($conditions)) {
        $sql .= " WHERE " . implode(" AND ", $conditions);
    }
    
    $sql .= " ORDER BY p.created_at DESC";
    
    $stmt = $conn->prepare($sql);
    $stmt->execute($params);
    $posts = $stmt->fetchAll();

    // Sanitize anonymous posts
    foreach ($posts as &$post) {
        if ($post['is_anonymous'] == 1) {
            $post['user_id'] = 0;
            $post['author_name'] = 'Anonymous Agent';
            $post['author_avatar'] = 'anonymous_avatar.png';
            $post['author_rank'] = 'Ghost Protocol';
        }
    }

    echo json_encode([
        "status" => "success",
        "data" => $posts
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
