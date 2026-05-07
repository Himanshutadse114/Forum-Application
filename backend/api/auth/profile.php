<?php
// backend/api/auth/profile.php

require_once __DIR__ . '/../../middleware/auth.php';

$userData = AuthMiddleware::authenticate();

$db = new Database();
$conn = $db->getConnection();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $stmt = $conn->prepare("SELECT id, username, email, avatar, role, reputation_points, `rank`, created_at FROM users WHERE id = ?");
        $stmt->execute([$userData['user_id']]);
        $user = $stmt->fetch();

        if (!$user) {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found."]);
            exit;
        }

        echo json_encode([
            "status" => "success",
            "data" => $user
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    try {
        if (isset($data['reputation_points'])) {
            $points = intval($data['reputation_points']);
            $stmt = $conn->prepare("UPDATE users SET reputation_points = reputation_points + ? WHERE id = ?");
            $stmt->execute([$points, $userData['user_id']]);
            
            // Fetch current updated reputation points to recalculate rank
            $stmtRep = $conn->prepare("SELECT reputation_points FROM users WHERE id = ?");
            $stmtRep->execute([$userData['user_id']]);
            $currentRep = intval($stmtRep->fetchColumn());
            
            $rank = 'WhiteHat Trainee';
            if ($currentRep >= 500) {
                $rank = 'Elite Hacker';
            } elseif ($currentRep >= 300) {
                $rank = 'Threat Hunter';
            } elseif ($currentRep >= 150) {
                $rank = 'Security Analyst';
            } elseif ($currentRep >= 50) {
                $rank = 'Cyber Scout';
            }
            
            $stmtUpdateRank = $conn->prepare("UPDATE users SET `rank` = ? WHERE id = ?");
            $stmtUpdateRank->execute([$rank, $userData['user_id']]);

            echo json_encode([
                "status" => "success",
                "message" => "Score added successfully.",
                "data" => [
                    "reputation_points" => $currentRep,
                    "rank" => $rank
                ]
            ]);
        } elseif (!empty($data['avatar'])) {
            $avatar = trim($data['avatar']);
            $stmt = $conn->prepare("UPDATE users SET avatar = ? WHERE id = ?");
            $stmt->execute([$avatar, $userData['user_id']]);

            echo json_encode([
                "status" => "success",
                "message" => "Profile updated successfully.",
                "data" => [
                    "avatar" => $avatar
                ]
            ]);
        } else {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "Required field missing."]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed."]);
}
