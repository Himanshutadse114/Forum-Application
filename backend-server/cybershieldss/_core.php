<?php
// _core.php — Shared helper: DB + JWT + Auth
// Include this at the top of every endpoint file.
// Place this file in your root cybershield/ folder on the server.

// ── CORS ──────────────────────────────────────────────────────
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

// ── Load .env ──────────────────────────────────────────────────
function _loadEnv() {
    static $loaded = false;
    if ($loaded) return;
    $loaded = true;
    // Search up from current file location
    $dir = __DIR__;
    for ($i = 0; $i < 4; $i++) {
        $path = $dir . DIRECTORY_SEPARATOR . '.env';
        if (file_exists($path)) {
            foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                if (strpos(trim($line), '#') === 0) continue;
                $parts = explode('=', $line, 2);
                if (count($parts) === 2) $_ENV[trim($parts[0])] = trim($parts[1]);
            }
            return;
        }
        $dir = dirname($dir);
    }
}

// ── PDO Connection ─────────────────────────────────────────────
function _db() {
    static $pdo;
    if ($pdo) return $pdo;
    _loadEnv();
    try {
        $pdo = new PDO(
            'mysql:host=' . ($_ENV['DB_HOST'] ?? 'localhost') . ';dbname=' . ($_ENV['DB_NAME'] ?? 'android') . ';charset=utf8mb4',
            $_ENV['DB_USER'] ?? 'android_user',
            $_ENV['DB_PASS'] ?? '',
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC, PDO::ATTR_EMULATE_PREPARES => false]
        );
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Database connection failed: ' . $e->getMessage()]);
        exit;
    }
    return $pdo;
}

// ── JWT ────────────────────────────────────────────────────────
function _jwtSecret() {
    _loadEnv();
    return $_ENV['JWT_SECRET'] ?? 'CyberShieldSuperSecretQuantumKey2026_Change_Me_Please_!';
}
function _b64e($d) { return rtrim(strtr(base64_encode($d), '+/', '-_'), '='); }
function _b64d($d) { return base64_decode(str_replace(['-','_'], ['+','/'], $d) . str_repeat('=', (4 - strlen($d) % 4) % 4)); }
function _jwtGenerate($payload) {
    $h = _b64e(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $p = _b64e(json_encode($payload));
    $s = _b64e(hash_hmac('sha256', "$h.$p", _jwtSecret(), true));
    return "$h.$p.$s";
}
function _jwtDecode($token) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return false;
    [$h, $p, $s] = $parts;
    $expected = _b64e(hash_hmac('sha256', "$h.$p", _jwtSecret(), true));
    if (!hash_equals($expected, $s)) return false;
    $data = json_decode(_b64d($p), true);
    if (!$data || (isset($data['exp']) && $data['exp'] < time())) return false;
    return $data;
}

// ── Extract Bearer Token ───────────────────────────────────────
function _getToken() {
    if (!empty($_GET['token'])) return $_GET['token'];
    foreach (['Authorization', 'HTTP_AUTHORIZATION', 'REDIRECT_HTTP_AUTHORIZATION'] as $k) {
        if (!empty($_SERVER[$k]) && preg_match('/Bearer\s+(.+)/i', $_SERVER[$k], $m)) return $m[1];
    }
    if (function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $k => $v) {
            if (strtolower($k) === 'authorization' && preg_match('/Bearer\s+(.+)/i', $v, $m)) return $m[1];
        }
    }
    return null;
}

// ── Authenticate (returns user array or exits with 401) ────────
function _auth() {
    $token = _getToken();
    if (!$token) { http_response_code(401); echo json_encode(['status' => 'error', 'message' => 'Authorization token missing']); exit; }
    $payload = _jwtDecode($token);
    if (!$payload) { http_response_code(401); echo json_encode(['status' => 'error', 'message' => 'Invalid or expired token']); exit; }

    $db   = _db();
    $stmt = $db->prepare('SELECT id, username, email, role, reputation_points, `rank`, avatar FROM users WHERE id = ?');
    $stmt->execute([$payload['sub']]);
    $user = $stmt->fetch();
    if (!$user) { http_response_code(401); echo json_encode(['status' => 'error', 'message' => 'User not found']); exit; }
    return $user;
}

// ── Optional auth (returns user or null) ──────────────────────
function _authOptional() {
    $token = _getToken();
    if (!$token) return null;
    $payload = _jwtDecode($token);
    if (!$payload) return null;
    $db   = _db();
    $stmt = $db->prepare('SELECT id, username, email, role, reputation_points, `rank`, avatar FROM users WHERE id = ?');
    $stmt->execute([$payload['sub']]);
    return $stmt->fetch() ?: null;
}
