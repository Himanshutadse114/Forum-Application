<?php
// categories/list.php
require_once __DIR__ . '/../_core.php';
_auth();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

try {
    $db = _db();
    // Ensure Security Advisories channel exists
    $db->prepare("INSERT IGNORE INTO categories (id, name, description, icon) VALUES (9999, 'Security Advisories & Fraud Alerts', 'Daily AI-curated safety warnings and scam alerts.', 'security')")->execute();

    $stmt = $db->query('SELECT id, name, description, icon FROM categories ORDER BY id ASC');
    echo json_encode(['status' => 'success', 'data' => $stmt->fetchAll()]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
