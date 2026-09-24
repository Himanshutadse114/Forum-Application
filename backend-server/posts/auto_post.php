<?php
// posts/auto_post.php — LIVE cybersecurity news from real RSS feeds
// Normal:  https://innvikta.co.in/cybershield/posts/auto_post.php?secret=CyberShieldCronSecret2026
// Testing: https://innvikta.co.in/cybershield/posts/auto_post.php?secret=CyberShieldCronSecret2026&force=1
ini_set('display_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$debugLog = [];
function addDebugLog($msg) {
    global $debugLog;
    $debugLog[] = "[" . date('H:i:s') . "] " . $msg;
}

// ── Security gate ─────────────────────────────────────────────
if (php_sapi_name() !== 'cli') {
    $secret = 'CyberShieldCronSecret2026';
    if (($_GET['secret'] ?? '') !== $secret) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Unauthorized.']);
        exit;
    }
}

// ── Load .env ─────────────────────────────────────────────────
function ap_loadEnv() {
    $dirs = [__DIR__ . '/../.env', __DIR__ . '/../../.env', __DIR__ . '/.env'];
    foreach ($dirs as $p) {
        if (!file_exists($p)) continue;
        foreach (file($p, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            if (strpos(trim($line), '#') === 0) continue;
            $parts = explode('=', $line, 2);
            if (count($parts) === 2) $_ENV[trim($parts[0])] = trim($parts[1]);
        }
        return;
    }
}
ap_loadEnv();

// ── DB Connection ─────────────────────────────────────────────
try {
    $pdo = new PDO(
        'mysql:host=' . ($_ENV['DB_HOST'] ?? 'localhost') . ';dbname=' . ($_ENV['DB_NAME'] ?? 'android') . ';charset=utf8mb4',
        $_ENV['DB_USER'] ?? 'android_user',
        $_ENV['DB_PASS'] ?? '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC, PDO::ATTR_EMULATE_PREPARES => false]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'DB connection failed: ' . $e->getMessage()]);
    exit;
}

// ── Fetch RSS feed via cURL ───────────────────────────────────
function fetchRSS($url) {
    addDebugLog("fetchRSS: Fetching $url");
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_TIMEOUT        => 12,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_USERAGENT      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    ]);
    $response = curl_exec($ch);
    $err      = curl_error($ch);
    curl_close($ch);
    if ($err) {
        addDebugLog("fetchRSS: cURL error on $url: $err");
        return null;
    }
    if (!$response) {
        addDebugLog("fetchRSS: Empty response from $url");
        return null;
    }
    addDebugLog("fetchRSS: Fetched " . strlen($response) . " bytes from $url");
    return $response;
}

// ── Parse RSS and return items ────────────────────────────────
function parseRSS($xml) {
    addDebugLog("parseRSS: Parsing RSS XML");
    libxml_use_internal_errors(true);
    $feed = simplexml_load_string($xml);
    if (!$feed) {
        addDebugLog("parseRSS: XML parsing failed");
        return [];
    }

    $items = [];
    $nodes = $feed->channel->item ?? $feed->entry ?? [];
    addDebugLog("parseRSS: Found " . count($nodes) . " items in feed");

    foreach ($nodes as $item) {
        $title   = trim((string)($item->title   ?? ''));
        $link    = trim((string)($item->link    ?? $item->id ?? ''));
        
        // Try content:encoded namespace for full content
        $namespaces = $item->getNamespaces(true);
        $fullText = '';
        if (isset($namespaces['content'])) {
            $contentNs = $item->children($namespaces['content']);
            if (isset($contentNs->encoded)) {
                $fullText = trim((string)$contentNs->encoded);
            }
        }
        
        if ($fullText) {
            addDebugLog("parseRSS: Found content:encoded namespace (len: " . strlen($fullText) . ") for '$title'");
        } else {
            $fullText = (string)($item->description ?? $item->summary ?? $item->content ?? '');
        }
        
        $summary = trim(strip_tags($fullText));
        
        if (!$title) continue;

        // Clean up double newlines/extra spaces
        $summary = preg_replace('/[ \t]+/', ' ', $summary);
        $summary = preg_replace('/\n\s*\n/', "\n\n", $summary);

        // Keep it detailed (limit to 5000 chars)
        if (strlen($summary) > 5000) {
            $summary = substr($summary, 0, 4997) . '...';
        }

        $items[] = ['title' => $title, 'summary' => $summary, 'link' => $link];
        addDebugLog("parseRSS: Item parsed - '$title' (summary length: " . strlen($summary) . ")");

        if (count($items) >= 10) break;
    }
    return $items;
}

