import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/bottomNav.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.none;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('SAFEGUARD+', style: TextStyle(fontSize: 14, letterSpacing: 2)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Choose Your Role',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please select your primary role to customize your safety features and emergency alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            _buildRoleCard(
              UserRole.woman,
              'WOMAN',
              'Emergency SOS & Live Tracking',
              Icons.person,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              UserRole.child,
              'CHILD',
              'Simple One-Tap Help & Geofencing',
              Icons.school_outlined,
              Colors.brown,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              UserRole.guardian,
              'GUARDIAN',
              'Monitor Loved Ones & Get Alerts',
              Icons.group_outlined,
              Colors.grey,
            ),

            const Spacer(),
            ElevatedButton(
              onPressed: _selectedRole == UserRole.none 
                ? null 
                : () {
                    userProvider.setRole(_selectedRole);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const BottomNav()),
                      (route) => false,
                    );
                  },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Continue'),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(UserRole role, String title, String subtitle, IconData icon, Color color) {
    bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryBlue)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
