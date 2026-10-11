import 'package:flutter/material.dart';
import '../models/opportunity.dart';
import '../models/recommendation_result.dart';
import '../models/user_profile.dart';
import '../services/recommendation_engine.dart';
import '../theme/app_theme.dart';

/// Full screen displaying in-depth opportunity details, skill requirements,
/// transparent recommendation analysis, and action controls.
class OpportunityDetailScreen extends StatefulWidget {
  final Opportunity opportunity;
  final UserProfile userProfile;
  final bool isSaved;
  final bool isJoined;
  final bool isCompleted;
  final VoidCallback onToggleBookmark;
  final VoidCallback onJoin;

  const OpportunityDetailScreen({
    super.key,
    required this.opportunity,
    required this.userProfile,
    required this.isSaved,
    required this.isJoined,
    required this.isCompleted,
    required this.onToggleBookmark,
    required this.onJoin,
  });

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  late bool _saved;
  late bool _joined;
  late RecommendationResult _recommendation;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _joined = widget.isJoined;
    _recommendation = RecommendationEngine.evaluate(
      opportunity: widget.opportunity,
      user: widget.userProfile,
    );
  }

  void _handleBookmark() {
    setState(() {
      _saved = !_saved;
    });
    widget.onToggleBookmark();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_saved ? 'Saved to bookmarks' : 'Removed from bookmarks'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmJoin() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to commit to ${widget.opportunity.title}?'),
            const SizedBox(height: 10),
            Text(
              'Date: ${widget.opportunity.date} (${widget.opportunity.time})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('Estimated duration: ${widget.opportunity.hours} volunteer hours'),
            const SizedBox(height: 8),
            const Text(
              'Note: Please only commit if you are able to attend to preserve spots for fellow volunteers.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
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
              setState(() {
                _joined = true;
              });
              widget.onJoin();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.forestGreen,
                  content: Text('Successfully joined ${widget.opportunity.title}!'),
                ),
              );
            },
            child: const Text('Confirm & Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opp = widget.opportunity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunity Details'),
        actions: [
          IconButton(
            tooltip: _saved ? 'Remove Bookmark' : 'Add Bookmark',
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              color: _saved ? AppTheme.forestGreen : AppTheme.forestGreenDark,
            ),
            onPressed: _handleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cause tag & spots left
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.paleGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    opp.cause,
                    style: const TextStyle(
                      color: AppTheme.forestGreenDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '${opp.spotsRemaining} spots available',
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              opp.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.forestGreenDark,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),

            // Organizer
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Organized by ${opp.organizer}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Key details highlight card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.calendar_month,
                      'Date & Time',
                      '${opp.date}\n${opp.time} (${opp.dayOfWeek})',
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      Icons.timer_outlined,
                      'Duration',
                      '${opp.hours} volunteer hours towards your community impact',
                    ),
                    const Divider(height: 20),
                    _detailRow(
                      Icons.place,
                      'Location',
                      '${opp.location}\nApprox. ${opp.distanceKm} km from your registered area',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Transparent Rule-based Match Engine Breakdown
            Card(
              color: AppTheme.paleGreen.withAlpha(80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.mintAccent),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppTheme.forestGreenDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Match Score: ${_recommendation.totalScore.toInt()}/100 pts',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forestGreenDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.forestGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _recommendation.matchTier,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Deterministic Algorithm Breakdown (40 causes + 30 skills + 30 availability):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._recommendation.explanations.map((exp) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          exp,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: exp.startsWith('✓')
                                ? AppTheme.forestGreenDark
                                : AppTheme.textDark,
                            fontWeight: exp.startsWith('✓')
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'About This Opportunity',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              opp.description,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),

            // Skills Prerequisite
            const Text(
              'Required Skills',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: opp.requiredSkills.map((skill) {
                final isMatched = widget.userProfile.userSkills
                    .any((s) => s.toLowerCase() == skill.toLowerCase());
                return Chip(
                  avatar: Icon(
                    isMatched ? Icons.check_circle : Icons.handyman_outlined,
                    size: 16,
                    color: isMatched ? AppTheme.forestGreen : Colors.grey.shade600,
                  ),
                  label: Text(
                    isMatched ? '$skill (In your profile)' : skill,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isMatched ? FontWeight.w700 : FontWeight.w500,
                      color: isMatched ? AppTheme.forestGreenDark : AppTheme.textDark,
                    ),
                  ),
                  backgroundColor: isMatched ? AppTheme.paleGreen : Colors.grey.shade100,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Sample Notice Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.brown),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sample Opportunity Notice: This activity is simulated demo data designed for hackathon evaluation. No real external location services or unverified attendees are claimed.',
                      style: TextStyle(fontSize: 11.5, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _handleBookmark,
                icon: Icon(
                  _saved ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                ),
                label: Text(_saved ? 'Saved' : 'Save'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: widget.isCompleted
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                        ),
                        onPressed: null,
                        icon: const Icon(Icons.verified),
                        label: const Text('Activity Completed'),
                      )
                    : _joined
                        ? FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                            ),
                            onPressed: null,
                            icon: const Icon(Icons.check),
                            label: const Text('You Have Joined'),
                          )
                        : FilledButton.icon(
                            onPressed: _confirmJoin,
                            icon: const Icon(Icons.group_add),
                            label: const Text('Join Activity'),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.paleGreen.withAlpha(100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.forestGreenDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