// ── Scrape and extract detailed article content from a web page ──
function fetchDetailedArticle($url) {
    if (!$url) return null;

    addDebugLog("fetchDetailedArticle: Attempting to fetch webpage: $url");
    $html = fetchRSS($url);
    if (!$html) {
        addDebugLog("fetchDetailedArticle: Web page fetch returned empty or failed");
        return null;
    }

    libxml_use_internal_errors(true);
    $dom = new DOMDocument();
    
    if (function_exists('mb_convert_encoding')) {
        $html = mb_convert_encoding($html, 'HTML-ENTITIES', 'UTF-8');
    }
    
    $dom->loadHTML($html);
    libxml_clear_errors();

    $xpath = new DOMXPath($dom);

    // Common CSS class / ID and tag structures for news article bodies
    $containers = [
        "//article",
        "//div[contains(@class, 'post-content')]",
        "//div[contains(@class, 'entry-content')]",
        "//div[contains(@class, 'article-content')]",
        "//div[contains(@class, 'article-body')]",
        "//div[contains(@class, 'td-post-content')]",
        "//div[contains(@class, 'post-body')]",
        "//div[contains(@id, 'article-body')]",
        "//div[contains(@id, 'entry-content')]",
        "//div[contains(@id, 'content-body')]",
        "//main",
    ];

    $bestNode = null;
    $maxParagraphs = 0;

    foreach ($containers as $query) {
        $nodes = $xpath->query($query);
        if ($nodes->length > 0) {
            foreach ($nodes as $node) {
                $pNodes = $xpath->query(".//p", $node);
                $pCount = $pNodes->length;
                if ($pCount > $maxParagraphs) {
                    $maxParagraphs = $pCount;
                    $bestNode = $node;
                }
            }
            // Stop if we find a candidate node with at least 2 paragraphs
            if ($maxParagraphs >= 2) {
                addDebugLog("fetchDetailedArticle: Selected container '$query' with $maxParagraphs paragraphs");
                break;
            }
        }
    }

    // Fallback if no container matched with substantial content
    if ($maxParagraphs < 2) {
        addDebugLog("fetchDetailedArticle: No matching container with paragraphs. Querying globally.");
        $bestNode = null;
    }

    if ($bestNode) {
        $pNodes = $xpath->query(".//p", $bestNode);
    } else {
        $pNodes = $xpath->query("//p");
    }

    addDebugLog("fetchDetailedArticle: Found " . $pNodes->length . " total paragraph nodes to process");

    $paragraphs = [];
    foreach ($pNodes as $pNode) {
        $text = trim($pNode->textContent);

        // Standardize whitespace
        $text = preg_replace('/\s+/', ' ', $text);

        // Require substantial paragraph length for a detailed read
        if (strlen($text) < 90) continue;

        // Skip standard news site boilerplate, cookie notices, and social calls
        $skipKeywords = [
            'share on', 'follow us', 'read more', 'sign up for', 
            'advertisement', 'related coverage', 'subscribe to', 
            'copyright', 'all rights reserved', 'privacy policy',
            'cookie policy', 'terms of service', 'click here',
            'photo by', 'image via', 'newsletter', 'join our channel',
            'telegram channel', 'whatsapp channel', 'youtube channel',
            'follow our facebook', 'add us to', 'follow us on'
        ];

        $shouldSkip = false;
        foreach ($skipKeywords as $keyword) {
            if (stripos($text, $keyword) !== false) {
                $shouldSkip = true;
                break;
            }
        }
        if ($shouldSkip) continue;

        $paragraphs[] = $text;

        // Fetch up to 7 paragraphs to build a rich, detailed article
        if (count($paragraphs) >= 7) break;
    }

    addDebugLog("fetchDetailedArticle: Scraped " . count($paragraphs) . " paragraphs of content");

    if (empty($paragraphs)) return null;

    return implode("\n\n", $paragraphs);
}

