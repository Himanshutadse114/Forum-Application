<?php
// reports/analyze.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$content = $data['content'] ?? '';

if (empty($content)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Content to analyze is required']);
    exit;
}

// Simple keyword-based scoring
$keywords = [
    'urgency' => ['act now', 'urgent', 'limited time', 'expires', 'immediately'],
    'money' => ['win', 'prize', 'claim', 'lottery', 'inheritance', 'bank details', 'crypto'],
    'links' => ['click here', 'verify your account', 'login to', 'update your password'],
    'personal_info' => ['ssn', 'social security', 'password', 'credit card', 'pin']
];

$found_indicators = [];
$score = 0;

foreach ($keywords as $category => $terms) {
    foreach ($terms as $term) {
        if (stripos($content, $term) !== false) {
            $found_indicators[] = $term;
            $score += 20; // Arbitrary score per match
        }
    }
}

if ($score > 100) $score = 100;

$threat_level = 'LOW';
if ($score >= 70) {
    $threat_level = 'HIGH';
} elseif ($score >= 40) {
    $threat_level = 'MEDIUM';
}

$recommendations = ["Do not share personal information."];
if ($threat_level === 'HIGH') {
    $recommendations[] = "Do not click any links in this message.";
    $recommendations[] = "Report this to the relevant authorities.";
} elseif ($threat_level === 'MEDIUM') {
    $recommendations[] = "Be cautious and verify the sender.";
}

echo json_encode([
    'status' => 'success',
    'analyzer' => 'CyberShield AI v1.0 (Keyword Based)',
    'data' => [
        'scam_likelihood_score' => $score,
        'threat_level' => $threat_level,
        'confidence' => ($score > 0) ? '75%' : '90%',
        'indicators_found' => array_unique($found_indicators),
        'recommendations' => $recommendations
    ]
]);
?>
