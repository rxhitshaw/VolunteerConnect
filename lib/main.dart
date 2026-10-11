import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'screens/activities_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
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
      home: const MainNavigationShell(),
    );
  }
}

/// Shell hosting the Material 3 bottom navigation bar and state synchronization.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isLoading = true;
  late UserProfile _userProfile;

  @override
  void initState() {
    super.initState();
    _loadStoredProfile();
  }

  Future<void> _loadStoredProfile() async {
    final profile = await StorageService.loadProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  void _persistState() {
    StorageService.saveProfile(_userProfile);
    setState(() {});
  }

  void _resetData() {
    setState(() {
      _userProfile = UserProfile();
    });
    _persistState();
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
        onDataChanged: _persistState,
      ),
      RecommendationsScreen(
        userProfile: _userProfile,
        onDataChanged: _persistState,
        onGoToProfile: () => _switchToTab(3),
      ),
      ActivitiesScreen(
        userProfile: _userProfile,
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
