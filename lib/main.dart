import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'custom_cradle_border.dart';
import 'database_helper.dart';
import 'api_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign-In Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A3E2B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A3E2B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5A3E2B),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAuthAction() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        // Sign-Up registration flow
        final success = await DatabaseHelper.instance.registerUser(email, password);
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Success dialog
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                title: const Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text('Account registered successfully! You can now sign in.'),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _isSignUp = false;
                        _formKey.currentState?.reset();
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: const Text('Go to Sign-In'),
                  ),
                ],
              );
            },
          );
        } else {
          _showWarningDialog('Registration Failed', 'This email address is already registered.');
        }
      } else {
        // Sign-In login & verification flow
        final verified = await DatabaseHelper.instance.verifyUser(email, password);
        
        if (!verified) {
          setState(() {
            _isLoading = false;
          });
          _showWarningDialog('Verification Failed', 'Invalid Credentials. The email or password you entered is incorrect.');
          return;
        }

        // Call list API after successful login verification
        final response = await http.get(Uri.parse('https://api.npoint.io/f7cdabeb07cef7eb8a67'));
        
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> productsJson = data['products'] ?? [];
          final products = productsJson.map((p) => Product.fromJson(p)).toList();

          if (!mounted) return;

          // Clear fields on success
          _passwordController.clear();

          // Navigate to ApiScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ApiScreen(
                products: products,
                userEmail: email,
              ),
            ),
          );
        } else {
          _showWarningDialog('API Error', 'Successfully logged in, but failed to load the product list from the API.');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showWarningDialog('Error', 'An unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final brownColor = isDark ? const Color(0xFFD7CCC8) : const Color(0xFF5A3E2B);
    final placeholderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
    final buttonColor = isDark ? const Color(0xFF383838) : const Color(0xFFDBDBDB);
    final buttonTextColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top breadcrumb text
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text(
                    _isSignUp ? 'Sign-Up' : 'Log In',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Form Container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rounded rectangle placeholder
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: placeholderColor,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Center(
                              child: Icon(
                                _isSignUp ? Icons.person_add_outlined : Icons.fingerprint,
                                size: 80,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Form Title
                          Text(
                            _isSignUp ? 'Create Account' : 'Sign-In',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Email Input field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                              alignLabelWithHint: true,
                              border: CradleInputBorder(
                                borderSide: BorderSide(color: brownColor, width: 1.5),
                              ),
                              enabledBorder: CradleInputBorder(
                                borderSide: BorderSide(
                                  color: isDark ? Colors.grey[700]! : const Color(0xFF8D6E63), 
                                  width: 1.5
                                ),
                              ),
                              focusedBorder: CradleInputBorder(
                                borderSide: BorderSide(color: brownColor, width: 2.2),
                              ),
                              errorBorder: const CradleInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 1.5),
                              ),
                              focusedErrorBorder: const CradleInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 2.2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Password Input field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                            onFieldSubmitted: (_) => _isSignUp ? null : _handleAuthAction(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                              alignLabelWithHint: true,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: CradleInputBorder(
                                borderSide: BorderSide(color: brownColor, width: 1.5),
                              ),
                              enabledBorder: CradleInputBorder(
                                borderSide: BorderSide(
                                  color: isDark ? Colors.grey[700]! : const Color(0xFF8D6E63), 
                                  width: 1.5
                                ),
                              ),
                              focusedBorder: CradleInputBorder(
                                borderSide: BorderSide(color: brownColor, width: 2.2),
                              ),
                              errorBorder: const CradleInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 1.5),
                              ),
                              focusedErrorBorder: const CradleInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 2.2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Confirm Password Field (Only shown in Sign-Up mode)
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleAuthAction(),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                                alignLabelWithHint: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                border: CradleInputBorder(
                                  borderSide: BorderSide(color: brownColor, width: 1.5),
                                ),
                                enabledBorder: CradleInputBorder(
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey[700]! : const Color(0xFF8D6E63), 
                                    width: 1.5
                                  ),
                                ),
                                focusedBorder: CradleInputBorder(
                                  borderSide: BorderSide(color: brownColor, width: 2.2),
                                ),
                                errorBorder: const CradleInputBorder(
                                  borderSide: BorderSide(color: Colors.red, width: 1.5),
                                ),
                                focusedErrorBorder: const CradleInputBorder(
                                  borderSide: BorderSide(color: Colors.red, width: 2.2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Dotted separator line
                          DottedLine(
                            color: isDark ? Colors.grey[800]! : Colors.grey[400]!,
                            height: 1.5,
                            dashWidth: 4,
                            dashSpace: 3,
                          ),
                          const SizedBox(height: 24),
                          
                          // Action Button
                          Center(
                            child: SizedBox(
                              width: 180,
                              height: 48,
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : InkWell(
                                      onTap: _handleAuthAction,
                                      borderRadius: BorderRadius.zero,
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          color: buttonColor,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _isSignUp ? 'Sign-Up' : 'Sign-In',
                                            style: TextStyle(
                                              color: buttonTextColor,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Toggle Auth Mode
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp ? "Already have an account? " : "Don't have an account? ",
                                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _formKey.currentState?.reset();
                                    _emailController.clear();
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                  });
                                },
                                child: Text(
                                  _isSignUp ? "Sign-In" : "Sign-Up",
                                  style: TextStyle(
                                    color: brownColor,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DottedLine extends StatelessWidget {
  const DottedLine({
    super.key,
    this.height = 1,
    this.color = Colors.black38,
    this.dashWidth = 4,
    this.dashSpace = 3,
  });

  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
