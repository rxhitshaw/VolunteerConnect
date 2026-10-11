import 'package:flutter/material.dart';
import '../../models/provider_profile.dart';
import '../../models/volunteer_registration.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

/// Screen listing all volunteers who have registered for any of the provider's activities.
class ProviderParticipantsScreen extends StatefulWidget {
  final ProviderProfile providerProfile;

  const ProviderParticipantsScreen({
    super.key,
    required this.providerProfile,
  });

  @override
  State<ProviderParticipantsScreen> createState() => _ProviderParticipantsScreenState();
}

class _ProviderParticipantsScreenState extends State<ProviderParticipantsScreen> {
  List<VolunteerRegistration> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final list = await StorageService.getParticipantsForProvider(widget.providerProfile.id);
    if (mounted) {
      setState(() {
        _participants = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.forestGreen));
    }

    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      appBar: AppBar(
        title: const Text('Volunteer Roster'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.forestGreenDark, AppTheme.forestGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 24,
                      child: Icon(Icons.groups, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_participants.length}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Total Active Registrations',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Participant List or Empty State
            Expanded(
              child: _participants.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 14),
                            const Text(
                              'No Volunteers Registered Yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'When community members join your opportunities, their contact details will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _participants.length,
                      itemBuilder: (ctx, i) {
                        final reg = _participants[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.paleGreen,
                              child: Text(
                                reg.volunteerName.isNotEmpty ? reg.volunteerName[0].toUpperCase() : 'V',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.forestGreenDark,
                                ),
                              ),
                            ),
                            title: Text(
                              reg.volunteerName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  'Event: ${reg.opportunityTitle}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Email: ${reg.volunteerEmail} • Date: ${reg.registeredAt}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.paleGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reg.status.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.forestGreenDark,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
