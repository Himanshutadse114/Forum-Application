<?php
// reports/create.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$title = $data['title'] ?? '';
$description = $data['description'] ?? '';
$scam_type = $data['scam_type'] ?? '';
$evidence_url = $data['evidence_url'] ?? null;

if (empty($title) || empty($description) || empty($scam_type)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Title, description, and scam type are required']);
    exit;
}

try {
    global $pdo;
    $stmt = $pdo->prepare("INSERT INTO threat_reports (user_id, title, description, scam_type, evidence_url) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$user['id'], $title, $description, $scam_type, $evidence_url]);
    
    $reportId = $pdo->lastInsertId();
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Threat report submitted successfully',
        'data' => ['report_id' => $reportId]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to submit report: ' . $e->getMessage()]);
}
?>
