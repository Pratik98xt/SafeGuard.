// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:women_safety/theme/app_theme.dart';
// import 'package:women_safety/screens/auth/register_screen.dart';
// import 'package:women_safety/providers/user_provider.dart';
// import 'package:women_safety/bottomNav.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isLoading = false;

//   void _handleLogin() async {
//     if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Please enter email and password')));
//       return;
//     }

//     setState(() => _isLoading = true);
//     final userProvider = Provider.of<UserProvider>(context, listen: false);

//     bool success = await userProvider.loginUser(
//       _emailController.text,
//       _passwordController.text,
//     );

//     if (success) {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const BottomNav()),
//         );
//       }
//     } else {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Failed. Check your credentials.')));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: _isLoading
//         ? const Center(child: CircularProgressIndicator())
//         : SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             children: [
//               const SizedBox(height: 60),
//               // Shield Icon
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(color: AppTheme.backgroundBlue, shape: BoxShape.circle),
//                 child: const Icon(Icons.security, size: 60, color: AppTheme.primaryBlue),
//               ),
//               const SizedBox(height: 24),
//               const Text('SafeGuard+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
//               const Text('Your safety is our priority.', style: TextStyle(fontSize: 16, color: Colors.black54)),
//               const SizedBox(height: 48),

//               // Fields
//               _buildField('EMAIL ADDRESS', 'name@email.com', Icons.person_outline, _emailController),
//               const SizedBox(height: 24),
//               _buildField('PASSWORD', '********', Icons.lock_outline, _passwordController, obscureText: true),

//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () {},
//                   child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
//                 ),
//               ),
//               const SizedBox(height: 8),

//               ElevatedButton(
//                 onPressed: _handleLogin,
//                 child: const Text('Login'),
//               ),
//               const SizedBox(height: 20),

//               const Icon(Icons.fingerprint, size: 40, color: Colors.blue),
//               const SizedBox(height: 30),

//               OutlinedButton(
//                 onPressed: () {
//                   Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
//                 },
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 55),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                   side: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 child: const Text('Create Account', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
//               ),
//               // ... same emergency access button
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildField(String label, String hint, IconData icon, TextEditingController controller, {bool obscureText = false}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 1.0)),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           obscureText: obscureText,
//           decoration: InputDecoration(
//             hintText: hint,
//             prefixIcon: Icon(icon, color: Colors.grey),
//             filled: true,
//             fillColor: Colors.blue.shade50.withOpacity(0.3),
//           ),
//         ),
//       ],
//     );
//   }
// }
//               const SizedBox(height: 24),

//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   borderRadius: BorderRadius.circular(15),
//                   border: Border.all(color: Colors.red.withOpacity(0.2)),
//                 ),
//                 child: const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
//                     SizedBox(width: 8),
//                     Text(
//                       'Emergency Access Without Login',
//                       style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 40),

//               const Text.rich(
//                 TextSpan(
//                   text: 'By continuing, you agree to our ',
//                   style: TextStyle(fontSize: 12, color: Colors.grey),
//                   children: [
//                     TextSpan(
//                       text: 'Terms of Service',
//                       style: TextStyle(decoration: TextDecoration.underline),
//                     ),
//                     TextSpan(text: ' and '),
//                     TextSpan(
//                       text: 'Privacy Policy',
//                       style: TextStyle(decoration: TextDecoration.underline),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/screens/auth/register_screen.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/bottomNav.dart';
import 'package:women_safety/services/permission_service.dart';
import 'package:women_safety/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String? error = await userProvider.loginUser(
      _emailController.text,
      _passwordController.text,
    );

    if (error == null) {
      // Request permissions once sequentially after login
      try {
        await PermissionService.requestAppPermissions();
      } catch (e) {
        debugPrint('Permission error on login: $e');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNav()),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your registered email address to receive a password reset link.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              final error = await AuthService().resetPassword(email);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error ?? 'Password reset link sent! Check your inbox.',
                    ),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 60,
                        color: AppTheme.primaryBlue,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'SafeGuard+',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const Text(
                      'Your safety is our priority.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),

                    const SizedBox(height: 48),

                    _buildField(
                      'EMAIL ADDRESS',
                      'name@email.com',
                      Icons.email_outlined,
                      _emailController,
                    ),
                    const SizedBox(height: 24),

                    _buildField(
                      'PASSWORD',
                      '********',
                      Icons.lock_outline,
                      _passwordController,
                      obscureText: true,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Login'),
                    ),

                    const SizedBox(height: 20),

                    const Icon(Icons.fingerprint, size: 40, color: Colors.blue),

                    const SizedBox(height: 30),

                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 40),

                    const Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
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
