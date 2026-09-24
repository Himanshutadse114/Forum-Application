# Innvikta / CyberShield Home Page UI & Layout Specification

This document details the UI design system, structure, layout components, and widget hierarchy of the Innvikta Home Page (Dashboard). The application features two different home page implementations: the **Active Home Feed** and the **Alternative Threat Investigator Dashboard**.

---

## 1. Design System & Theme Configuration
The application runs on the **Kinetic Security** design theme (configured in [theme.dart](file:///c:/sneakers_app/lib/core/theme.dart)). It utilizes a modern high-contrast aesthetic that pairs warm off-whites with neon accents.

### Color Palette
*   **Background:** `#FBFBF8` (Cream Off-White) - reduces eye strain.
*   **Surface:** `#FFFFFF` (Clean White Cards).
*   **Primary Accent:** `#FF6B00` (Vibrant Arcade Orange) - used for focus states, highlights, and primary actions.
*   **Secondary Accent:** `#1A1C1C` (Deep Charcoal) - used for secondary buttons and text.
*   **Status Colors:**
    *   *Warning:* `#FFB300` (Amber)
    *   *Danger:* `#BA1A1A` (Red)
    *   *Success:* `#2E7D32` (Green)

### Typography
*   **Space Grotesk** (Headings & Brand Titles): Geometric sans-serif with a futuristic, technical aesthetic.
*   **Inter** (Body text, UI labels, description paragraphs): Highly legible sans-serif.

---

## 2. Active Home Page Layout (Innvikta Feed)
The active home page is rendered inside [dashboard_screen.dart](file:///c:/sneakers_app/lib/features/dashboard/screens/dashboard_screen.dart) under the `_HomeFeedView` widget when the bottom navigation index is `0`.

### Navigation Shell Structure
*   **AppBar:**
    *   *Left:* "INNVIKTA" branding text in Space Grotesk bold (`fontSize: 20`, color: `CyberTheme.primary`).
    *   *Right:* Notification Icon (`notifications_outlined`) with a red badge dot (`CyberTheme.primary`) showing a modal overlay with recent alerts.
*   **Bottom Navigation Bar:**
    *   Pill-shaped floating capsule container with dual-shadows (`boxShadow` on `#F9FAFB` background).
    *   Tabs: **Home** (Active), **Forums**, **Games**, **Ranks**, and **Profile**.
*   **Navigation Drawer:**
    *   Features profile header displaying the user's avatar, username, and role-based actions (including access to Super Admin or Admin Analytics screens).

### Feed Body Layout
The body is wrapped in a `SingleChildScrollView` to support smooth scrolling:

1.  **Premium Hero Banner Card:**
    *   *Background:* Cream Peach (`#FFF9F5`) with container shadows.
    *   *Left Column:* 
        *   Heading: "Connect. Share." (Charcoal) followed by "Learn. Grow." (Arcade Orange) in Space Grotesk (`fontSize: 22`).
        *   Subtitle: "Join a community of thinkers and level up every day."
        *   Action Button: "Explore Now" (Orange pill button).
    *   *Right Illustration:* Aligned image `assets/images/innvikta_hero.png` partially layered in a stack.
2.  **Carousel Page Indicators:**
    *   Horizontal dot indicators positioned below the hero banner.
3.  **Quick Actions Grid:**
    *   Heading: "Quick Actions" in Space Grotesk (`fontSize: 16`).
    *   Row of three interactive cards with 3D shadows:
        *   **Scanner:** "Scan SMS" (navigates to SMS scanner).
        *   **Forums:** "Discuss" (navigates to forum section).
        *   **Games:** "Play" (navigates to games section).
4.  **Trending Discussions:**
    *   Header: "Trending Discussions" row with a clickable "View all" action.
    *   Cards listing active threads with threat title, author, relative time, and comment counts.

### Active Home Screen Layout Mockup
```
+--------------------------------------------------------+
|  [Logo] INNVIKTA                              [Notif]  |
+--------------------------------------------------------+
|                                                        |
|  +--------------------------------------------------+  |
|  | Connect. Share.                    +----------+  |  |
|  | Learn. Grow.                       |   Hero   |  |  |
|  | Join community of thinkers...       |  Image   |  |  |
|  | [ Explore Now ]                    +----------+  |  |
|  +--------------------------------------------------+  |
|                         ( O o o )                      |
|                                                        |
|  Quick Actions                                         |
|  +-------------+  +-------------+  +-------------+     |
|  |   Scanner   |  |   Forums    |  |    Games    |     |
|  |  Scan SMS   |  |   Discuss   |  |    Play     |     |
|  +-------------+  +-------------+  +-------------+     |
|                                                        |
|  Trending Discussions                        View All  |
|  +--------------------------------------------------+  |
|  | [!] What's the biggest threat in 2026?            |  |
|  |     by CyberNinja * 2h ago       [Chat Bubble] 32|  |
|  +--------------------------------------------------+  |
|                                                        |
|    +----------------------------------------------+    |
|    | [Home]  [Forums]  [Games]  [Ranks]  [Profile]|    |
|    +----------------------------------------------+    |
+--------------------------------------------------------+
```

---

## 3. Alternative Home Page Layout (Defender Dashboard)
The alternative layout is located in [home_screen.dart](file:///c:/sneakers_app/lib/view/home/home_screen.dart) and serves as an interactive threat scanner dashboard. It uses a dark cyber slate design.

### Dark Palette Settings
*   **Background:** `#0B0F19` (Slate Dark)
*   **Card Background:** `#161B22` (Dark Card)
*   **Accent Primary:** `#00E5FF` (Electric Cyber Cyan)
*   **Text Primary:** `#FFFFFF` (White)
*   **Text Secondary:** `#8B949E` (Muted Grey)

### Dashboard Layout Components
1.  **AppBar:**
    *   Branding: "Innvikta" accompanied by a cyan Shield icon (`CupertinoIcons.shield_fill`).
    *   Right Icon: Notification bell (`CupertinoIcons.bell_fill`).
2.  **Safety Status Header:**
    *   Large title: "Defender Dashboard"
    *   Subtitle: "Train yourself to spot and block malicious scams"
3.  **Safety Score Circular Card:**
    *   Left side: Circular progress indicator displaying `85%` completion score.
    *   Right side: Status title "Safety Status: Safe" (Green) and details text: *"You've spotted 12 of 14 phishing simulations correctly."*
4.  **URL Threat Investigator Card:**
    *   Section title: "URL Threat Investigator"
    *   Input: `TextField` to paste suspicious links, with a cyan link prefix icon.
    *   Button: "Scan Link" (Cyan solid background).
    *   Dynamic Results: Shows alert banner containing safety heuristics checks (domain spoofing, IP addresses, suspicious TLDs, or missing HTTPS encryption).
5.  **Daily Tip Card:**
    *   Warning amber lightbulb icon with title: "Tip of the Day".
    *   Content explaining domain-spoofing techniques.
6.  **Security Quick Guides Grid:**
    *   A 2x2 grid containing informative cards:
        *   **Password Safety** (Lock icon, primary cyan highlight)
        *   **Spotting Phish** (Eye icon, green highlight)
        *   **2FA Setup** (Phone icon, warning amber highlight)
        *   **Social Scams** (People icon, danger red highlight)

---

## 4. Flutter Widget Hierarchy Comparison

### Active Home Screen (`_HomeFeedView`)
```
Scaffold
 ├── appBar: AppBar (Title: INNVIKTA, Action: Notification Icon button)
 ├── drawer: Drawer (UserAccountsDrawerHeader + Navigation Items)
 ├── body: subViews[_currentIndex] -> _HomeFeedView
 │    └── SingleChildScrollView (AlwaysScrollableScrollPhysics)
 │         └── Column
 │              ├── Container (Hero Banner Stack)
 │              │    └── Padding
 │              │         └── Column (Title, Subtitle, "Explore Now" button)
 │              ├── Row (Carousel Dots)
 │              ├── Text ("Quick Actions")
 │              ├── Row (3x _buildQuickActionCard)
 │              ├── Row ("Trending Discussions" Header)
 │              └── Column (_buildFilteredDiscussions)
 └── bottomNavigationBar: Container
      └── ClipRRect (Radius: 24)
           └── BottomNavigationBar (Home, Forums, Games, Ranks, Profile)
```

### Alternative Home Screen (`HomeScreen`)
```
Scaffold
 ├── backgroundColor: AppConstantsColor.backgroundColor
 ├── appBar: AppBar (Title: CupertinoIcons.shield_fill + "Innvikta", Action: Bell Icon button)
 └── body: SingleChildScrollView (BouncingScrollPhysics)
      └── Column (Padding: 16)
           ├── Text ("Defender Dashboard")
           ├── Text ("Train yourself...")
           ├── Container (Safety Score Card)
           │    └── Row
           │         ├── Stack (CircularProgressIndicator + "85%" Text)
           │         └── Column ("Safety Status: Safe", Stats Text)
           ├── Text ("URL Threat Investigator")
           ├── Container (Scan Input Card)
           │    └── Column
           │         ├── TextField (Input URL)
           │         ├── ElevatedButton ("Scan Link")
           │         └── Container (Heuristics Threat Result details)
           ├── Container (Tip of the Day Card)
           │    └── Column (Lightbulb Icon + Threat Tip text)
           ├── Text ("Security Quick Guides")
           └── GridView.count (2x2 Quick Guide cards)
```
