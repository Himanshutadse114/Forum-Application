-- ============================================================
--  CyberShield Forum — Complete Database Schema
--  DB: android  |  User: android_user
--  Run: mysql -u android_user -p android < schema.sql
-- ============================================================

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;   -- disable during setup
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS `users` (
  `id`                INT          NOT NULL AUTO_INCREMENT,
  `username`          VARCHAR(50)  NOT NULL,
  `email`             VARCHAR(100) NOT NULL,
  `password_hash`     VARCHAR(255) NOT NULL,
  `role`              ENUM('user','admin','super_admin') NOT NULL DEFAULT 'user',
  `avatar`            VARCHAR(30)  NOT NULL DEFAULT 'avatar_1',
  `reputation_points` INT          NOT NULL DEFAULT 0,
  `rank`              VARCHAR(60)  NOT NULL DEFAULT 'Recruit',
  `created_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_username` (`username`),
  UNIQUE KEY `uq_email`    (`email`),
  KEY `idx_role`            (`role`),
  KEY `idx_reputation`      (`reputation_points`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 2. CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS `categories` (
  `id`          INT          NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(100) NOT NULL,
  `description` TEXT,
  `icon`        VARCHAR(50)  NOT NULL DEFAULT 'shield',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 3. POSTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `posts` (
  `id`             INT          NOT NULL AUTO_INCREMENT,
  `user_id`        INT          NOT NULL,
  `category_id`    INT          NOT NULL,
  `title`          VARCHAR(255) NOT NULL,
  `content`        TEXT         NOT NULL,
  `is_anonymous`   TINYINT(1)   NOT NULL DEFAULT 0,
  `likes_count`    INT          NOT NULL DEFAULT 0,
  `comments_count` INT          NOT NULL DEFAULT 0,
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_category`   (`category_id`),
  KEY `idx_user`       (`user_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_posts_user`     FOREIGN KEY (`user_id`)     REFERENCES `users`(`id`)      ON DELETE CASCADE,
  CONSTRAINT `fk_posts_category` FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 4. COMMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `comments` (
  `id`           INT        NOT NULL AUTO_INCREMENT,
  `post_id`      INT        NOT NULL,
  `user_id`      INT        NOT NULL,
  `content`      TEXT       NOT NULL,
  `is_anonymous` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at`   DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_post_id`    (`post_id`),
  KEY `idx_user_id`    (`user_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_comments_post` FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 5. LIKES  (one like per user per post — toggle)
-- ============================================================
CREATE TABLE IF NOT EXISTS `likes` (
  `id`         INT      NOT NULL AUTO_INCREMENT,
  `user_id`    INT      NOT NULL,
  `post_id`    INT      NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_like`  (`user_id`, `post_id`),
  KEY `idx_post_id` (`post_id`),
  CONSTRAINT `fk_likes_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_likes_post` FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 6. FOLLOWS
-- ============================================================
CREATE TABLE IF NOT EXISTS `follows` (
  `id`           INT      NOT NULL AUTO_INCREMENT,
  `follower_id`  INT      NOT NULL,
  `following_id` INT      NOT NULL,
  `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_follow`       (`follower_id`, `following_id`),
  KEY `idx_follower_id`         (`follower_id`),
  KEY `idx_following_id`        (`following_id`),
  CONSTRAINT `fk_follows_follower`  FOREIGN KEY (`follower_id`)  REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_follows_following` FOREIGN KEY (`following_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 7. GAME SCORES  (every attempt — full audit trail)
--    Mirrors Hive's  game_history_{userId}_{gameId}  list
-- ============================================================
CREATE TABLE IF NOT EXISTS `game_scores` (
  `id`        INT      NOT NULL AUTO_INCREMENT,
  `user_id`   INT      NOT NULL,
  `game_id`   ENUM(
                'cyber_match',    -- WebView card-match game
                'firewall_drone', -- WebView flappy HTML game
                'shield_maze',    -- WebView SCORM maze
                'patrol',         -- Inline Flutter phishing patrol  (+10 XP/round, 3 rounds)
                'trivia',         -- Inline Flutter cyber trivia     (+10 XP/answer, 3 rounds)
                'password'        -- Inline Flutter password cracker (+10 XP/level, 3 levels)
              ) NOT NULL,
  `score`     INT      NOT NULL,
  `played_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_game`  (`user_id`, `game_id`),
  KEY `idx_played_at`  (`played_at`),
  CONSTRAINT `fk_game_scores_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 8. GAME LEADERBOARD  (best score per user per game — fast queries)
--    Mirrors Hive's  game_score_{userId}_{gameId}  best-score key
-- ============================================================
CREATE TABLE IF NOT EXISTS `game_leaderboard` (
  `id`         INT      NOT NULL AUTO_INCREMENT,
  `user_id`    INT      NOT NULL,
  `game_id`    ENUM(
                 'cyber_match',
                 'firewall_drone',
                 'shield_maze',
                 'patrol',
                 'trivia',
                 'password'
               ) NOT NULL,
  `best_score` INT      NOT NULL DEFAULT 0,
  `play_count` INT      NOT NULL DEFAULT 0,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_game`  (`user_id`, `game_id`),
  KEY `idx_game_score`       (`game_id`, `best_score`),
  CONSTRAINT `fk_leaderboard_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 9. THREAT REPORTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `threat_reports` (
  `id`           INT          NOT NULL AUTO_INCREMENT,
  `user_id`      INT                   DEFAULT NULL,   -- NULL = submitted anonymously
  `title`        VARCHAR(255) NOT NULL,
  `description`  TEXT         NOT NULL,
  `scam_type`    VARCHAR(100) NOT NULL,
  `evidence_url` VARCHAR(500)          DEFAULT NULL,
  `status`       ENUM('pending','reviewed','resolved') NOT NULL DEFAULT 'pending',
  `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status`     (`status`),
  KEY `idx_user_id`    (`user_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_reports_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 10. ADMIN ASSIGNMENTS  (super_admin assigns users to admins)
-- ============================================================
CREATE TABLE IF NOT EXISTS `admin_assignments` (
  `id`         INT      NOT NULL AUTO_INCREMENT,
  `admin_id`   INT      NOT NULL,
  `user_id`    INT      NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_assignment`  (`admin_id`, `user_id`),
  KEY `idx_admin_id`           (`admin_id`),
  KEY `idx_user_id`            (`user_id`),
  CONSTRAINT `fk_assignment_admin` FOREIGN KEY (`admin_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_assignment_user`  FOREIGN KEY (`user_id`)  REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 11. REALTIME EVENTS  (event bus for live updates)
--     Polled by /realtime/poll.php  every 4s  (forum users)
--     Streamed via SSE by /realtime/admin_stats.php  (admins)
-- ============================================================
CREATE TABLE IF NOT EXISTS `realtime_events` (
  `id`         INT      NOT NULL AUTO_INCREMENT,
  `event_type` ENUM(
                 'new_post',
                 'new_comment',
                 'new_like',
                 'score_submitted',
                 'new_user',
                 'rank_up',
                 'new_report'
               ) NOT NULL,
  `user_id`    INT               DEFAULT NULL,   -- who triggered the event
  `target_id`  INT               DEFAULT NULL,   -- post_id / comment_id / user_id
  `payload`    JSON              DEFAULT NULL,   -- {game_id, score, rank, preview…}
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_created_at`  (`created_at`),
  KEY `idx_event_type`  (`event_type`),
  KEY `idx_user_id`     (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- AUTO-CLEANUP: delete realtime_events older than 30 minutes
-- (requires MySQL Event Scheduler to be ON)
-- ============================================================
SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS `cleanup_realtime_events`;
CREATE EVENT `cleanup_realtime_events`
  ON SCHEDULE EVERY 30 MINUTE
  DO
    DELETE FROM `realtime_events`
    WHERE `created_at` < (NOW() - INTERVAL 30 MINUTE);


-- ============================================================
-- RE-ENABLE FOREIGN KEYS
-- ============================================================
SET foreign_key_checks = 1;


-- ============================================================
-- SEED DATA
-- ============================================================

-- 6 Forum Categories
INSERT IGNORE INTO `categories` (`id`, `name`, `description`, `icon`) VALUES
(1, 'Threat Intelligence',  'Latest cyber threat news, CVEs and advisories',      'radar'),
(2, 'Malware Analysis',     'Share samples, reverse engineering and IOCs',          'bug_report'),
(3, 'Ethical Hacking',      'Penetration testing, CTFs and red-team discussions',   'terminal'),
(4, 'Security Tools',       'Reviews, how-tos and configs for security tools',      'build'),
(5, 'General Discussion',   'Anything cybersecurity — news, careers, opinions',     'forum'),
(9999, 'Security Advisories & Fraud Alerts', 'Latest warnings, data breaches, and safety updates compiled by the AI reputation auditor.', 'security');


-- Default Super Admin account
-- Password: CyberAdmin@2026  (bcrypt hash below — change immediately after first login)
INSERT IGNORE INTO `users`
  (`id`, `username`, `email`, `password_hash`, `role`, `avatar`, `reputation_points`, `rank`)
VALUES (
  1,
  'cybershield_admin',
  'admin@innvikta.co.in',
  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: CyberAdmin@2026
  'super_admin',
  'avatar_1',
  9999,
  'Cyber Commander'
);


-- ============================================================
-- USEFUL VIEWS (optional — for fast admin queries)
-- ============================================================

-- Leaderboard view: top players across all games
CREATE OR REPLACE VIEW `v_global_leaderboard` AS
SELECT
  gl.user_id,
  u.username,
  u.avatar,
  u.rank,
  u.reputation_points,
  gl.game_id,
  gl.best_score,
  gl.play_count,
  RANK() OVER (PARTITION BY gl.game_id ORDER BY gl.best_score DESC) AS rank_position
FROM `game_leaderboard` gl
JOIN `users` u ON u.id = gl.user_id
ORDER BY gl.game_id, gl.best_score DESC;


-- Per-game stats view for /users/game_stats.php
CREATE OR REPLACE VIEW `v_game_stats_per_user` AS
SELECT
  user_id,
  game_id,
  MAX(score)  AS best_score,
  AVG(score)  AS avg_score,
  COUNT(*)    AS play_count,
  SUM(score)  AS total_xp
FROM `game_scores`
GROUP BY user_id, game_id;


-- Admin analytics view for /admin/users_analytics.php
CREATE OR REPLACE VIEW `v_admin_analytics` AS
SELECT
  aa.admin_id,
  COUNT(DISTINCT aa.user_id)              AS total_assigned_users,
  SUM(u.reputation_points)               AS total_reputation_points,
  (SELECT COUNT(*) FROM posts p
   WHERE p.user_id IN (
     SELECT user_id FROM admin_assignments WHERE admin_id = aa.admin_id
   ))                                     AS total_posts_by_users,
  (SELECT COUNT(*) FROM game_scores gs
   WHERE gs.user_id IN (
     SELECT user_id FROM admin_assignments WHERE admin_id = aa.admin_id
   ) AND DATE(gs.played_at) = CURDATE())  AS active_games_today
FROM `admin_assignments` aa
JOIN `users` u ON u.id = aa.user_id
GROUP BY aa.admin_id;


-- ============================================================
-- END OF SCHEMA
-- ============================================================
