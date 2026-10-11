import 'package:flutter/material.dart';
import 'models/app_user.dart';
import 'models/opportunity.dart';
import 'models/user_profile.dart';
import 'screens/activities_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/provider/provider_dashboard_shell.dart';
import 'screens/recommendations_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VolunteerConnectApp());
}

/// The root widget of VolunteerConnect.
class VolunteerConnectApp extends StatelessWidget {
  const VolunteerConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VolunteerConnect',
      theme: AppTheme.lightTheme,
      home: const SessionRouter(),
    );
  }
}

/// Determines whether to display WelcomeScreen, Volunteer Dashboard, or Provider Dashboard
/// based on persisted authentication session.
class SessionRouter extends StatefulWidget {
  const SessionRouter({super.key});

  @override
  State<SessionRouter> createState() => _SessionRouterState();
}

class _SessionRouterState extends State<SessionRouter> {
  bool _isLoading = true;
  AppUser? _session;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      await StorageService.initializeData();
      final session = await StorageService.getCurrentSession();
      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _session = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.forestGreen),
        ),
      );
    }

    if (_session == null) {
      return const WelcomeScreen();
    }

    if (_session!.isProvider) {
      return const ProviderDashboardShell();
    }

    return const MainNavigationShell();
  }
}

/// Shell hosting the Material 3 bottom navigation bar and state synchronization for Volunteers.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isLoading = true;
  late UserProfile _userProfile;
  List<Opportunity> _opportunities = [];

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final profile = await StorageService.loadProfile();
    final opps = await StorageService.loadOpportunities();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _opportunities = opps;
        _isLoading = false;
      });
    }
  }

  Future<void> _persistState() async {
    await StorageService.saveProfile(_userProfile);
    final opps = await StorageService.loadOpportunities();
    if (mounted) {
      setState(() {
        _opportunities = opps;
      });
    }
  }

  void _resetData() async {
    await StorageService.clearProfile(_userProfile.userId);
    final fresh = await StorageService.loadProfile(_userProfile.userId);
    final opps = await StorageService.loadOpportunities();
    if (mounted) {
      setState(() {
        _userProfile = fresh;
        _opportunities = opps;
      });
    }
  }

  void _switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.forestGreen),
        ),
      );
    }

    final screens = [
      HomeScreen(
        userProfile: _userProfile,
        opportunities: _opportunities,
        onDataChanged: _persistState,
      ),
      RecommendationsScreen(
        userProfile: _userProfile,
        opportunities: _opportunities,
        onDataChanged: _persistState,
        onGoToProfile: () => _switchToTab(3),
      ),
      ActivitiesScreen(
        userProfile: _userProfile,
        opportunities: _opportunities,
        onDataChanged: _persistState,
        onBrowseOpportunities: () => _switchToTab(0),
      ),
      ProfileScreen(
        userProfile: _userProfile,
        onProfileSaved: _persistState,
        onResetData: _resetData,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchToTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'For You',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _userProfile.joinedOpportunityIds.isNotEmpty,
              label: Text('${_userProfile.joinedOpportunityIds.length}'),
              child: const Icon(Icons.task_alt_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _userProfile.joinedOpportunityIds.isNotEmpty,
              label: Text('${_userProfile.joinedOpportunityIds.length}'),
              child: const Icon(Icons.task_alt),
            ),
            label: 'Activities',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
