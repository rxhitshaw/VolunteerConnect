import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/app_user.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../provider/provider_dashboard_shell.dart';
import 'login_screen.dart';

/// Role-aware registration screen collecting volunteer preferences or organizer details.
class SignUpScreen extends StatefulWidget {
  final UserRole targetRole;

  const SignUpScreen({
    super.key,
    required this.targetRole,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Provider specific controllers
  final _orgNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedOrgType = 'NGO';

  // Volunteer specific preferences
  final Set<String> _selectedCauses = {'Environment', 'Community Support'};
  final Set<String> _selectedSkills = {'Teamwork', 'Communication'};
  final Set<String> _selectedDays = {'Saturday', 'Sunday'};

  final List<String> _allCauses = [
    'Environment',
    'Education',
    'Food Donation',
    'Animal Welfare',
    'Community Support',
    'Healthcare',
  ];

  final List<String> _allSkills = [
    'Teamwork',
    'Teaching',
    'Gardening',
    'First Aid',
    'Logistics',
    'Communication',
    'Animal Care',
  ];

  final List<String> _allDays = [
    'Saturday',
    'Sunday',
    'Weekdays',
    'Weekends',
    'Mornings',
    'Evenings',
  ];

  final List<String> _orgTypes = [
    'NGO',
    'School',
    'Community Group',
    'Individual Organizer',
  ];

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isVolunteer => widget.targetRole == UserRole.volunteer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgNameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isVolunteer) {
      if (_selectedCauses.isEmpty) {
        setState(() => _errorMessage = 'Please select at least one cause of interest.');
        return;
      }
      if (_selectedDays.isEmpty) {
        setState(() => _errorMessage = 'Please select at least one availability option.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppUser? newUser;

      if (_isVolunteer) {
        newUser = await StorageService.registerVolunteer(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          preferredCauses: _selectedCauses,
          skills: _selectedSkills,
          availabilityDays: _selectedDays,
        );
      } else {
        newUser = await StorageService.registerProvider(
          organizationName: _orgNameController.text.trim(),
          contactPerson: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          organizationType: _selectedOrgType,
          phone: _phoneController.text.trim(),
          description: _descController.text.trim(),
        );
      }

      if (!mounted) return;

      if (newUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This email address is already registered. Please sign in instead.';
        });
        return;
      }

      // Successful registration -> Navigate to role dashboard
      if (_isVolunteer) {
        Navigator.pushAndRemoveUntil<void>(
          context,
          MaterialPageRoute(builder: (ctx) => const MainNavigationShell()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil<void>(
          context,
          MaterialPageRoute(builder: (ctx) => const ProviderDashboardShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Registration failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isVolunteer ? 'Volunteer Registration' : 'Provider Registration';

    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isVolunteer ? 'Join as a Volunteer' : 'Register as an Organizer',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreenDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isVolunteer
                      ? 'Create your profile to start finding impactful activities matching your passions.'
                      : 'Create an organizer account to post opportunities and recruit local volunteers.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Provider specific: Organization Name
                if (!_isVolunteer) ...[
                  TextFormField(
                    controller: _orgNameController,
                    decoration: InputDecoration(
                      labelText: 'Organization / Initiative Name *',
                      prefixIcon: const Icon(Icons.business, color: AppTheme.forestGreen),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Please enter organization name.' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedOrgType,
                    decoration: InputDecoration(
                      labelText: 'Organization Type *',
                      prefixIcon: const Icon(Icons.category, color: AppTheme.forestGreen),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: _orgTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedOrgType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Name field (Full name or contact person)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _isVolunteer ? 'Full Name *' : 'Contact Person Name *',
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.forestGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Please enter your name.' : null,
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.forestGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your email.';
                    if (!val.contains('@') || !val.contains('.')) return 'Please enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password (min. 6 characters) *',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.forestGreen),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.forestGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Provider optional fields
                if (!_isVolunteer) ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Phone Number (Optional)',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.forestGreen),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Organization Mission / Description (Optional)',
                      prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.forestGreen),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],

                // Volunteer preference chips
                if (_isVolunteer) ...[
                  const Divider(height: 32),
                  const Text(
                    'Preferred Causes (Select all that apply):',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allCauses.map((c) {
                      final sel = _selectedCauses.contains(c);
                      return FilterChip(
                        label: Text(c, style: TextStyle(fontSize: 12, color: sel ? AppTheme.forestGreenDark : Colors.black87)),
                        selected: sel,
                        selectedColor: AppTheme.paleGreen,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedCauses.add(c);
                            } else {
                              _selectedCauses.remove(c);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Your Skills:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allSkills.map((s) {
                      final sel = _selectedSkills.contains(s);
                      return FilterChip(
                        label: Text(s, style: TextStyle(fontSize: 12, color: sel ? AppTheme.forestGreenDark : Colors.black87)),
                        selected: sel,
                        selectedColor: AppTheme.paleGreen,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedSkills.add(s);
                            } else {
                              _selectedSkills.remove(s);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Your Availability:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allDays.map((d) {
                      final sel = _selectedDays.contains(d);
                      return FilterChip(
                        label: Text(d, style: TextStyle(fontSize: 12, color: sel ? AppTheme.forestGreenDark : Colors.black87)),
                        selected: sel,
                        selectedColor: AppTheme.paleGreen,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedDays.add(d);
                            } else {
                              _selectedDays.remove(d);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // Submit Button
                FilledButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isVolunteer ? 'Complete Volunteer Registration' : 'Register Organization',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 16),

                // Switch to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(fontSize: 13)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement<void, void>(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => LoginScreen(targetRole: widget.targetRole),
                          ),
                        );
                      },
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
