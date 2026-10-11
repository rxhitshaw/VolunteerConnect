import 'package:flutter/material.dart';
import '../../models/opportunity.dart';
import '../../models/provider_profile.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'create_opportunity_screen.dart';

/// Screen allowing Opportunity Providers to inspect, edit, delete,
/// and update statuses of their published volunteering events.
class ProviderOpportunitiesScreen extends StatefulWidget {
  final ProviderProfile providerProfile;
  final VoidCallback onDataChanged;

  const ProviderOpportunitiesScreen({
    super.key,
    required this.providerProfile,
    required this.onDataChanged,
  });

  @override
  State<ProviderOpportunitiesScreen> createState() => _ProviderOpportunitiesScreenState();
}

class _ProviderOpportunitiesScreenState extends State<ProviderOpportunitiesScreen> {
  List<Opportunity> _myOpportunities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await StorageService.loadOpportunities();
    final mine = all.where((o) => o.providerId == widget.providerProfile.id).toList();
    if (mounted) {
      setState(() {
        _myOpportunities = mine;
        _isLoading = false;
      });
    }
  }

  void _openCreateOrEdit([Opportunity? existing]) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => CreateOpportunityScreen(
          providerProfile: widget.providerProfile,
          existingOpportunity: existing,
          onOpportunitySaved: () {
            _loadData();
            widget.onDataChanged();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Opportunity opp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Opportunity?'),
        content: Text(
          'Are you sure you want to permanently delete "${opp.title}"? This action will remove it from the volunteer feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteOpportunity(opp.id, widget.providerProfile.id);
      _loadData();
      widget.onDataChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${opp.title}".')),
        );
      }
    }
  }

  Future<void> _changeStatus(Opportunity opp, String newStatus) async {
    await StorageService.setOpportunityStatus(opp.id, newStatus, widget.providerProfile.id);
    _loadData();
    widget.onDataChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.forestGreen,
          content: Text('Status of "${opp.title}" set to $newStatus.'),
        ),
      );
    }
  }

  void _viewParticipants(Opportunity opp) async {
    final participants = await StorageService.getParticipantsForOpportunity(opp.id);
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.people, color: AppTheme.forestGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registered Volunteers (${participants.length}/${opp.spotsTotal})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            Text(
              opp.title,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
            ),
            const Divider(height: 24),
            if (participants.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No volunteers have registered for this opportunity yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  separatorBuilder: (context, index) => const Divider(height: 12),
                  itemBuilder: (ctx, idx) {
                    final p = participants[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.paleGreen,
                        child: Text(
                          p.volunteerName.isNotEmpty ? p.volunteerName[0].toUpperCase() : 'V',
                          style: const TextStyle(color: AppTheme.forestGreenDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(p.volunteerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text('${p.volunteerEmail} • Registered ${p.registeredAt}', style: const TextStyle(fontSize: 11)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.paleGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Confirmed',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.forestGreenDark),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.forestGreen));
    }

    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      appBar: AppBar(
        title: const Text('My Opportunities'),
        actions: [
          IconButton(
            tooltip: 'Create Opportunity',
            icon: const Icon(Icons.add_circle, color: AppTheme.forestGreen, size: 28),
            onPressed: () => _openCreateOrEdit(),
          ),
        ],
      ),
      body: _myOpportunities.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No Opportunities Created Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Publish volunteering events to recruit helpers from the community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openCreateOrEdit(),
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.forestGreen),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Opportunity'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myOpportunities.length,
              itemBuilder: (ctx, i) {
                final opp = _myOpportunities[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cause & Status badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.paleGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                opp.cause,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.forestGreenDark,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Status Dropdown
                            DropdownButton<String>(
                              value: opp.status,
                              underline: const SizedBox(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              items: const [
                                DropdownMenuItem(value: 'open', child: Text('Status: Open', style: TextStyle(color: Colors.green))),
                                DropdownMenuItem(value: 'full', child: Text('Status: Full', style: TextStyle(color: Colors.orange))),
                                DropdownMenuItem(value: 'completed', child: Text('Status: Completed', style: TextStyle(color: Colors.grey))),
                              ],
                              onChanged: (val) {
                                if (val != null) _changeStatus(opp, val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Text(
                          opp.title,
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          '${opp.date} • ${opp.time} • ${opp.location}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 12),

                        // Capacity & Registered Volunteers Strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people_outline, size: 16, color: AppTheme.forestGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${opp.spotsFilled}/${opp.spotsTotal} Joined',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Text(
                                '${opp.spotsRemaining} spots left',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: opp.spotsRemaining > 0 ? AppTheme.forestGreenDark : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _viewParticipants(opp),
                              icon: const Icon(Icons.group, size: 16),
                              label: const Text('Participants', style: TextStyle(fontSize: 12)),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Edit Opportunity',
                              icon: const Icon(Icons.edit, size: 20, color: AppTheme.forestGreen),
                              onPressed: () => _openCreateOrEdit(opp),
                            ),
                            IconButton(
                              tooltip: 'Delete Opportunity',
                              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                              onPressed: () => _confirmDelete(opp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