// ── Real Cybersecurity News RSS Feeds ────────────────────────
// Multiple feeds in priority order — first successful one is used
$feeds = [
    [
        'name' => 'The Hacker News',
        'url'  => 'https://feeds.feedburner.com/TheHackersNews',
        'icon' => '📰',
    ],
    [
        'name' => 'Bleeping Computer',
        'url'  => 'https://www.bleepingcomputer.com/feed/',
        'icon' => '🛡️',
    ],
    [
        'name' => 'Krebs on Security',
        'url'  => 'https://krebsonsecurity.com/feed/',
        'icon' => '🔐',
    ],
    [
        'name' => 'CISA Advisories',
        'url'  => 'https://www.cisa.gov/news.xml',
        'icon' => '🇺🇸',
    ],
    [
        'name' => 'SecurityWeek',
        'url'  => 'https://feeds.feedburner.com/securityweek',
        'icon' => '⚠️',
    ],
];

// ── Fetch latest news ─────────────────────────────────────────
$newsItems  = [];
$sourceName = '';

foreach ($feeds as $feed) {
    $xml = fetchRSS($feed['url']);
    if (!$xml) continue;
    $parsed = parseRSS($xml);
    if (!empty($parsed)) {
        $newsItems  = $parsed;
        $sourceName = $feed['name'];
        break;
    }
}

// ── Strip all emoji from a string ────────────────────────────
function removeEmoji($string) {
    // Remove emoji unicode ranges
    $string = preg_replace('/[\x{1F600}-\x{1F64F}]/u', '', $string); // Emoticons
    $string = preg_replace('/[\x{1F300}-\x{1F5FF}]/u', '', $string); // Misc symbols
    $string = preg_replace('/[\x{1F680}-\x{1F6FF}]/u', '', $string); // Transport
    $string = preg_replace('/[\x{1F700}-\x{1F77F}]/u', '', $string); // Alchemical
    $string = preg_replace('/[\x{1F780}-\x{1F7FF}]/u', '', $string); // Geometric
    $string = preg_replace('/[\x{1F800}-\x{1F8FF}]/u', '', $string); // Supplemental arrows
    $string = preg_replace('/[\x{1F900}-\x{1F9FF}]/u', '', $string); // Supplemental symbols
    $string = preg_replace('/[\x{1FA00}-\x{1FA6F}]/u', '', $string); // Chess symbols
    $string = preg_replace('/[\x{1FA70}-\x{1FAFF}]/u', '', $string); // Symbols extended
    $string = preg_replace('/[\x{2600}-\x{26FF}]/u',   '', $string); // Misc symbols
    $string = preg_replace('/[\x{2700}-\x{27BF}]/u',   '', $string); // Dingbats
    $string = preg_replace('/[\x{FE00}-\x{FE0F}]/u',   '', $string); // Variation selectors
    $string = preg_replace('/[\x{1F1E0}-\x{1F1FF}]/u', '', $string); // Flags
    return trim(preg_replace('/\s+/', ' ', $string));
}

// ── Fallback pool if all feeds fail ──────────────────────────
$fallbackItems = [
    ['title' => 'GoldPickaxe Android Trojan Targeting Banking Apps',    'summary' => "A dangerous Android Trojan named GoldPickaxe is actively harvesting biometric data, identity documents, and SMS OTPs from banking apps. Keep Google Play Protect enabled and never install APKs from unknown links.", 'link' => 'https://thehackernews.com'],
    ['title' => 'WhatsApp Account Takeover via Verification Code Scam', 'summary' => "Scammers call victims pretending to be WhatsApp support and ask for the 6-digit SMS verification code. Once shared, your account is instantly hijacked. Enable Two-Step Verification in WhatsApp Settings.", 'link' => 'https://www.bleepingcomputer.com'],
    ['title' => 'UPI Fraud: Fake Screen Share Scam via Remote Apps',    'summary' => "Fraudsters call victims claiming to be bank officials and ask them to install AnyDesk or TeamViewer. Your bank will NEVER ask for your UPI PIN or OTP over a call.", 'link' => 'https://krebsonsecurity.com'],
    ['title' => 'SIM Swap Fraud: Protect Your 2FA SMS Codes',           'summary' => "Criminals convince your carrier to transfer your number to a new SIM, intercepting all 2FA codes. Set a SIM PIN with your carrier and switch to Google Authenticator.", 'link' => 'https://www.cisa.gov'],
    ['title' => 'Phishing SMS: Fake Delivery Notification Scam Active', 'summary' => "An active phishing campaign sends SMS messages pretending to be delivery services. Do NOT click links in unexpected SMS — report suspicious SMS to 1930 (Cyber Crime Helpline).", 'link' => 'https://thehackernews.com'],
];

