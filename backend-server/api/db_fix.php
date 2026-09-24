<?php
// backend/api/db_fix.php - 100% self-contained database migration script
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

$checkedPaths = [];
$loadedFrom = null;

function loadEnv() {
    global $checkedPaths, $loadedFrom;
    $dirs = [
        __DIR__ . '/.env',
        __DIR__ . '/../.env',
        __DIR__ . '/../../.env',
        __DIR__ . '/config/.env',
        __DIR__ . '/../config/.env'
    ];
    foreach ($dirs as $p) {
        $checkedPaths[] = $p;
        if (!file_exists($p)) continue;
        $lines = file($p, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $hasDb = false;
        foreach ($lines as $line) {
            if (strpos(trim($line), '#') === 0) continue;
            $parts = explode('=', $line, 2);
            if (count($parts) === 2) {
                $key = trim($parts[0]);
                $val = trim($parts[1]);
                $_ENV[$key] = $val;
                putenv("$key=$val");
                if ($key === 'DB_PASS' || $key === 'DB_PASSWORD') {
                    $hasDb = true;
                }
            }
        }
        if ($hasDb) {
            $loadedFrom = $p;
            return;
        }
    }
}
loadEnv();

$results = [
    'checked_paths' => $checkedPaths,
    'loaded_from' => $loadedFrom,
    'env_keys' => array_keys($_ENV)
];

try {
    $host = $_ENV['DB_HOST'] ?? 'localhost';
    $db   = $_ENV['DB_NAME'] ?? 'android';
    $user = $_ENV['DB_USER'] ?? 'android_user';
    $pass = $_ENV['DB_PASS'] ?? '';

    $conn = new PDO(
        "mysql:host=$host;dbname=$db;charset=utf8mb4",
        $user,
        $pass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );

    $results['db_connection'] = "Connected successfully to $db";

    // 1. Create notifications table if not exists
    $createNotifications = "CREATE TABLE IF NOT EXISTS `notifications` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `user_id` INT NOT NULL,
        `type` VARCHAR(50) NOT NULL,
        `title` VARCHAR(100) NOT NULL,
        `message` TEXT NOT NULL,
        `is_read` TINYINT(1) DEFAULT 0,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";
    $conn->exec($createNotifications);
    $results['notifications_table'] = "Verified/Created";

    // 2. Create achievements table if not exists
    $createAchievements = "CREATE TABLE IF NOT EXISTS `achievements` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `user_id` INT NOT NULL,
        `badge_name` VARCHAR(50) NOT NULL,
        `badge_icon` VARCHAR(50) NOT NULL,
        `description` VARCHAR(255) NOT NULL,
        `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY `user_badge` (`user_id`, `badge_name`),
        FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";
    $conn->exec($createAchievements);
    $results['achievements_table'] = "Verified/Created";

    // 3. Create reports table if not exists
    $createReports = "CREATE TABLE IF NOT EXISTS `reports` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `user_id` INT DEFAULT NULL,
        `title` VARCHAR(150) NOT NULL,
        `description` TEXT NOT NULL,
        `scam_type` VARCHAR(50) NOT NULL,
        `evidence_url` VARCHAR(255) DEFAULT NULL,
        `status` VARCHAR(20) DEFAULT 'pending',
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";
    $conn->exec($createReports);
    $results['reports_table'] = "Verified/Created";

    // 4. Ensure submitted_at column exists in game_scores
    $checkCol = $conn->query("SHOW COLUMNS FROM `game_scores` LIKE 'submitted_at'");
    if ($checkCol->rowCount() == 0) {
        $conn->exec("ALTER TABLE `game_scores` ADD COLUMN `submitted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
        $results['game_scores_submitted_at_column'] = "Added";
    } else {
        $results['game_scores_submitted_at_column'] = "Already Exists";
    }

    // 5. Check if any threat_reports exist to migrate into reports
    $checkThreatReportsTable = $conn->query("SHOW TABLES LIKE 'threat_reports'");
    if ($checkThreatReportsTable->rowCount() > 0) {
        $migrateQuery = "INSERT INTO `reports` (id, user_id, title, description, scam_type, evidence_url, status, created_at)
                         SELECT id, user_id, title, description, scam_type, evidence_url, 
                                CASE 
                                    WHEN status = 'reviewed' THEN 'under_review'
                                    WHEN status = 'resolved' THEN 'verified'
                                    ELSE 'pending'
                                END, 
                                created_at 
                         FROM `threat_reports`
                         WHERE id NOT IN (SELECT id FROM `reports`)";
        try {
            $migrated = $conn->exec($migrateQuery);
            $results['migrated_reports_count'] = $migrated;
        } catch (PDOException $ex) {
            $results['migrated_reports_error'] = $ex->getMessage();
        }
    }

    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "message" => "Database verified and fixed successfully.",
        "details" => $results
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database error during migration: " . $e->getMessage(),
        "details" => $results
    ]);
}
?>
