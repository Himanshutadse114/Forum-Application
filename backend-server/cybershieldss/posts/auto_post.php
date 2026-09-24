<?php
// posts/auto_post.php
// ─────────────────────────────────────────────────────────────────────────────
// Daily Security Advisory Auto-Poster
// Run via cron OR visit the URL once to publish today's advisory:
//   https://innvikta.co.in/cybershield/posts/auto_post.php?secret=CyberShieldCronSecret2026
// ─────────────────────────────────────────────────────────────────────────────
ini_set('display_errors', 1);
require_once __DIR__ . '/../_core.php';

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');

// ── Security gate (skip for CLI cron) ────────────────────────────────────────
if (php_sapi_name() !== 'cli') {
    $secret = 'CyberShieldCronSecret2026';
    if (($_GET['secret'] ?? '') !== $secret) {
        http_response_code(403); echo json_encode(['status' => 'error', 'message' => 'Unauthorized']); exit;
    }
}

// ── Advisory Pool (one per day, cycles through the year) ─────────────────────
$advisories = [
    ['title' => '⚠️ GoldPickaxe Android Trojan Targeting Banking Apps', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: CyberShield Advisory Team\n\nA dangerous Android Trojan named 'GoldPickaxe' is actively harvesting biometric data, identity documents, and SMS OTPs from banking apps. It disguises itself as a system update.\n\n✅ Stay Safe:\n• Keep Google Play Protect enabled\n• Never install APKs from unknown links\n• Check app permissions regularly"],
    ['title' => '🚨 WhatsApp Account Takeover via Verification Code Scam', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: Mobile Security Bureau\n\nScammers call victims pretending to be WhatsApp support and ask for the 6-digit SMS verification code. Once shared, your account is instantly hijacked.\n\n✅ Stay Safe:\n• Never share OTP codes with anyone\n• Enable Two-Step Verification in WhatsApp Settings\n• WhatsApp support will NEVER call you for a code"],
    ['title' => '⚡ Juice Jacking: Public USB Charging Ports Are Dangerous', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: Hardware Security Group\n\nPublic USB charging ports at airports, malls, and hotels can be modified by attackers to install malware or steal your data (Juice Jacking).\n\n✅ Stay Safe:\n• Use a standard wall outlet + your own charger\n• Carry a USB Data Blocker (a.k.a. 'USB Condom')\n• Use power banks when travelling"],
    ['title' => '🛡️ Fake Google Play System Update Installing Spyware', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: OS Threat Intelligence\n\nMalicious apps display fake 'Google Play System Update' popups to gain Device Administrator permissions. Once granted, they record screens and steal passwords silently.\n\n✅ Stay Safe:\n• Real updates ONLY appear inside Settings → System\n• Never grant Device Admin to unknown apps\n• Review Device Admin apps in Settings → Security"],
    ['title' => '📱 SIM Swap Fraud: Protect Your 2FA SMS Codes', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: Telecom Safety Advisory\n\nCriminals convince your mobile carrier to transfer your phone number to a new SIM they control. They then intercept all your SMS-based 2FA codes to access banking and social media.\n\n✅ Stay Safe:\n• Set a SIM/Account PIN with your carrier\n• Switch to app-based 2FA (Google Authenticator)\n• Never share your Aadhaar details over calls"],
    ['title' => '🌐 Man-in-the-Middle Attack via Rogue Public Wi-Fi', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: Network Security Bureau\n\nHackers set up rogue Wi-Fi hotspots with names like 'Airport_Free_WiFi' to intercept all your traffic and steal banking credentials and passwords.\n\n✅ Stay Safe:\n• Never access banking on public Wi-Fi\n• Use a trusted VPN when on public networks\n• Verify Wi-Fi name with staff before connecting"],
    ['title' => '🎣 Phishing SMS: Fake Delivery Notification Scam Active', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: CyberShield Threat Network\n\nAn active phishing campaign sends SMS messages pretending to be delivery services (Innvikta Post, DTDC, FedEx) with a link to 'confirm delivery'. The link leads to a fake banking login page.\n\n✅ Stay Safe:\n• Do NOT click links in unexpected SMS messages\n• Go directly to the courier's official website\n• Report suspicious SMS to 1930 (Cyber Crime Helpline)"],
    ['title' => '🔌 Malicious Browser Extensions Stealing Passwords', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: Threat Intelligence Lab\n\nSeveral browser extensions have been hijacked to inject scripts into banking and social media pages, silently capturing your keystrokes and passwords.\n\n✅ Stay Safe:\n• Remove browser extensions you don't recognise\n• Avoid extensions that request access to 'all sites'\n• Prefer extensions with 1M+ users and recent updates"],
    ['title' => '💳 UPI Fraud: Fake Screen Share Scam via Remote Apps', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: Digital Payments Safety Council\n\nFraudsters call victims claiming to be bank officials and ask them to install screen-sharing apps like AnyDesk or TeamViewer. They then watch the victim enter UPI PINs and drain accounts.\n\n✅ Stay Safe:\n• Never install screen-share apps on request from strangers\n• Your bank will NEVER ask for your UPI PIN or OTP\n• Hang up and call your bank's official number to verify"],
    ['title' => '🤖 AI Voice Cloning Scam Targeting Families', 'content' => "📅 " . date('Y-m-d') . "\n🔍 Source: AI Threat Research Group\n\nScammers are using AI to clone the voice of a family member from social media and call relatives claiming to be in an emergency, demanding immediate money transfers.\n\n✅ Stay Safe:\n• Establish a secret family codeword for emergencies\n• Always call back on the family member's known number\n• Limit voice content posted publicly on social media"],
];

// ── Post today's advisory ─────────────────────────────────────────────────────
try {
    $db = _db();

    // Ensure Security Advisories category 9999 exists
    $db->prepare("INSERT IGNORE INTO categories (id, name, description, icon) VALUES (9999, 'Security Advisories & Fraud Alerts', 'Daily AI-curated safety warnings and scam alerts.', 'security')")->execute();

    // Ensure admin user (id=1) exists
    $chkAdmin = $db->prepare('SELECT id FROM users WHERE id = 1');
    $chkAdmin->execute();
    if (!$chkAdmin->fetch()) {
        $db->prepare("INSERT INTO users (id, username, email, password_hash, role, reputation_points, `rank`, avatar) VALUES (1,'cybershield_admin','admin@innvikta.co.in',?,'super_admin',9999,'Cyber Commander','avatar_1')")
           ->execute([password_hash('CyberAdmin@2026', PASSWORD_BCRYPT)]);
    }

    // Pick today's advisory (cycles through the pool)
    $advisory = $advisories[intval(date('z')) % count($advisories)];
    $title    = $advisory['title'];
    $content  = $advisory['content'];

    // Skip if same title was already posted today
    $chk = $db->prepare("SELECT id FROM posts WHERE title = ? AND category_id = 9999 AND DATE(created_at) = CURDATE()");
    $chk->execute([$title]);
    if ($existing = $chk->fetch()) {
        echo json_encode(['status' => 'success', 'message' => 'Already published today', 'data' => ['post_id' => $existing['id'], 'title' => $title]]);
        exit;
    }

    $db->prepare('INSERT INTO posts (user_id, category_id, title, content, is_anonymous) VALUES (1, 9999, ?, ?, 0)')->execute([$title, $content]);
    echo json_encode(['status' => 'success', 'message' => 'Daily advisory posted!', 'data' => ['post_id' => $db->lastInsertId(), 'title' => $title]]);

} catch (PDOException $e) {
    http_response_code(500); echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
