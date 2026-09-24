<?php
// posts/create.php — self-contained
ini_set('display_errors', 0);
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo json_encode(['status'=>'error','message'=>'Method not allowed']); exit; }

function getToken_pc() {
    if (!empty($_GET['token'])) return $_GET['token'];
    foreach (['Authorization','HTTP_AUTHORIZATION','REDIRECT_HTTP_AUTHORIZATION'] as $k) {
        if (!empty($_SERVER[$k]) && preg_match('/Bearer\s+(.+)/i', $_SERVER[$k], $m)) return $m[1];
    }
    if (function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $k => $v)
            if (strtolower($k) === 'authorization' && preg_match('/Bearer\s+(.+)/i', $v, $m)) return $m[1];
    }
    return null;
}
function loadEnv_pc() {
    foreach ([__DIR__ . '/../.env', __DIR__ . '/../../.env'] as $p) {
        if (!file_exists($p)) continue;
        foreach (file($p, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            if (strpos(trim($line), '#') === 0) continue;
            $parts = explode('=', $line, 2);
            if (count($parts) === 2) $_ENV[trim($parts[0])] = trim($parts[1]);
        }
        return;
    }
}
function b64d_pc($d) { return base64_decode(str_replace(['-','_'],['+','/'],$d).str_repeat('=',(4-strlen($d)%4)%4)); }
function validateJWT_pc($token, $secret) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return false;
    [$h,$p,$s] = $parts;
    $exp = rtrim(strtr(base64_encode(hash_hmac('sha256',"$h.$p",$secret,true)),'+/','-_'),'=');
    if (!hash_equals($exp,$s)) return false;
    $data = json_decode(b64d_pc($p),true);
    return ($data && (!isset($data['exp']) || $data['exp'] >= time())) ? $data : false;
}

$token = getToken_pc();
if (!$token) { http_response_code(401); echo json_encode(['status'=>'error','message'=>'Token missing']); exit; }

loadEnv_pc();
try {
    $pdo = new PDO('mysql:host='.($_ENV['DB_HOST']??'localhost').';dbname='.($_ENV['DB_NAME']??'android').';charset=utf8mb4',
        $_ENV['DB_USER']??'android_user', $_ENV['DB_PASS']??'',
        [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC, PDO::ATTR_EMULATE_PREPARES=>false]);
} catch (PDOException $e) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'DB failed: '.$e->getMessage()]); exit; }

$secret = $_ENV['JWT_SECRET'] ?? 'CyberShieldSuperSecretQuantumKey2026_Change_Me_Please_!';
$payload = validateJWT_pc($token, $secret);
if (!$payload) { http_response_code(401); echo json_encode(['status'=>'error','message'=>'Invalid token']); exit; }

$userId = intval($payload['sub'] ?? 0);

$data = json_decode(file_get_contents('php://input'), true) ?? [];
$categoryId  = intval($data['category_id'] ?? 0);
$title       = trim($data['title']       ?? '');
$content     = trim($data['content']     ?? '');
$isAnonymous = intval($data['is_anonymous'] ?? 0);

if (!$categoryId || !$title || !$content) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'category_id, title and content are required']);
    exit;
}
if (strlen($title) < 5)   { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Title too short (min 5 chars)']); exit; }
if (strlen($content) < 10){ http_response_code(400); echo json_encode(['status'=>'error','message'=>'Content too short (min 10 chars)']); exit; }

try {
    // Ensure category exists
    $chk = $pdo->prepare('SELECT id FROM categories WHERE id = ?');
    $chk->execute([$categoryId]);
    if (!$chk->fetch()) {
        if ($categoryId == 9999) {
            $pdo->prepare("INSERT IGNORE INTO categories (id, name, description, icon) VALUES (9999,'Security Advisories & Fraud Alerts','Daily AI-curated safety warnings.','security')")->execute();
        } else {
            http_response_code(404); echo json_encode(['status'=>'error','message'=>'Category not found']); exit;
        }
    }
    $stmt = $pdo->prepare('INSERT INTO posts (user_id, category_id, title, content, is_anonymous) VALUES (?,?,?,?,?)');
    $stmt->execute([$userId, $categoryId, $title, $content, $isAnonymous]);
    echo json_encode(['status'=>'success','message'=>'Post created successfully','data'=>['post_id'=>$pdo->lastInsertId()]]);
} catch (PDOException $e) { http_response_code(500); echo json_encode(['status'=>'error','message'=>$e->getMessage()]); }
