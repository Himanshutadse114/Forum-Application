<?php
// backend/api/reports/analyze.php

require_once __DIR__ . '/../../middleware/auth.php';

AuthMiddleware::getCorsHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['content'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Text content is required for analysis."]);
    exit;
}

$content = trim($data['content']);
$lowered = strtolower($content);

// Heuristic Risk Assessment Engine
$riskPoints = 0;
$indicators = [];
$threatLevel = "LOW";
$confidence = "85%";

// Check 1: Urgency indicators
if (preg_include(['urgent', 'immediate', 'act now', 'expires', 'limited time', 'within 24 hours', 'hurry'], $lowered)) {
    $riskPoints += 25;
    $indicators[] = "High Urgency & Psychological Pressure";
}

// Check 2: Financial/Gift Card requests
if (preg_include(['gift card', 'bitcoin', 'crypto', 'wire transfer', 'western union', 'payment', 'fee', 'overdue'], $lowered)) {
    $riskPoints += 30;
    $indicators[] = "Unorthodox Payment Request (Crypto/Gift Cards)";
}

// Check 3: Credential harvesting keywords
if (preg_include(['verify account', 'login', 'password', 'security update', 'restore access', 'ssn', 'social security', 'credit card'], $lowered)) {
    $riskPoints += 35;
    $indicators[] = "Credential Harvesting / Identity Theft Attempt";
}

// Check 4: Suspicious domains / URLs
if (preg_include(['http://', '.apk', '.zip', 'click here', 'download link', 'shorturl', 'tinyurl'], $lowered)) {
    $riskPoints += 20;
    $indicators[] = "Suspicious Link / Executable Payload Referral";
}

// Check 5: General generic greeting
if (preg_include(['dear customer', 'dear user', 'sir/madam', 'valued client'], $lowered)) {
    $riskPoints += 15;
    $indicators[] = "Impersonal Generic Greeting";
}

// Calculate Risk Score (capped at 100)
$riskScore = min(100, $riskPoints);

// Determine Threat Level
if ($riskScore >= 75) {
    $threatLevel = "CRITICAL / HIGH RISK";
} elseif ($riskScore >= 40) {
    $threatLevel = "MODERATE SUSPICION";
} else {
    // If there are no indicators but text is extremely short, default to some low risk
    $riskScore = max(5, $riskScore);
    $threatLevel = "SAFE / NEGLIGIBLE RISK";
}

// Generate Security Recommendations based on indicators
$recommendations = [];
if ($riskScore >= 75) {
    $recommendations[] = "❌ DO NOT click any links, open attachments, or download files referenced in this message.";
    $recommendations[] = "❌ DO NOT reply to the sender or provide any personal information, passwords, or credit card numbers.";
    $recommendations[] = "🔒 Report this email/SMS immediately to your IT security team or official government fraud channels.";
} elseif ($riskScore >= 40) {
    $recommendations[] = "⚠️ Double check the sender's actual email address (not just display name) for domain spoofing.";
    $recommendations[] = "⚠️ Contact the alleged company directly using their official publicly listed phone number to verify.";
} else {
    $recommendations[] = "✅ This content appears relatively safe, but always remain vigilant when interacting with unsolicited communications.";
}

// Helper function to check if any needle exists in haystack
function preg_include($needles, $haystack) {
    foreach ($needles as $needle) {
        if (strpos($haystack, $needle) !== false) {
            return true;
        }
    }
    return false;
}

echo json_encode([
    "status" => "success",
    "analyzer" => "CyberShield AI Sentinel v2.5",
    "timestamp" => date('c'),
    "data" => [
        "scam_likelihood_score" => $riskScore,
        "threat_level" => $threatLevel,
        "confidence" => $confidence,
        "indicators_found" => $indicators,
        "recommendations" => $recommendations
    ]
]);
