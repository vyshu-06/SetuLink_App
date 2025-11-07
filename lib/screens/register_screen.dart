import 'package:flutter/material.dart';

// Mock translation function - replace with easy_localization when integrated
String tr(String key) {
  final translations = {
    'citizen_login': 'Citizen Login',
    'craftizen_login': 'Craftizen Login',
    'welcome_back': 'Welcome Back!',
    'login_to_continue': 'Login to continue to your account',
    'email': 'Email',
    'password': 'Password',
    'email_required': 'Email is required',
    'enter_valid_email': 'Please enter a valid email',
    'password_required': 'Password is required',
    'password_min_6': 'Password must be at least 6 characters',
    'remember_me': 'Remember me',
    'forgot_password': 'Forgot Password?',
    'login': 'Login',
    'logging_in': 'Logging in...',
    'or': 'OR',
    'login_with_phone': 'Login with Phone',
    'dont_have_account': "Don't have an account?",
    'sign_up': 'Sign Up',
    'feature_coming_soon': 'Feature coming soon!',
    'login_success': 'Login successful!',
    'login_failed': 'Login failed. Please check your credentials.',
    'login_error': 'Login error',
    'dismiss': 'Dismiss',
  };
  return translations[key] ?? key;
}

// Mock CustomButton widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const CustomButton({
    required this.text,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: onPressed == null ? 0 : 2,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Mock AuthService
class AuthService {
  Future<Map<String, dynamic>?> signInWithEmail(
      String email,
      String password,
      String role,
      ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock authentication logic
    if (email == 'test@example.com' && password == 'password123') {
      return {
        'uid': '123456',
        'email': email,
        'role': role,
        'name': role == 'citizen' ? 'John Doe' : 'Jane Smith',
      };
    }
    return null;
  }
}

// Mock Home Screens
class CitizenHome extends StatelessWidget {
  final Map<String, dynamic> userObj;

  const CitizenHome({required this.userObj, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citizen Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${userObj['name']}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Email: ${userObj['email']}'),
            Text('Role: ${userObj['role']}'),
          ],
        ),
      ),
    );
  }
}

class CraftizenHome extends StatelessWidget {
  final Map<String, dynamic> userObj;

  const CraftizenHome({required this.userObj, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Craftizen Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.engineering, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${userObj['name']}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Email: ${userObj['email']}'),
            Text('Role: ${userObj['role']}'),
          ],
        ),
      ),
    );
  }
}

// Mock PhoneAuthScreen
class PhoneAuthScreen extends StatelessWidget {
  final String role;

  const PhoneAuthScreen({required this.role, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Authentication')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text('Phone Auth for $role'),
            const SizedBox(height: 20),
            const Text('This feature is under development'),
          ],
        ),
      ),
    );
  }
}

// Main LoginScreen - DEBUGGED VERSION
class LoginScreen extends StatefulWidget {
  final String role; // "citizen" or "craftizen"
  const LoginScreen({required this.role, Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String email = '';
  String password = '';
  bool loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Email validation regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Show error snackbar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: tr('dismiss'),
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Show success snackbar
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Handle login
  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      final result = await AuthService()
          .signInWithEmail(email, password, widget.role);

      if (!mounted) return;

      setState(() => loading = false);

      if (result == null) {
        _showError(tr('login_failed'));
      } else {
        _showSuccess(tr('login_success'));

        // Navigate after a short delay for better UX
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.role == 'citizen'
                ? CitizenHome(userObj: result)
                : CraftizenHome(userObj: result),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showError('${tr('login_error')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.role == "citizen" ? 'citizen_login' : 'craftizen_login')),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or Icon
                Icon(
                  widget.role == 'citizen' ? Icons.person : Icons.engineering,
                  size: 80,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 32),

                // Welcome Text
                Text(
                  tr('welcome_back'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  tr('login_to_continue'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr('email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (val) {
                    email = val.trim();
                  },
                  onFieldSubmitted: (_) {
                    _passwordFocusNode.requestFocus();
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return tr('email_required');
                    }
                    if (!_isValidEmail(val)) {
                      return tr('enter_valid_email');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: tr('password'),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (val) {
                    password = val;
                  },
                  onFieldSubmitted: (_) {
                    _handleLogin();
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return tr('password_required');
                    }
                    if (val.length < 6) {
                      return tr('password_min_6');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                        ),
                        Text(tr('remember_me')),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        _showError(tr('feature_coming_soon'));
                      },
                      child: Text(tr('forgot_password')),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Button
                CustomButton(
                  text: loading ? tr('logging_in') : tr('login'),
                  onPressed: loading ? null : _handleLogin,
                ),

                // Loading Indicator
                if (loading) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],

                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        tr('or'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Phone Login Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: Text(tr('login_with_phone')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: loading ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhoneAuthScreen(role: widget.role),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('dont_have_account'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        _showError(tr('feature_coming_soon'));
                      },
                      child: Text(
                        tr('sign_up'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // Demo Credentials Info
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Demo Credentials:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Email: test@example.com',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Password: password123',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
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

// Demo app to test the login screen
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Role'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose Your Role',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.person, size: 30),
                label: const Text(
                  'Citizen Login',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(role: 'citizen'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.engineering, size: 30),
                label: const Text(
                  'Craftizen Login',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(role: 'craftizen'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}