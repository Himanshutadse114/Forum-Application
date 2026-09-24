# CyberShield Forum — Backend Implementation Plan

> ⚠️ **Updated** — Full Game Tracking module added (Section 4)

> **Stack:** PHP 8.x (pure PHP, no framework) · MySQL (existing `android` DB) · JWT Auth  
> **Base URL:** `https://innvikta.co.in/cybershield/api` (already wired in the Flutter app)  
> **DB Credentials:** Already provided via `.env`

---

## 1. Technology Decisions

| Concern | Choice | Reason |
|---|---|---|
| Language | **PHP 8.1+** | Runs on any Apache/Nginx VPS, no framework overhead, easy to deploy |
| Auth | **JWT (HS256)** | App already sends `Authorization: Bearer <token>`; secret key provided |
| DB | **MySQL** (`android` DB) | Already provisioned |
| Password hashing | `password_hash()` / `password_verify()` | Bcrypt by default in PHP |
| CORS | One shared `cors.php` header file | Flutter needs `Access-Control-Allow-Origin` |
| Response format | `{"status":"success"/"error","data":...,"message":...}` | App parses exactly this shape |

---

## 2. Project Folder Structure

```
/var/www/html/cybershield/api/
├── .env                          ← DB + JWT secrets
├── config/
│   ├── db.php                    ← PDO connection
│   ├── jwt.php                   ← JWT encode/decode helpers
│   └── cors.php                  ← CORS + JSON headers
├── middleware/
│   └── auth.php                  ← Validates Bearer token, returns $user
│
├── auth/
│   ├── register.php              POST  – create user
│   ├── login.php                 POST  – return JWT + user object
│   ├── profile.php               GET/PUT – get / update own profile
│   └── update_reputation.php     POST  – add reputation points
│
├── categories/
│   └── list.php                  GET   – all forum categories
│
├── posts/
│   ├── list.php                  GET   – list posts (optional ?category_id & ?user_id)
│   ├── create.php                POST  – new post
│   └── like.php                  POST  – toggle like
│
├── comments/
│   ├── list.php                  GET   – ?post_id=X
│   └── create.php                POST  – new comment
│
├── users/
│   ├── profile.php               GET   – ?user_id=X (public profile)
│   ├── follow.php                POST  – follow a user
│   ├── unfollow.php              POST  – unfollow a user
│   ├── followers.php             GET   – ?user_id=X
│   ├── following.php             GET   – ?user_id=X
│   └── submit_score.php          POST  – game score → reputation
│
├── reports/
│   ├── list.php                  GET   – threat feed
│   ├── create.php                POST  – submit threat report
│   └── analyze.php               POST  – AI scam analysis (keyword-based or Gemini)
│
├── admin/
│   ├── users_analytics.php       GET   – admin dashboard analytics
│   └── user_detail.php           GET   – ?user_id=X
│
└── super_admin/
    ├── list_all.php              GET   – list all admins + users
    ├── create_admin.php          POST  – create new admin account
    ├── make_admin.php            POST  – promote user to admin
    ├── remove_admin.php          POST  – demote admin to user
    └── assign_user.php           POST  – assign user to admin
```

---

## 3. Database Schema (MySQL)

### 3.1 `users`
```sql
CREATE TABLE users (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  username         VARCHAR(50) UNIQUE NOT NULL,
  email            VARCHAR(100) UNIQUE NOT NULL,
  password_hash    VARCHAR(255) NOT NULL,
  role             ENUM('user','admin','super_admin') DEFAULT 'user',
  avatar           VARCHAR(20) DEFAULT 'avatar_1',
  reputation_points INT DEFAULT 0,
  rank             VARCHAR(50) DEFAULT 'Recruit',
  created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 3.2 `categories`
```sql
CREATE TABLE categories (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  description TEXT,
  icon        VARCHAR(50) DEFAULT 'shield'
);

