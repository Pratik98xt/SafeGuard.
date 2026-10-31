import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/screens/alerts/notification_screen.dart';
import 'package:women_safety/screens/home/woman_dashboard.dart';
import 'package:women_safety/screens/home/child_dashboard.dart';
import 'package:women_safety/screens/home/guardian_dashboard.dart';
import 'package:women_safety/screens/map/map_screen.dart';
import 'package:women_safety/screens/profile/profile_screen.dart';
import 'package:women_safety/screens/community/community_screen.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'package:women_safety/models/notification_model.dart';
import 'package:women_safety/widgets/notification_manager.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final role = userProvider.selectedRole;
    final currentUserId = userProvider.currentUser?.uid;

    final List<Widget> screens = [
      _getHomeDashboard(role),
      const MapScreen(),
      const NotificationScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    return NotificationManager(
      child: Scaffold(
        body: screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryBlue,
              unselectedItemColor: Colors.grey.shade400,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedFontSize: 12,
              unselectedFontSize: 10,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  activeIcon: Icon(Icons.dashboard_rounded, size: 28),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.location_on_rounded),
                  activeIcon: Icon(Icons.location_on_rounded, size: 28),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: _buildNotificationIcon(currentUserId, false),
                  activeIcon: _buildNotificationIcon(currentUserId, true),
                  label: 'Notifications',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.campaign_rounded),
                  activeIcon: Icon(Icons.campaign_rounded, size: 28),
                  label: 'Community',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  activeIcon: Icon(Icons.person_rounded, size: 28),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getHomeDashboard(UserRole role) {
    switch (role) {
      case UserRole.woman:
        return const WomanDashboard();
      case UserRole.child:
        return const ChildDashboard();
      case UserRole.guardian:
        return const GuardianDashboard();
      default:
        return const WomanDashboard();
    }
  }

  Widget _buildNotificationIcon(String? userId, bool isActive) {
    if (userId == null) {
      return Icon(Icons.notifications_rounded, size: isActive ? 28 : 24);
    }

    return StreamBuilder<List<AppNotification>>(
      stream: _firestoreService.getNotificationsByReceiver(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData
            ? snapshot.data!.where((n) => !n.isRead).length
            : 0;

        return Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
          child: Icon(Icons.notifications_rounded, size: isActive ? 28 : 24),
        );
      },
    );
  }
}