if (empty($newsItems)) {
    $newsItems  = $fallbackItems;
    $sourceName = 'CyberShield Advisory Team';
}

// ── Choose article ────────────────────────────────────────────
$forceMode = isset($_GET['force']) && $_GET['force'] === '1';

if ($forceMode) {
    shuffle($newsItems);
    $item = $newsItems[0];
} else {
    $item = $newsItems[intval(date('z')) % count($newsItems)];
}

// Strip emoji from RSS title
$title   = removeEmoji(mb_substr($item['title'], 0, 150));
$link    = trim($item['link']);

// Attempt to fetch detailed article content from the web link
$detailedContent = null;
if (!empty($link) && strpos($link, 'http') === 0) {
    addDebugLog("Main: Attempting detailed scrape for link: $link");
    $detailedContent = fetchDetailedArticle($link);
}

// Fallback to the parsed RSS summary if detailed fetching failed or is empty
if ($detailedContent) {
    addDebugLog("Main: Detailed scrape successful! Content length: " . strlen($detailedContent) . " chars");
    $summary = removeEmoji($detailedContent);
} else {
    addDebugLog("Main: Scrape failed or skipped. Using RSS summary fallback (length: " . strlen($item['summary']) . " chars)");
    $summary = removeEmoji($item['summary'] ?: $item['title']);
}

// Build clean post content — no emoji, link on its own line for clickability
$content  = "Date: " . date('D, d M Y') . "\n";
$content .= "Source: $sourceName\n\n";
$content .= $summary;
if ($link) {
    $content .= "\n\nRead full article:\n$link";
}
$content .= "\n\nPosted by CyberShield Security Monitor\n";
$content .= "Like and comment to help spread awareness.";

// ── Insert post ───────────────────────────────────────────────
try {
    // Ensure Security Advisories category 9999 exists
    $pdo->prepare("INSERT IGNORE INTO categories (id, name, description, icon) VALUES (9999, 'Security Advisories & Fraud Alerts', 'Daily AI-curated safety warnings and scam alerts.', 'security')")->execute();

    // Ensure admin user (id=1) exists and has the correct admin username
    $chk = $pdo->prepare("SELECT id, username FROM users WHERE id = 1");
    $chk->execute();
    $existingUser = $chk->fetch();
    if (!$existingUser) {
        $pdo->prepare("INSERT INTO users (id, username, email, password_hash, role, reputation_points, `rank`, avatar) VALUES (1, 'cybershield_admin', 'admin@innvikta.co.in', ?, 'super_admin', 9999, 'Cyber Commander', 'avatar_1')")
            ->execute([password_hash('CyberAdmin@2026', PASSWORD_BCRYPT)]);
    } else if ($existingUser['username'] !== 'cybershield_admin') {
        // If user ID 1 exists but is set to a test user, update it to be cybershield_admin
        $pdo->prepare("UPDATE users SET username = 'cybershield_admin', email = 'admin@innvikta.co.in', role = 'super_admin', reputation_points = 9999, `rank` = 'Cyber Commander', avatar = 'avatar_1' WHERE id = 1")->execute();
    }

    // Skip duplicate check only in normal (non-force) mode
    if (!$forceMode) {
        $dup = $pdo->prepare("SELECT id FROM posts WHERE title = ? AND category_id = 9999 AND DATE(created_at) = CURDATE()");
        $dup->execute([$title]);
        if ($existing = $dup->fetch()) {
            echo json_encode([
                'status' => 'success', 
                'message' => 'Already published today.', 
                'data' => ['post_id' => $existing['id'], 'title' => $title, 'source' => $sourceName],
                'debug' => $debugLog
            ]);
            exit;
        }
    }

    $pdo->prepare("INSERT INTO posts (user_id, category_id, title, content, is_anonymous) VALUES (1, 9999, ?, ?, 0)")->execute([$title, $content]);
    $postId = $pdo->lastInsertId();

    echo json_encode([
        'status'  => 'success',
        'message' => $forceMode ? 'Live news post added!' : 'Daily news advisory posted!',
        'data'    => [
            'post_id' => $postId,
            'title'   => $title,
            'source'  => $sourceName,
        ],
        'debug'   => $debugLog
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()]);
}