-- Seed data
INSERT INTO categories (name, description, icon) VALUES
('Threat Intelligence', 'Latest cyber threat news and reports', 'radar'),
('Malware Analysis', 'Share malware samples and analysis', 'bug_report'),
('Ethical Hacking', 'Penetration testing discussions', 'terminal'),
('Security Tools', 'Reviews and how-tos for security tools', 'build'),
('General Discussion', 'Anything cybersecurity related', 'forum');
```

### 3.3 `posts`
```sql
CREATE TABLE posts (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT NOT NULL,
  category_id   INT NOT NULL,
  title         VARCHAR(255) NOT NULL,
  content       TEXT NOT NULL,
  is_anonymous  TINYINT(1) DEFAULT 0,
  likes_count   INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (category_id) REFERENCES categories(id)
);
```

### 3.4 `comments`
```sql
CREATE TABLE comments (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  post_id      INT NOT NULL,
  user_id      INT NOT NULL,
  content      TEXT NOT NULL,
  is_anonymous TINYINT(1) DEFAULT 0,
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (post_id) REFERENCES posts(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 3.5 `likes`
```sql
CREATE TABLE likes (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  post_id    INT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_like (user_id, post_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (post_id) REFERENCES posts(id)
);
```

### 3.6 `follows`
```sql
CREATE TABLE follows (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  follower_id     INT NOT NULL,
  following_id    INT NOT NULL,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_follow (follower_id, following_id),
  FOREIGN KEY (follower_id) REFERENCES users(id),
  FOREIGN KEY (following_id) REFERENCES users(id)
);
```

### 3.7 `game_scores`
```sql
CREATE TABLE game_scores (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  game_id    VARCHAR(50) NOT NULL,
  score      INT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 3.8 `threat_reports`
```sql
CREATE TABLE threat_reports (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT,
  title        VARCHAR(255) NOT NULL,
  description  TEXT NOT NULL,
  scam_type    VARCHAR(100) NOT NULL,
  evidence_url VARCHAR(500),
  status       ENUM('pending','reviewed','resolved') DEFAULT 'pending',
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 3.9 `admin_assignments`
```sql
CREATE TABLE admin_assignments (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  admin_id   INT NOT NULL,
  user_id    INT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_assignment (admin_id, user_id),
  FOREIGN KEY (admin_id) REFERENCES users(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 4. 🎮 Game Tracking Module (Full Detail)

### 4.1 All 6 Games & How They Submit Scores

| # | Game | `game_id` | Mechanism | Score Source |
|---|---|---|---|---|
| 1 | **CyberMatch** | `cyber_match` | WebView (HTML game) | JS → `FlutterGameChannel.postMessage({action:'submitScore', score})` |
| 2 | **Flying Shield** (Flappy) | `firewall_drone` | WebView (HTML game) | JS → `FlutterGameChannel.postMessage({action:'submitScore', score})` |
| 3 | **ShieldMaze** | `shield_maze` | WebView (SCORM package) | SCORM `LMSSetValue('score.raw', N)` → shim → JS channel |
| 4 | **Phishing Patrol** | `patrol` | Inline Flutter widget | `addReputationPoints(_gameScore)` (+10 XP per correct round, 3 rounds) |
| 5 | **Cyber Trivia** | `trivia` | Inline Flutter widget | `addReputationPoints(_gameScore)` (+10 XP per correct answer, 3 rounds) |
| 6 | **Password Cracker** | `password` | Inline Flutter widget | `addReputationPoints(_gameScore)` (+10 XP per correct level, 3 levels) |

> **Important distinction:**  
> Games 1–3 (WebView) call `submitGameScore()` → `POST /users/submit_score.php`  
> Games 4–6 (Inline Flutter) call `addReputationPoints()` → `POST /auth/update_reputation.php`  
> Both paths must update reputation + rank + leaderboard on the backend.

---

### 4.2 What Happens When a Score is Submitted (Full Flow)

```
Game ends
  │
  ▼
Flutter: saveGameScore() in Hive
  │  ├─ Stores personal best (only if score > current best)
  │  └─ Appends to game_history list
  │
  ▼
Flutter: updateRepAndRank() in Hive  ← instant local update (offline-safe)
  │
  ▼
POST /users/submit_score.php  { user_id, game_id, score }
  │
  ├─ INSERT into game_scores (every attempt logged)
  ├─ UPDATE users SET reputation_points = reputation_points + score
  ├─ Recalculate rank → UPDATE users SET rank = '...'
  ├─ UPDATE/INSERT into game_leaderboard (best score per user per game)
  └─ Return { status, new_reputation, new_rank, is_new_best }
  │
  ▼
Flutter: fetchProfile() to sync server state back
```

---

### 4.3 Database Tables for Game Tracking

#### `game_scores` — Every attempt (full history)
```sql
CREATE TABLE game_scores (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  game_id    ENUM(
               'cyber_match',    -- WebView card matcher
               'firewall_drone', -- WebView HTML flappy game  
               'shield_maze',    -- WebView SCORM maze
               'patrol',         -- Inline phishing detection (+10 XP/round)
               'trivia',         -- Inline cybersecurity quiz (+10 XP/round)
               'password'        -- Inline password security quiz (+10 XP/level)
             ) NOT NULL,
  score      INT NOT NULL,
  played_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### `game_leaderboard` — Best score per user per game
```sql
CREATE TABLE game_leaderboard (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  game_id    ENUM('cyber_match','firewall_drone','shield_maze','patrol','trivia','password') NOT NULL,
  best_score INT NOT NULL DEFAULT 0,
  play_count INT NOT NULL DEFAULT 0,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user_game (user_id, game_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

> **Why two tables?**  
> `game_scores` = full audit trail / history (matches Hive's `game_history_*` list).  
> `game_leaderboard` = fast leaderboard queries (matches Hive's `game_score_*` best-score key).

---

### 4.4 Game Endpoints

| Method | Path | Auth? | Description |
|---|---|---|---|
| POST | `/users/submit_score.php` | ✅ | Submit a score → update reputation + leaderboard |
| GET | `/users/leaderboard.php` | ✅ | Global leaderboard (optional ?game_id filter) |
| GET | `/users/game_history.php` | ✅ | Own game history (?game_id optional) |
| GET | `/users/game_stats.php` | ✅ | Own stats per game (best, avg, count) |

---

### 4.5 `POST /users/submit_score.php` — Full Logic

```
Input:  { user_id, game_id, score }

1. Validate JWT → get auth user_id
2. Validate score > 0 and game_id is valid
3. INSERT INTO game_scores (user_id, game_id, score)
4. INSERT INTO game_leaderboard ... ON DUPLICATE KEY UPDATE
     best_score = IF(score > best_score, score, best_score),
     play_count = play_count + 1
5. UPDATE users SET
     reputation_points = reputation_points + score,
     rank = [recalculated rank]
   WHERE id = user_id
6. SELECT new reputation_points, rank, and is_new_best FROM DB
7. Return:
   {
     "status": "success",
     "data": {
       "new_reputation": 780,
       "new_rank": "Security Expert",
       "is_new_best": true,
       "best_score": 320
     }
   }
```

---

### 4.6 `GET /users/leaderboard.php` — Response Shape

```json
{
  "status": "success",
  "data": [
    {
      "rank_position": 1,
      "user_id": 12,
      "username": "CyberHunter",
      "avatar": "avatar_3",
      "rank": "Cyber Commander",
      "game_id": "cyber_match",
      "best_score": 950,
      "play_count": 14
    },
    ...
  ]
}
```

Query: `SELECT ... FROM game_leaderboard lb JOIN users u ON u.id=lb.user_id WHERE game_id=? ORDER BY best_score DESC LIMIT 50`

---

### 4.7 `GET /users/game_stats.php` — Per-User Stats

```json
{
  "status": "success",
  "data": {
    "cyber_match":    { "best_score": 320, "avg_score": 210, "play_count": 8 },
    "firewall_drone": { "best_score": 150, "avg_score": 120, "play_count": 5 },
    "shield_maze":    { "best_score": 90,  "avg_score": 75,  "play_count": 3 },
    "patrol":         { "best_score": 30,  "avg_score": 20,  "play_count": 12 },
    "trivia":         { "best_score": 30,  "avg_score": 25,  "play_count": 9 },
    "password":       { "best_score": 30,  "avg_score": 20,  "play_count": 7 }
  }
}
```

---

### 4.8 Rank Recalculation (called inside submit_score.php)

```php
// helpers/rank.php
function calculateRank(int $rep): string {
    if ($rep >= 1000) return 'Cyber Commander';
    if ($rep >= 500)  return 'Security Expert';
    if ($rep >= 250)  return 'Security Analyst';
    return 'Recruit';
}
```

This is identical to the Flutter-side logic — both will always agree on rank.

---

### 4.9 Anti-Cheat Considerations

| Rule | Implementation |
|---|---|
| Score must be `> 0` | Validate in PHP before INSERT |
| Score ceiling per game | See table below — reject anything above max |
| Cooldown | Max 1 submission per user per game per minute |
| JWT user must match `user_id` param | Always use `$authUser['id']` from JWT, ignore POST `user_id` |

**Max score caps per game:**

| Game | `game_id` | Max Score | Reason |
|---|---|---|---|
| CyberMatch | `cyber_match` | 1000 | Card match pairs, each worth points |
| Flying Shield | `firewall_drone` | 500 | 100 packets × 5 XP each |
| ShieldMaze | `shield_maze` | 100 | SCORM score.raw 0–100 |
| Phishing Patrol | `patrol` | 30 | 3 rounds × 10 XP max |
| Cyber Trivia | `trivia` | 30 | 3 questions × 10 XP max |
| Password Cracker | `password` | 30 | 3 levels × 10 XP max |

---

## 5. Auth Flow

```
Register ──► Hash password (bcrypt) ──► INSERT users ──► 200 success
Login    ──► Verify password ──► Issue JWT (id, username, role, exp) ──► Return token + user
All other endpoints ──► Middleware reads Authorization: Bearer <token>
                    ──► Decode + validate JWT ──► inject $authUser
```

**JWT Payload:**
```json
{
  "iss": "cybershield_api",
  "sub": 42,
  "username": "himanshu",
  "role": "user",
  "iat": 1715000000,
  "exp": 1715086400
}
```

---

## 5. Rank Calculation (server-side mirror of Flutter logic)

| Reputation | Rank |
|---|---|
| 0–249 | Recruit |
| 250–499 | Security Analyst |
| 500–999 | Security Expert |
| 1000+ | Cyber Commander |

This logic lives in a shared `helpers/rank.php` function called by `update_reputation.php` and `submit_score.php`.

---

## 6. Endpoint Specification Summary

### Auth
| Method | Path | Auth? | Key Params |
|---|---|---|---|
| POST | `/auth/register.php` | No | username, email, password |
| POST | `/auth/login.php` | No | username, password |
| GET | `/auth/profile.php` | ✅ | — |
| PUT | `/auth/profile.php` | ✅ | username?, avatar?, reputation_points? |
| POST | `/auth/update_reputation.php` | ✅ | reputation_points, action(`add`) |

### Forum
| Method | Path | Auth? | Key Params |
|---|---|---|---|
| GET | `/categories/list.php` | ✅ | — |
| GET | `/posts/list.php` | ✅ | category_id?, user_id? |
| POST | `/posts/create.php` | ✅ | category_id, title, content, is_anonymous |
| POST | `/posts/like.php` | ✅ | post_id (toggle) |
| GET | `/comments/list.php` | ✅ | post_id |
| POST | `/comments/create.php` | ✅ | post_id, content, is_anonymous |

### Users / Social
| Method | Path | Auth? | Key Params |
|---|---|---|---|
| GET | `/users/profile.php` | ✅ | user_id |
| POST | `/users/follow.php` | ✅ | target_user_id |
| POST | `/users/unfollow.php` | ✅ | target_user_id |
| GET | `/users/followers.php` | ✅ | user_id |
| GET | `/users/following.php` | ✅ | user_id |
| POST | `/users/submit_score.php` | ✅ | user_id, game_id, score |

### Reports
| Method | Path | Auth? | Key Params |
|---|---|---|---|
| GET | `/reports/list.php` | ✅ | — |
| POST | `/reports/create.php` | ✅ | title, description, scam_type, evidence_url? |
| POST | `/reports/analyze.php` | ✅ | content (text to analyze) |

### Admin
| Method | Path | Auth? | Role? |
|---|---|---|---|
| GET | `/admin/users_analytics.php` | ✅ | admin+ |
| GET | `/admin/user_detail.php` | ✅ | admin+ |

### Super Admin
| Method | Path | Auth? | Role? |
|---|---|---|---|
| GET | `/super_admin/list_all.php` | ✅ | super_admin |
| POST | `/super_admin/create_admin.php` | ✅ | super_admin |
| POST | `/super_admin/make_admin.php` | ✅ | super_admin |
| POST | `/super_admin/remove_admin.php` | ✅ | super_admin |
| POST | `/super_admin/assign_user.php` | ✅ | super_admin |

---

## 7. Implementation Order (Sprints)

### Sprint 1 — Foundation (Day 1)
1. `config/db.php` — PDO connection using `.env`
2. `config/jwt.php` — encode/decode helpers (pure PHP, no library needed)
3. `config/cors.php` — shared CORS headers
4. `helpers/rank.php` — rank calculation
5. `middleware/auth.php` — validate Bearer token

### Sprint 2 — Auth (Day 1-2)
6. `auth/register.php`
7. `auth/login.php`
8. `auth/profile.php` (GET + PUT)
9. `auth/update_reputation.php`

### Sprint 3 — Forum Core (Day 2-3)
10. `categories/list.php`
11. `posts/list.php`
12. `posts/create.php`
13. `posts/like.php`
14. `comments/list.php`
15. `comments/create.php`

### Sprint 4 — Users & Social (Day 3)
16. `users/profile.php`
17. `users/follow.php` + `unfollow.php`
18. `users/followers.php` + `following.php`
19. `users/submit_score.php`

### Sprint 5 — Reports (Day 4)
20. `reports/list.php`
21. `reports/create.php`
22. `reports/analyze.php` (keyword scoring, optionally call Gemini API)

### Sprint 6 — Admin & Super Admin (Day 4-5)
23. `admin/users_analytics.php`
24. `admin/user_detail.php`
25. `super_admin/list_all.php`
26. `super_admin/create_admin.php`
27. `super_admin/make_admin.php`
28. `super_admin/remove_admin.php`
29. `super_admin/assign_user.php`

### Sprint 7 — Database Setup & Seed (Day 1, parallel)
- Run `schema.sql` to create all tables
- Seed categories
- Create initial super_admin account

---

## 8. Security Checklist

- [x] JWT secret in `.env`, never in PHP files
- [x] PDO prepared statements (no raw SQL concat)
- [x] `password_hash()` / `password_verify()` (bcrypt)
- [x] Role-based access enforcement in every admin/super_admin endpoint
- [x] CORS locked to trusted origins in production
- [x] Input validation + sanitization on all POST params
- [x] `is_anonymous` posts hide username/avatar in response (return `"Anonymous Sentinel"`)

---

## 9. Anonymous Post Handling

When `is_anonymous = 1`:
- `author_name` → `"Anonymous Sentinel"`
- `author_avatar` → `"avatar_anon"`
- `author_rank` → `"WhiteHat"` 
- **Do NOT expose `user_id`** in the list response (set to `0`)

---

## 10. `reports/analyze.php` — Scam Detection Logic

Simple keyword scoring (no external API needed for MVP):

```
Response shape expected by app:
{
  "status": "success",
  "analyzer": "CyberShield AI v2.0",
  "data": {
    "scam_likelihood_score": 85,
    "threat_level": "HIGH",
    "confidence": "89%",
    "indicators_found": ["urgency language", "prize claim", "suspicious URL"],
    "recommendations": ["Do not click links", "Report to authorities"]
  }
}
```

Keyword categories: urgency, money, links, personal-info requests, prize claims → weighted score 0-100.

---

> **Ready to build?**  
> Say "start with Sprint 1" and I'll generate all the PHP files for the foundation layer.
