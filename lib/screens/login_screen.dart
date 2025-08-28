import 'package:flutter/material.dart';
import 'package:saferide_ai_app/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final String _adminPassword = "admin123"; // Admin password for multi-user dashboard
  final String _userPassword = "user123"; // User password for detection
  String _selectedRole = "User"; // Default role

  Future<void> _login() async {
    if (_selectedRole == "Admin" && _passwordController.text == _adminPassword) {
      // Admin login - navigate to multi-user admin dashboard
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else if (_selectedRole == "User" && _passwordController.text == _userPassword) {
      // User login - navigate to detection screen for monitoring
      Navigator.pushReplacementNamed(context, '/detection');
    } else {
      String expectedPassword = _selectedRole == "Admin" ? _adminPassword : _userPassword;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect password for $_selectedRole! Use: $expectedPassword'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.car_rental,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // App Title
              const Text(
                'SafeRide AI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Driver Safety Monitoring System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Login Card
              Card(
                elevation: 8,
                color: AppConstants.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Login to SafeRide AI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Role Selection
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.backgroundDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            dropdownColor: AppConstants.backgroundDark,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            items: const [
                              DropdownMenuItem(
                                value: "User",
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.blue, size: 20),
                                    SizedBox(width: 12),
                                    Text("User - Detection Mode"),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: "Admin",
                                child: Row(
                                  children: [
                                    Icon(Icons.dashboard, color: Colors.purple, size: 20),
                                    SizedBox(width: 12),
                                    Text("Admin - Multi-User Dashboard"),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedRole = newValue!;
                                _passwordController.clear(); // Clear password when role changes
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: _selectedRole == "Admin" 
                              ? 'Enter admin password (admin123)'
                              : 'Enter user password (user123)',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppConstants.primaryColor),
                          ),
                          filled: true,
                          fillColor: AppConstants.backgroundDark,
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRole == "Admin" 
                                ? Colors.purple 
                                : AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'Login as $_selectedRole',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Help Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'User Password: user123',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.dashboard, color: Colors.purple, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Admin Password: admin123',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
