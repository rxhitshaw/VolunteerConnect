import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Professional Welcome screen featuring the VolunteerConnect brand identity
/// and clear role selection between Volunteer and Opportunity Provider.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateToLogin(BuildContext context, UserRole role) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => LoginScreen(targetRole: role),
      ),
    );
  }

  void _navigateToSignUp(BuildContext context, UserRole role) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => SignUpScreen(targetRole: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Brand Logo & Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.forestGreenDark, AppTheme.forestGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.forestGreen.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'VolunteerConnect',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.forestGreenDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Connecting passion with purpose. Join local initiatives or organize impactful community service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Role Selection Header
              const Text(
                'Select how you want to participate:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Option 1: Volunteer Card
              _roleCard(
                context: context,
                icon: Icons.person_search,
                badge: 'For Individuals',
                title: 'Continue as Volunteer',
                subtitle:
                    'Discover local causes, match with activities by skills & availability, earn verified hours, and level up your impact rank.',
                primaryActionText: 'Volunteer Log In',
                secondaryActionText: 'New Volunteer Sign Up',
                accentColor: AppTheme.forestGreen,
                onPrimary: () => _navigateToLogin(context, UserRole.volunteer),
                onSecondary: () => _navigateToSignUp(context, UserRole.volunteer),
              ),
              const SizedBox(height: 20),

              // Option 2: Opportunity Provider Card
              _roleCard(
                context: context,
                icon: Icons.corporate_fare,
                badge: 'For Organizations & Leaders',
                title: 'Continue as Opportunity Provider',
                subtitle:
                    'Publish community service events, set volunteer slot capacities, review registered participants, and manage logistics.',
                primaryActionText: 'Provider Log In',
                secondaryActionText: 'Register Organization',
                accentColor: const Color(0xFF1E5B53),
                onPrimary: () => _navigateToLogin(context, UserRole.provider),
                onSecondary: () => _navigateToSignUp(context, UserRole.provider),
              ),

              const SizedBox(height: 32),

              // Hackathon transparency footer note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: AppTheme.forestGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo Auth Mode: Passwords cryptographically hashed (SHA-256) on-device. Session state persists locally.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
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

  Widget _roleCard({
    required BuildContext context,
    required IconData icon,
    required String badge,
    required String title,
    required String subtitle,
    required String primaryActionText,
    required String secondaryActionText,
    required Color accentColor,
    required VoidCallback onPrimary,
    required VoidCallback onSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.paleGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    primaryActionText,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accentColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    secondaryActionText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
