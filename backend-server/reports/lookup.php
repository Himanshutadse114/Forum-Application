<?php
// reports/lookup.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/auth.php';

$user = authenticate();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$query = isset($_GET['query']) ? trim($_GET['query']) : '';

if (empty($query)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Query parameter is required']);
    exit;
}

// Minimal length check to avoid broad matches
if (strlen($query) < 3) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Query parameter must be at least 3 characters long']);
    exit;
}

// 1. Static high-risk indicator blacklist (inspired by AntiCyScam's local catalog)
$static_blacklist = [
    // Fake banking / wallet domain patterns
    'paypal-verify-user.net', 'pay-auth-portal.ru', 'login-axisbank.verification-secure.in',
    'sbi-kyc-update.com', 'secure-bank-login-verification.xyz', 'crypto-bonus-airdrop.org',
    // Known scam phone numbers / formats (examples)
    '+919876543210', '18001112222', '0912345678',
    // Fraudulent UPI formats
    'scammer@upi', 'prize-claim@ybl', 'lottery-win@paytm'
];

$matched_static = false;
foreach ($static_blacklist as $blacklist_item) {
    if (stripos($query, $blacklist_item) !== false || stripos($blacklist_item, $query) !== false) {
        $matched_static = true;
        break;
    }
}

try {
    global $pdo;
    
    // 2. Query community ledger (threat_reports) for matches
    // Look in title, description, and evidence_url
    $sql = "SELECT id, title, scam_type, status, created_at 
            FROM threat_reports 
            WHERE title LIKE :q 
               OR description LIKE :q 
               OR evidence_url LIKE :q 
            ORDER BY created_at DESC 
            LIMIT 5";
            
    $stmt = $pdo->prepare($sql);
    $search_param = "%" . $query . "%";
    $stmt->execute(['q' => $search_param]);
    $db_matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $flag_count = count($db_matches);
    $is_flagged = ($flag_count > 0) || $matched_static;
    
    // Calculate threat level
    $threat_level = 'SAFE';
    if ($matched_static) {
        $threat_level = 'HIGH';
    } elseif ($flag_count >= 3) {
        $threat_level = 'HIGH';
    } elseif ($flag_count > 0) {
        $threat_level = 'MEDIUM';
    }
    
    $explanation = 'This item is not currently flagged in our community database.';
    if ($threat_level === 'HIGH') {
        $explanation = 'WARNING: This query has been identified in our high-risk blacklist or matches multiple community threat reports.';
    } elseif ($threat_level === 'MEDIUM') {
        $explanation = 'CAUTION: This query matches recent scam reports submitted by other users. Verify details carefully.';
    }

    echo json_encode([
        'status' => 'success',
        'data' => [
            'query' => $query,
            'is_flagged' => $is_flagged,
            'threat_level' => $threat_level,
            'flag_count' => $flag_count,
            'explanation' => $explanation,
            'community_matches' => $db_matches,
            'source' => $matched_static ? 'CyberShield System Blacklist' : 'Community Threat Ledger'
        ]
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Database search failed: ' . $e->getMessage()]);
}
?>
