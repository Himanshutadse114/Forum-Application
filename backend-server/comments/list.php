<?php
// comments/list.php — self-contained
ini_set('display_errors', 0);
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

function getToken_cl() {
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
function loadEnv_cl() {
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
function b64d_cl($d) { return base64_decode(str_replace(['-','_'],['+','/'],$d).str_repeat('=',(4-strlen($d)%4)%4)); }
function validateJWT_cl($token, $secret) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return false;
    [$h,$p,$s] = $parts;
    $exp = rtrim(strtr(base64_encode(hash_hmac('sha256',"$h.$p",$secret,true)),'+/','-_'),'=');
    if (!hash_equals($exp,$s)) return false;
    $data = json_decode(b64d_cl($p),true);
    return ($data && (!isset($data['exp']) || $data['exp'] >= time())) ? $data : false;
}

$token = getToken_cl();
if (!$token) { http_response_code(401); echo json_encode(['status'=>'error','message'=>'Token missing']); exit; }

loadEnv_cl();
try {
    $pdo = new PDO('mysql:host='.($_ENV['DB_HOST']??'localhost').';dbname='.($_ENV['DB_NAME']??'android').';charset=utf8mb4',
        $_ENV['DB_USER']??'android_user', $_ENV['DB_PASS']??'',
        [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC, PDO::ATTR_EMULATE_PREPARES=>false]);
} catch (PDOException $e) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'DB failed: '.$e->getMessage()]); exit; }

$secret = $_ENV['JWT_SECRET'] ?? 'CyberShieldSuperSecretQuantumKey2026_Change_Me_Please_!';
if (!validateJWT_cl($token, $secret)) { http_response_code(401); echo json_encode(['status'=>'error','message'=>'Invalid token']); exit; }

$postId = isset($_GET['post_id']) ? intval($_GET['post_id']) : 0;
if (!$postId) { http_response_code(400); echo json_encode(['status'=>'error','message'=>'post_id required']); exit; }

try {
    $stmt = $pdo->prepare('SELECT c.*, u.username AS author_name, u.avatar AS author_avatar, u.`rank` AS author_rank FROM comments c JOIN users u ON c.user_id = u.id WHERE c.post_id = ? ORDER BY c.created_at ASC');
    $stmt->execute([$postId]);
    $comments = $stmt->fetchAll();
    foreach ($comments as &$c) {
        if ($c['is_anonymous'] == 1) { $c['user_id']=0; $c['author_name']='Anonymous Agent'; $c['author_avatar']='avatar_anon'; $c['author_rank']='Ghost Protocol'; }
    }
    echo json_encode(['status'=>'success','data'=>$comments]);
} catch (PDOException $e) { http_response_code(500); echo json_encode(['status'=>'error','message'=>$e->getMessage()]); }
