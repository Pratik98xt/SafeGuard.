import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/bottomNav.dart';
import 'package:women_safety/services/permission_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.woman;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String? error = await userProvider.registerUser(
      _nameController.text,
      _emailController.text,
      _phoneController.text,
      _passwordController.text,
      _selectedRole,
    );

    if (error == null) {
      try {
        await PermissionService.requestAppPermissions();
      } catch (e) {
        debugPrint('Permission error on register: $e');
      }

      if (mounted) {
         Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNav()), 
          (route) => false
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Photo
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Role Selector
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SELECT YOUR ROLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _roleButton(UserRole.woman, 'Woman', Icons.person),
                      _roleButton(UserRole.child, 'Child', Icons.child_care),
                      _roleButton(
                        UserRole.guardian,
                        'Guardian',
                        Icons.security,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildField(
                    'FULL NAME',
                    'e.g. James',
                    Icons.person_outline,
                    _nameController,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    'PHONE NUMBER',
                    '+91 98765 43210',
                    Icons.phone_outlined,
                    _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    'EMAIL ADDRESS',
                    'name@email.com',
                    Icons.email_outlined,
                    _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    'PASSWORD',
                    '********',
                    Icons.lock_outline,
                    _passwordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _handleRegister,
                    child: const Text('Register'),
                  ),
                  const SizedBox(height: 24),
                  // ... same login link
                ],
              ),
            ),
    );
  }

  Widget _roleButton(UserRole role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : Colors.blue.shade50.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.blue.shade50.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
