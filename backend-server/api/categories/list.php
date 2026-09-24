<?php
// backend/api/categories/list.php

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
    // Ensure Security Advisories & Fraud Alerts channel always exists
    $conn->prepare("INSERT IGNORE INTO categories (id, name, description, icon) VALUES (9999, 'Security Advisories & Fraud Alerts', 'Daily AI-curated safety warnings and scam alerts.', 'security')")->execute();

    $stmt = $conn->prepare("SELECT * FROM categories ORDER BY id ASC");
    $stmt->execute();
    $categories = $stmt->fetchAll();

    echo json_encode([
        "status" => "success",
        "data" => $categories
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
