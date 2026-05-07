-- CyberShield Forum MySQL Schema
-- Suitable for phpMyAdmin and MySQL 8.0+

-- CREATE DATABASE and USE queries removed for shared hosting compatibility. Runs inside the selected database.

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `avatar` VARCHAR(255) DEFAULT 'default_avatar.png',
  `role` VARCHAR(20) DEFAULT 'user', -- 'user', 'moderator', 'admin'
  `reputation_points` INT DEFAULT 10,
  `rank` VARCHAR(50) DEFAULT 'WhiteHat Trainee', -- 'WhiteHat Trainee', 'Cyber Scout', 'Security Analyst', 'Threat Hunter', 'Elite Hacker'
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS `categories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL UNIQUE,
  `description` VARCHAR(255) NOT NULL,
  `icon` VARCHAR(50) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. POSTS TABLE (Forum Threads)
CREATE TABLE IF NOT EXISTS `posts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `category_id` INT NOT NULL,
  `title` VARCHAR(150) NOT NULL,
  `content` TEXT NOT NULL,
  `is_anonymous` TINYINT(1) DEFAULT 0,
  `likes_count` INT DEFAULT 0,
  `comments_count` INT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. COMMENTS TABLE
CREATE TABLE IF NOT EXISTS `comments` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `post_id` INT NOT NULL,
  `user_id` INT NOT NULL,
  `content` TEXT NOT NULL,
  `is_anonymous` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. LIKES TABLE (Tracks post engagement)
CREATE TABLE IF NOT EXISTS `likes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `post_id` INT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `user_post_like` (`user_id`, `post_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. REPORTS TABLE (Scam / Threat reporting)
CREATE TABLE IF NOT EXISTS `reports` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT DEFAULT NULL, -- Nullable for anonymous reports
  `title` VARCHAR(150) NOT NULL,
  `description` TEXT NOT NULL,
  `scam_type` VARCHAR(50) NOT NULL, -- 'phishing', 'vishing', 'ransomware', 'impersonation', 'crypto_scam', 'other'
  `evidence_url` VARCHAR(255) DEFAULT NULL,
  `status` VARCHAR(20) DEFAULT 'pending', -- 'pending', 'under_review', 'verified', 'dismissed'
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `type` VARCHAR(50) NOT NULL, -- 'like', 'comment', 'report_status', 'achievement'
  `title` VARCHAR(100) NOT NULL,
  `message` TEXT NOT NULL,
  `is_read` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. ACHIEVEMENTS TABLE
CREATE TABLE IF NOT EXISTS `achievements` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `badge_name` VARCHAR(50) NOT NULL,
  `badge_icon` VARCHAR(50) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `user_badge` (`user_id`, `badge_name`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. FOLLOWS TABLE (Tracks follower/following relations)
CREATE TABLE IF NOT EXISTS `follows` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `follower_id` INT NOT NULL,
  `followed_id` INT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `follower_followed_idx` (`follower_id`, `followed_id`),
  FOREIGN KEY (`follower_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`followed_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- SEED DATA FOR CATEGORIES
INSERT INTO `categories` (`name`, `description`, `icon`) VALUES
('Phishing Alerts', 'Report and analyze suspicious emails, malicious URLs, SMS scams, and social engineering attacks.', 'alternate_email'),
('Ransomware & Malware', 'Discuss threats, analyze virus payloads, decryption updates, and endpoint defense tactics.', 'security_update_warning'),
('Scam Reports', 'Community-driven log of active digital scams, financial frauds, and online impersonations.', 'gavel'),
('General Cyber Talk', 'General discussions about cybersecurity trends, tools, hardware hacking, and industry events.', 'forum'),
('Security Best Practices', 'Share tips, checklists, guides, and procedures for secure browsing and organizational safety.', 'fact_check');

-- SEED DATA FOR AN INITIAL ADMIN USER (Password is: 'AdminPass123!')
-- Password hash generated using BCRYPT (PHP standard)
INSERT INTO `users` (`username`, `email`, `password_hash`, `role`, `reputation_points`, `rank`) VALUES
('cybershield_admin', 'admin@cybershield.org', '$2y$10$tZre0eN0O4j6.U/P9MizbOL8GjVj68HjUf8Uqg7mN0u5tN3X8wM6y', 'admin', 500, 'Cyber Security Commander');

-- SEED DATA FOR DEMO POSTS
INSERT INTO `posts` (`user_id`, `category_id`, `title`, `content`, `is_anonymous`, `likes_count`, `comments_count`) VALUES
(1, 1, '⚠️ Beware of "Innvikta Delivery" SMS Scam!', 'There is currently an active phishing campaign sending SMS text messages pretending to be "Innvikta Post" asking to click a URL to confirm shipment details. DO NOT click it! The domain registered is `innvikta-delivery-failed.com` which is hosting a credential harvesting page targeting bank accounts. Stay safe out there!', 0, 15, 2);

-- SEED DATA FOR DEMO COMMENTS
INSERT INTO `comments` (`post_id`, `user_id`, `content`, `is_anonymous`) VALUES
(1, 1, 'Wow, thanks for the heads up! I almost clicked one of these yesterday. The URL looked very suspicious.', 1);
