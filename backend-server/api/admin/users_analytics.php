<?php
// backend/api/admin/users_analytics.php

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

$adminId = intval($userData['user_id']);

$db = new Database();
$conn = $db->getConnection();

try {
    // Analytics: Total Users Assigned
    if ($userData['role'] === 'super_admin') {
        $stmtUsers = $conn->prepare("SELECT COUNT(*) as total_users, SUM(reputation_points) as total_reputation FROM users WHERE role = 'user'");
        $stmtUsers->execute();
        $userStats = $stmtUsers->fetch(PDO::FETCH_ASSOC);

        // Analytics: Fetch assigned users IDs for deeper analytics
        $stmtIds = $conn->prepare("SELECT id, username FROM users WHERE role = 'user'");
        $stmtIds->execute();
        $assignedUsers = $stmtIds->fetchAll(PDO::FETCH_ASSOC);
    } else {
        $stmtUsers = $conn->prepare("SELECT COUNT(*) as total_users, SUM(reputation_points) as total_reputation FROM users WHERE assigned_admin_id = ?");
        $stmtUsers->execute([$adminId]);
        $userStats = $stmtUsers->fetch(PDO::FETCH_ASSOC);

        // Analytics: Fetch assigned users IDs for deeper analytics
        $stmtIds = $conn->prepare("SELECT id, username FROM users WHERE assigned_admin_id = ?");
        $stmtIds->execute([$adminId]);
        $assignedUsers = $stmtIds->fetchAll(PDO::FETCH_ASSOC);
    }
    
    $userIds = array_column($assignedUsers, 'id');
    
    $totalPosts = 0;
    if (!empty($userIds)) {
        $inQuery = implode(',', array_fill(0, count($userIds), '?'));
        
        $stmtPosts = $conn->prepare("SELECT COUNT(*) FROM posts WHERE user_id IN ($inQuery)");
        $stmtPosts->execute($userIds);
        $totalPosts = intval($stmtPosts->fetchColumn());
    }

    echo json_encode([
        "status" => "success",
        "data" => [
            "total_assigned_users" => intval($userStats['total_users']),
            "total_reputation_points" => intval($userStats['total_reputation']),
            "total_posts_by_users" => $totalPosts,
            "assigned_users_list" => $assignedUsers
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
