<?php
// posts/list.php  — self-contained, no fragile require chains
ini_set('display_errors', 0);
error_reporting(E_ALL);

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

// ── Auth: accept Bearer header OR ?token= query param ──────────
function getToken() {
    if (!empty($_GET['token'])) return $_GET['token'];
    foreach (['Authorization','HTTP_AUTHORIZATION','REDIRECT_HTTP_AUTHORIZATION'] as $k) {
        if (!empty($_SERVER[$k])) {
            if (preg_match('/Bearer\s+(.+)/i', $_SERVER[$k], $m)) return $m[1];
        }
    }
    if (function_exists('apache_request_headers')) {
        $h = apache_request_headers();
        foreach ($h as $k => $v) {
            if (strtolower($k) === 'authorization' && preg_match('/Bearer\s+(.+)/i', $v, $m)) return $m[1];
        }
    }
    return null;
}

$token = getToken();
if (!$token) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Authorization token missing']);
    exit;
}

// ── DB Connection: search for .env in parent dirs ──────────────
function loadEnv() {
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
loadEnv();

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

// ── Token validation (lightweight, no lib needed) ──────────────
function base64url_decode($data) {
    return base64_decode(str_replace(['-','_'], ['+','/'], $data) . str_repeat('=', (4 - strlen($data) % 4) % 4));
}
function validateJWT($token, $secret) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return false;
    [$header, $payload, $sig] = $parts;
    $expected = rtrim(strtr(base64_encode(hash_hmac('sha256', "$header.$payload", $secret, true)), '+/', '-_'), '=');
    if (!hash_equals($expected, $sig)) return false;
    $data = json_decode(base64url_decode($payload), true);
    if (!$data || (isset($data['exp']) && $data['exp'] < time())) return false;
    return $data;
}

$secret  = $_ENV['JWT_SECRET'] ?? 'CyberShieldSuperSecretQuantumKey2026_Change_Me_Please_!';
$payload = validateJWT($token, $secret);
if (!$payload) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Invalid or expired token']);
    exit;
}

// ── Build Query ────────────────────────────────────────────────
$categoryId = isset($_GET['category_id']) ? intval($_GET['category_id']) : null;
$userId     = isset($_GET['user_id'])     ? intval($_GET['user_id'])     : null;

$sql    = 'SELECT p.*, u.username AS author_name, u.avatar AS author_avatar, u.`rank` AS author_rank, c.name AS category_name
           FROM posts p
           JOIN users u ON p.user_id = u.id
           LEFT JOIN categories c ON p.category_id = c.id';
$params = [];
$where  = [];

if ($categoryId) { $where[] = 'p.category_id = ?'; $params[] = $categoryId; }
if ($userId)     { $where[] = 'p.user_id = ?';     $params[] = $userId;     }
if ($where)      { $sql .= ' WHERE ' . implode(' AND ', $where); }
$sql .= ' ORDER BY p.created_at DESC';

try {
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $posts = $stmt->fetchAll();

    foreach ($posts as &$post) {
        if ($post['is_anonymous'] == 1) {
            $post['user_id']      = 0;
            $post['author_name']  = 'Anonymous Agent';
            $post['author_avatar']= 'anonymous_avatar.png';
            $post['author_rank']  = 'Ghost Protocol';
        }
    }
    echo json_encode(['status' => 'success', 'data' => $posts]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Query failed: ' . $e->getMessage()]);
}
