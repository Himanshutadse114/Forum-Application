<?php
// reports/create.php
require_once __DIR__ . '/../_core.php';
$user = _auth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); echo json_encode(['status' => 'error', 'message' => 'Method not allowed']); exit;
}

$data        = json_decode(file_get_contents('php://input'), true) ?? [];
$title       = trim($data['title']        ?? '');
$description = trim($data['description'] ?? '');
$scamType    = trim($data['scam_type']   ?? '');
$evidenceUrl = $data['evidence_url'] ?? null;

if (!$title || !$description || !$scamType) {
    http_response_code(400); echo json_encode(['status' => 'error', 'message' => 'title, description and scam_type are required']); exit;
}

try {
    $db = _db();
    $db->prepare('INSERT INTO threat_reports (user_id, title, description, scam_type, evidence_url) VALUES (?,?,?,?,?)')->execute([$user['id'], $title, $description, $scamType, $evidenceUrl]);
    echo json_encode(['status' => 'success', 'message' => 'Threat report submitted', 'data' => ['report_id' => $db->lastInsertId()]]);
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
