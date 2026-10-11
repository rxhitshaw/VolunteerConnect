import 'package:flutter/material.dart';
import '../../models/opportunity.dart';
import '../../models/provider_profile.dart';
import '../../models/volunteer_registration.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../auth/welcome_screen.dart';
import 'create_opportunity_screen.dart';
import 'provider_opportunities_screen.dart';
import 'provider_participants_screen.dart';

/// Main navigation shell for Opportunity Providers and Community Organizers.
class ProviderDashboardShell extends StatefulWidget {
  const ProviderDashboardShell({super.key});

  @override
  State<ProviderDashboardShell> createState() => _ProviderDashboardShellState();
}

class _ProviderDashboardShellState extends State<ProviderDashboardShell> {
  int _currentIndex = 0;
  bool _isLoading = true;
  late ProviderProfile _providerProfile;
  List<Opportunity> _myOpportunities = [];
  List<VolunteerRegistration> _myParticipants = [];

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    final session = await StorageService.getCurrentSession();
    final providerId = session?.id ?? 'usr-prov-demo';
    final profile = await StorageService.loadProviderProfile(providerId);
    final allOpps = await StorageService.loadOpportunities();
    final mine = allOpps.where((o) => o.providerId == providerId).toList();
    final parts = await StorageService.getParticipantsForProvider(providerId);

    if (mounted) {
      setState(() {
        _providerProfile = profile;
        _myOpportunities = mine;
        _myParticipants = parts;
        _isLoading = false;
      });
    }
  }

  void _onDataChanged() {
    _loadProviderData();
  }

  void _openCreateScreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => CreateOpportunityScreen(
          providerProfile: _providerProfile,
          onOpportunitySaved: _onDataChanged,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to end your current organizer session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearSession();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil<void>(
        context,
        MaterialPageRoute(builder: (ctx) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.forestGreen)),
      );
    }

    final screens = [
      _buildOverviewTab(),
      ProviderOpportunitiesScreen(
        providerProfile: _providerProfile,
        onDataChanged: _onDataChanged,
      ),
      ProviderParticipantsScreen(providerProfile: _providerProfile),
      _buildProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _openCreateScreen,
              backgroundColor: AppTheme.forestGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'My Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Participants',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Org Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final openCount = _myOpportunities.where((o) => o.isOpen).length;
    final totalSlots = _myOpportunities.fold<int>(0, (sum, o) => sum + o.spotsTotal);

    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.paleGreen,
                    radius: 22,
                    child: Text(
                      _providerProfile.organizationName.isNotEmpty
                          ? _providerProfile.organizationName[0].toUpperCase()
                          : 'O',
                      style: const TextStyle(
                        color: AppTheme.forestGreenDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _providerProfile.organizationName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forestGreenDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_providerProfile.organizationType} • Contact: ${_providerProfile.contactPerson}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log Out',
                    icon: const Icon(Icons.logout, color: Colors.grey),
                    onPressed: _handleLogout,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.forestGreenDark, AppTheme.forestGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organizer Impact Portal',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${_myOpportunities.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Published Activities',
                          style: TextStyle(color: AppTheme.paleGreen, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricTile('Open & Active', '$openCount', Icons.check_circle_outline),
                        Container(height: 24, width: 1, color: Colors.white24),
                        _metricTile('Active Registrations', '${_myParticipants.length}', Icons.group),
                        Container(height: 24, width: 1, color: Colors.white24),
                        _metricTile('Total Capacity', '$totalSlots', Icons.event_seat),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _currentIndex = 1),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View All Events'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      icon: Icons.add_box_outlined,
                      title: 'Publish Event',
                      subtitle: 'Recruit volunteers',
                      color: AppTheme.forestGreen,
                      onTap: _openCreateScreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      icon: Icons.badge_outlined,
                      title: 'View Roster',
                      subtitle: 'Inspect attendance',
                      color: const Color(0xFF1E5B53),
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Activities List
              const Text(
                'Recent Opportunities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),

              if (_myOpportunities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.event_busy, color: Colors.grey, size: 40),
                        const SizedBox(height: 10),
                        const Text('No opportunities posted yet.', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Tap "Publish Event" to start recruiting.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                ..._myOpportunities.take(3).map((opp) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(opp.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text('${opp.date} • ${opp.cause} • ${opp.spotsFilled}/${opp.spotsTotal} Joined'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.paleGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          opp.status.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.forestGreenDark),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      appBar: AppBar(title: const Text('Organization Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.forestGreen,
                      child: Text(
                        _providerProfile.organizationName.isNotEmpty
                            ? _providerProfile.organizationName[0].toUpperCase()
                            : 'O',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _providerProfile.organizationName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    ),
                    Text(
                      _providerProfile.organizationType,
                      style: const TextStyle(fontSize: 13, color: AppTheme.forestGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: AppTheme.forestGreen),
                        title: const Text('Contact Person', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(_providerProfile.contactPerson, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.phone, color: AppTheme.forestGreen),
                        title: const Text('Contact Phone', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(
                          _providerProfile.phone.isNotEmpty ? _providerProfile.phone : 'Not provided',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: AppTheme.forestGreen),
                        title: const Text('Organization Mission', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(
                          _providerProfile.description.isNotEmpty ? _providerProfile.description : 'Community volunteering organizer.',
                          style: const TextStyle(height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _handleLogout,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out of Organizer Account', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
