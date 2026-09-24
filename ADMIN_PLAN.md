# Detailed Implementation Plan: Role-Based Access Control & Admin Analytics

## Overview
This document outlines the architecture for a comprehensive Admin and Super Admin system. The Super Admin has the ultimate authority to create Admins and arbitrarily map any User to any Admin. Admins, in turn, have a dedicated dashboard to monitor the analytics, score progress, and detailed profiles of the specific Users assigned to them.

## 1. Database Schema Changes

To allow the Super Admin to assign any User to any Admin, we will modify the existing `users` table.

1. **Add `role` support for `super_admin`**:
   The application logic will be updated to recognize `'super_admin'`, alongside the existing `'admin'` and `'user'` roles.
   
2. **Add `assigned_admin_id` Column**:
   This column will store the ID of the Admin responsible for a given User. Only the Super Admin can change this value.

**SQL Migration:**
```sql
ALTER TABLE `users`
ADD COLUMN `assigned_admin_id` INT DEFAULT NULL;

ALTER TABLE `users`
ADD CONSTRAINT `fk_assigned_admin` FOREIGN KEY (`assigned_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
```

## 2. Backend API Implementation (PHP)

All new APIs will be secured by JWT and role-checking middleware. We will create two distinct sets of APIs: one for Super Admins and one for Admins.

### A. Super Admin APIs (`backend/api/super_admin/`)
*Requires `role === 'super_admin'`*

1. **`POST /api/super_admin/create_admin.php`**
   - **Purpose**: Create a new account with the `admin` role.
   - **Payload**: `{ "username": "...", "email": "...", "password": "..." }`

2. **`GET /api/super_admin/list_all.php`**
   - **Purpose**: Fetch lists of all Admins and all Users to populate the assignment UI.

3. **`POST /api/super_admin/assign_user.php`**
   - **Purpose**: Allows the Super Admin to assign *any* User to *any* Admin.
   - **Payload**: `{ "user_id": 123, "admin_id": 456 }`
   - **Logic**: Updates the `assigned_admin_id` of the target user to the chosen `admin_id`.

### B. Admin APIs (`backend/api/admin/`)
*Requires `role === 'admin'` or `'super_admin'`*

1. **`GET /api/admin/my_users.php`**
   - **Purpose**: Fetches the list of Users assigned to the requesting Admin (i.e., where `assigned_admin_id` matches the Admin's token ID).

2. **`GET /api/admin/users_analytics.php`**
   - **Purpose**: Aggregated analytics for all Users assigned to this Admin.
   - **Data Returned**: 
     - Total reputation points of assigned users.
     - Average game scores across all assigned users.
     - Recent activity/posts from assigned users.

3. **`GET /api/admin/user_detail.php?user_id=123`**
   - **Purpose**: Deep dive into a single assigned User.
   - **Security**: Verifies that the requested `user_id` is actually assigned to the requesting Admin.
   - **Data Returned**:
     - **Profile Info**: Email, Rank, Avatar, Total Reputation, Join Date.
     - **Overall Leaderboard**: Data from the `leaderboard` table.
     - **Game-Specific Score Progress**: Queries the individual game tables (`scores_shield_maze`, `scores_phishing_patrol`, `scores_cyber_trivia`, etc.) to return a timeline of the user's score progression.
     - **Forum Activity**: Recent posts and comments made by the user.

## 3. Frontend Implementation (Flutter)

The Flutter app will feature new dashboards based on the logged-in user's role.

### 1. Super Admin Dashboard
- **User-to-Admin Assignment UI**: A dedicated screen where the Super Admin sees a list of all standard Users. Next to each User, there is a dropdown containing all available Admins. The Super Admin can select an Admin from the dropdown to instantly assign the User to them.
- **Admin Management**: A screen to register new Admins.

### 2. Admin Analytics Dashboard
When an Admin logs in, they are presented with a rich data dashboard exclusively for their assigned subset of Users.
- **Assigned Users List**: A data table displaying all their assigned Users, showing their current Rank and Total Reputation at a glance.
- **Global Analytics View**: Charts showing the overall progress of their assigned group (e.g., average scores improving over time).
- **User Detail Screen (Deep Dive)**:
  - Clicking on a specific User opens their detailed profile.
  - **Progress Charts**: Line charts (using a package like `fl_chart`) plotting the user's score history over time for specific games (e.g., Phishing Patrol, Shield Maze).
  - **Activity Log**: A feed of the user's recent forum posts, reported scams, and unlocked achievements.

## 4. Execution Steps

1. **Database Update**: Execute the `ALTER TABLE` commands to enable the `assigned_admin_id` mapping.
2. **Backend Development**:
   - Create the `super_admin` and `admin` API directories.
   - Implement the `assign_user.php` endpoint first to establish relationships.
   - Implement the `user_detail.php` endpoint with complex `JOIN` queries to fetch the game score history from the various `scores_*` tables.
3. **Frontend Development**:
   - Build the Super Admin UI for assigning users.
   - Build the Admin Dashboard with charts and analytics for score progress tracking.
4. **Integration & Testing**:
   - Test that an Admin *cannot* view the detailed analytics of a User assigned to a *different* Admin.
