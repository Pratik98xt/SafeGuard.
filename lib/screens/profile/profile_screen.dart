import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/models/user_model.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/screens/contacts/contacts_screen.dart';
import 'package:women_safety/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _safetyAlerts = true;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Profile Header
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name.trim()[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${userProvider.selectedRole.name.toUpperCase()} ROLE',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (user.guardianId != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'ID: ${user.guardianId}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 30),

            // Settings List
            _buildSettingSection('ACCOUNT DETAILS', [
              _buildSettingItem(
                Icons.person_outline,
                'Edit Profile',
                onTap: () =>
                    _showEditProfileDialog(context, userProvider, user),
              ),
              _buildSettingItem(
                Icons.people_outline,
                'Emergency Contacts',
                subtitle: 'Manage your safety circle',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactsScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                Icons.lock_outline,
                'Change Password',
                onTap: () => _showChangePasswordDialog(context, userProvider),
              ),
            ]),
            _buildSettingSection('PREFERENCES & APP', [
              _buildSettingItem(
                Icons.language_outlined,
                'Language',
                trailing: 'English (US)',
              ),
              _buildSwitchSettingItem(
                Icons.notifications_outlined,
                'Safety Alerts',
                _safetyAlerts,
                (v) => setState(() => _safetyAlerts = v),
              ),
            ]),

            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await userProvider.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.2)),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SafeGuard+ Version 2.4.1 (Build 890)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    UserProvider provider,
    UserModel user,
  ) {
    final nameCtl = TextEditingController(text: user.name);
    final phoneCtl = TextEditingController(text: user.phone);
    final addrCtl = TextEditingController(text: user.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneCtl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: addrCtl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final error = await provider.updateProfile(
                name: nameCtl.text.trim(),
                phone: phoneCtl.text.trim(),
                address: addrCtl.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error == null
                          ? 'Profile updated!'
                          : 'Failed to update profile: $error',
                    ),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, UserProvider provider) {
    final currentPass = TextEditingController();
    final newPass = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPass,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            TextField(
              controller: newPass,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (currentPass.text.isEmpty || newPass.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter current and new password'),
                  ),
                );
                return;
              }
              bool success = await provider.changePassword(
                currentPass.text,
                newPass.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Password changed successfully!'
                          : 'Failed to change password. Please check your current password.',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title, {
    String? subtitle,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailing,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchSettingItem(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryBlue,
      ),
    );
  }
}
