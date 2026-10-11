import 'package:flutter/material.dart';
import '../data/sample_opportunities.dart';
import '../models/opportunity.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'opportunity_detail_screen.dart';

/// My Activities and Volunteer Hours Tracking screen.
/// Includes strict anti-duplicate completion verification and hours calculation.
class ActivitiesScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Opportunity>? opportunities;
  final VoidCallback onDataChanged;
  final VoidCallback onBrowseOpportunities;

  const ActivitiesScreen({
    super.key,
    required this.userProfile,
    this.opportunities,
    required this.onDataChanged,
    required this.onBrowseOpportunities,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Opportunity> get _joinedOpportunities {
    final list = widget.opportunities ?? sampleOpportunities;
    return list.where((opp) {
      return widget.userProfile.joinedOpportunityIds.contains(opp.id) &&
          !widget.userProfile.isOpportunityCompleted(opp.id);
    }).toList();
  }

  void _markAsCompleted(Opportunity opp) {
    // 1. Anti-duplicate verification check
    if (widget.userProfile.isOpportunityCompleted(opp.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warning: This activity is already marked as completed!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Completed Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm that you have completed ${opp.title}.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.paleGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppTheme.forestGreenDark),
                  const SizedBox(width: 8),
                  Text(
                    '+${opp.hours} Hours to be credited',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forestGreenDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Anti-duplicate protection: The system creates an immutable log record and locks this opportunity to prevent double counting.',
              style: TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);

              // 2. Add verified log
              final newLog = VolunteerLog(
                id: 'log-${DateTime.now().millisecondsSinceEpoch}',
                opportunityId: opp.id,
                title: opp.title,
                cause: opp.cause,
                hours: opp.hours,
                completedDate: DateTime.now().toLocal().toString().split(' ')[0],
              );

              setState(() {
                widget.userProfile.completedLogs.add(newLog);
              });
              widget.onDataChanged();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.forestGreen,
                  content: Text('Success! Credited ${opp.hours} volunteer hours.'),
                ),
              );
            },
            child: const Text('Verify & Credit Hours'),
          ),
        ],
      ),
    );
  }

  void _openDetails(Opportunity opp) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => OpportunityDetailScreen(
          opportunity: opp,
          userProfile: widget.userProfile,
          isSaved: widget.userProfile.savedOpportunityIds.contains(opp.id),
          isJoined: widget.userProfile.joinedOpportunityIds.contains(opp.id),
          isCompleted: widget.userProfile.isOpportunityCompleted(opp.id),
          onToggleBookmark: () {
            setState(() {
              if (widget.userProfile.savedOpportunityIds.contains(opp.id)) {
                widget.userProfile.savedOpportunityIds.remove(opp.id);
              } else {
                widget.userProfile.savedOpportunityIds.add(opp.id);
              }
            });
            widget.onDataChanged();
          },
          onJoin: () {
            setState(() {
              widget.userProfile.joinedOpportunityIds.add(opp.id);
            });
            widget.onDataChanged();
          },
          onLeave: () {
            setState(() {
              widget.userProfile.joinedOpportunityIds.remove(opp.id);
            });
            widget.onDataChanged();
          },
        ),
      ),
    );
  }

  void _confirmLeave(Opportunity opp) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Attendance?'),
        content: Text('Are you sure you want to leave ${opp.title}? Your spot will be released.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay Joined'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                widget.userProfile.joinedOpportunityIds.remove(opp.id);
              });
              widget.onDataChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Left ${opp.title}. Spot released.')),
              );
            },
            child: const Text('Leave Activity'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final joined = _joinedOpportunities;
    final completedLogs = widget.userProfile.completedLogs;
    final totalHours = widget.userProfile.totalCompletedHours;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Impact Dashboard Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.forestGreenDark, AppTheme.forestGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forestGreen.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Verified Impact',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$totalHours',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Hours',
                                  style: TextStyle(
                                    color: AppTheme.paleGreen,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.userProfile.impactLevel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricColumn(
                          'Joined Active',
                          '${joined.length}',
                          Icons.pending_actions,
                        ),
                        Container(height: 24, width: 1, color: Colors.white24),
                        _metricColumn(
                          'Completed',
                          '${completedLogs.length}',
                          Icons.task_alt,
                        ),
                        Container(height: 24, width: 1, color: Colors.white24),
                        _metricColumn(
                          'Bookmarked',
                          '${widget.userProfile.savedOpportunityIds.length}',
                          Icons.bookmark_added,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.forestGreenDark,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.forestGreen,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              tabs: [
                Tab(
                  text: 'Joined & Upcoming (${joined.length})',
                ),
                Tab(
                  text: 'Completed History (${completedLogs.length})',
                ),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Joined & Upcoming
                  joined.isEmpty
                      ? _emptyTab(
                          icon: Icons.event_busy,
                          title: 'No Upcoming Activities',
                          message:
                              'You have not joined any upcoming activities yet. Browse community opportunities and join one to start earning hours.',
                          actionText: 'Browse Opportunities',
                          onAction: widget.onBrowseOpportunities,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: joined.length,
                          itemBuilder: (ctx, i) {
                            final opp = joined[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
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
                                        Text(
                                          '${opp.hours} hrs credit',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: AppTheme.forestGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      opp.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 13,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${opp.date} • ${opp.time}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            opp.location,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => _openDetails(opp),
                                          style: OutlinedButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text('Details'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _confirmLeave(opp),
                                          icon: Icon(Icons.close, size: 14, color: Colors.red.shade700),
                                          label: Text(
                                            'Leave',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        FilledButton.icon(
                                          onPressed: () => _markAsCompleted(opp),
                                          icon: const Icon(Icons.check_circle_outline, size: 16),
                                          label: const Text('Mark Completed'),
                                          style: FilledButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  // Tab 2: Completed History
                  completedLogs.isEmpty
                      ? _emptyTab(
                          icon: Icons.history,
                          title: 'No Completed Activities Yet',
                          message:
                              'Once you complete a joined activity and verify your hours, your certificate logs will appear here without duplicates.',
                          actionText: null,
                          onAction: null,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: completedLogs.length,
                          itemBuilder: (ctx, i) {
                            final log = completedLogs[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.paleGreen,
                                  child: Icon(Icons.verified, color: AppTheme.forestGreen),
                                ),
                                title: Text(
                                  log.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Cause: ${log.cause} • Date: ${log.completedDate}'),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Protected against duplicate counting ✓',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.forestGreenDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.paleGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${log.hours} hrs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.forestGreenDark,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }

  Widget _emptyTab({
    required IconData icon,
    required String title,
    required String message,
    required String? actionText,
    required VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
