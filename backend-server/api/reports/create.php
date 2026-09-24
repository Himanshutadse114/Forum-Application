<?php
// backend/api/reports/create.php

require_once __DIR__ . '/../../middleware/auth.php';

AuthMiddleware::getCorsHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['title']) || empty($data['description']) || empty($data['scam_type'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing required fields (title, description, scam_type)."]);
    exit;
}

$title = trim($data['title']);
$description = trim($data['description']);
$scamType = trim($data['scam_type']);
$evidenceUrl = !empty($data['evidence_url']) ? trim($data['evidence_url']) : null;

// Handle optional authenticated user
$userId = null;
$headers = getallheaders();
$authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : (isset($headers['authorization']) ? $headers['authorization'] : null);

if ($authHeader && strpos($authHeader, 'Bearer ') === 0) {
    $token = substr($authHeader, 7);
    $decoded = JWT::validate($token);
    if ($decoded) {
        $userId = $decoded['user_id'];
    }
}

$db = new Database();
$conn = $db->getConnection();

try {
    $conn->beginTransaction();

    $stmt = $conn->prepare("INSERT INTO reports (user_id, title, description, scam_type, evidence_url) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$userId, $title, $description, $scamType, $evidenceUrl]);
    $reportId = $conn->lastInsertId();

    $reputationEarned = 0;
    if ($userId) {
        // Gamification: Reward +30 reputation points for active scam reporting!
        $reputationEarned = 30;
        $stmt = $conn->prepare("UPDATE users SET reputation_points = reputation_points + ? WHERE id = ?");
        $stmt->execute([$reputationEarned, $userId]);

        // Insert Notification for reporting
        $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, type, title, message) VALUES (?, 'report_status', 'Scam Report Received', 'Your threat report has been recorded. Thank you for securing the grid! Reward: +30 XP.')");
        $notifStmt->execute([$userId]);
    }

    $conn->commit();

    echo json_encode([
        "status" => "success",
        "message" => "Scam report submitted successfully! " . ($reputationEarned > 0 ? "XP Reward: +{$reputationEarned} points." : "Submitted anonymously."),
        "data" => [
            "id" => $reportId,
            "title" => $title,
            "scam_type" => $scamType,
            "reputation_points_earned" => $reputationEarned
        ]
    ]);
} catch (PDOException $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
