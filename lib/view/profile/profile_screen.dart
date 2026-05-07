import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // Interactive Checklist State
  final List<Map<String, dynamic>> _checklist = [
    {"title": "Multi-Factor Authentication Enabled", "checked": true},
    {"title": "Unique Passwords for every account", "checked": true},
    {"title": "Weekly Software updates performed", "checked": false},
    {"title": "Spotted 10 simulated phishing attempts", "checked": false},
    {"title": "Installed a trusted Anti-Malware suite", "checked": true},
  ];

  void _toggleCheck(int index) {
    setState(() {
      _checklist[index]["checked"] = !_checklist[index]["checked"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstantsColor.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Icon(CupertinoIcons.person_crop_circle_fill, color: AppConstantsColor.primaryColor, size: 28),
            const SizedBox(width: 8),
            const Text(
              "Guardian Profile",
              style: TextStyle(
                fontFamily: 'Quicksand',
                color: AppConstantsColor.darkTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstantsColor.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppConstantsColor.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppConstantsColor.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppConstantsColor.primaryColor, width: 2),
                        ),
                        child: const Icon(
                          CupertinoIcons.shield_fill,
                          size: 50,
                          color: AppConstantsColor.primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppConstantsColor.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Cyber Defender Alex",
                    style: TextStyle(
                      color: AppConstantsColor.darkTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Guardian Level 4 • Elite Protector",
                    style: TextStyle(
                      color: AppConstantsColor.lightTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Stats
            Text(
              "Security Statistics",
              style: TextStyle(
                color: AppConstantsColor.darkTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _buildStatCard("24", "URLs Scanned", CupertinoIcons.link, AppConstantsColor.primaryColor),
                _buildStatCard("12 / 14", "Scams Spotted", CupertinoIcons.eye_fill, AppConstantsColor.secondaryColor),
                _buildStatCard("85.7%", "Scan Accuracy", CupertinoIcons.percent, AppConstantsColor.warningColor),
                _buildStatCard("Gold", "Shield Badge", CupertinoIcons.shield_fill, AppConstantsColor.dangerColor),
              ],
            ),
            const SizedBox(height: 24),

            // Best Practices Checklist
            Text(
              "Your Security Checklist",
              style: TextStyle(
                color: AppConstantsColor.darkTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Toggle items to keep track of your digital self-defense hygiene",
              style: TextStyle(
                color: AppConstantsColor.lightTextColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppConstantsColor.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstantsColor.unSelectedTextColor.withOpacity(0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _checklist.length,
                separatorBuilder: (context, index) => Divider(color: AppConstantsColor.unSelectedTextColor.withOpacity(0.3), height: 1),
                itemBuilder: (context, index) {
                  final item = _checklist[index];
                  return ListTile(
                    leading: IconButton(
                      icon: Icon(
                        item["checked"] ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
                        color: item["checked"] ? AppConstantsColor.secondaryColor : AppConstantsColor.lightTextColor,
                        size: 24,
                      ),
                      onPressed: () => _toggleCheck(index),
                    ),
                    title: Text(
                      item["title"],
                      style: TextStyle(
                        color: item["checked"] ? AppConstantsColor.darkTextColor : AppConstantsColor.lightTextColor,
                        fontSize: 14,
                        decoration: item["checked"] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Badge Collection Horizontal Showcase
            Text(
              "Earned Security Badges",
              style: TextStyle(
                color: AppConstantsColor.darkTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildBadgeCard(CupertinoIcons.shield_fill, AppConstantsColor.secondaryColor, "Scam Slayer", "Spotted 5 Phish"),
                  _buildBadgeCard(CupertinoIcons.search, AppConstantsColor.primaryColor, "URL Agent", "Scanned 3 Links"),
                  _buildBadgeCard(CupertinoIcons.bolt_fill, AppConstantsColor.warningColor, "First Step", "Onboarding Done"),
                  _buildBadgeCard(CupertinoIcons.lock_fill, AppConstantsColor.dangerColor, "Guardian Pro", "Checked Checklist"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstantsColor.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstantsColor.unSelectedTextColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppConstantsColor.darkTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppConstantsColor.lightTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(IconData icon, Color color, String title, String requirement) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstantsColor.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstantsColor.unSelectedTextColor.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppConstantsColor.darkTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            requirement,
            style: const TextStyle(
              color: AppConstantsColor.lightTextColor,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}