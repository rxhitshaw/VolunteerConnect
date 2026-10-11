import 'package:flutter/material.dart';
import '../data/sample_opportunities.dart';
import '../models/opportunity.dart';
import '../models/recommendation_result.dart';
import '../models/user_profile.dart';
import '../services/recommendation_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/opportunity_card.dart';
import 'opportunity_detail_screen.dart';

/// "For You" screen showing opportunities ranked by the transparent
/// 40/30/30 rule-based recommendation engine, with reasons explaining each score.
class RecommendationsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Opportunity>? opportunities;
  final VoidCallback onDataChanged;
  final VoidCallback onGoToProfile;

  const RecommendationsScreen({
    super.key,
    required this.userProfile,
    this.opportunities,
    required this.onDataChanged,
    required this.onGoToProfile,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
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
          onToggleBookmark: () => _toggleBookmark(opp.id),
          onJoin: () => _joinOpportunity(opp.id),
          onLeave: () => _leaveOpportunity(opp.id),
        ),
      ),
    );
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (widget.userProfile.savedOpportunityIds.contains(id)) {
        widget.userProfile.savedOpportunityIds.remove(id);
      } else {
        widget.userProfile.savedOpportunityIds.add(id);
      }
    });
    widget.onDataChanged();
  }

  void _joinOpportunity(String id) {
    setState(() {
      widget.userProfile.joinedOpportunityIds.add(id);
    });
    widget.onDataChanged();
  }

  void _leaveOpportunity(String id) {
    setState(() {
      widget.userProfile.joinedOpportunityIds.remove(id);
    });
    widget.onDataChanged();
  }

  void _showScoreExplainer(RecommendationResult rec) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
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
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.forestGreen, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Recommendation Logic',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forestGreenDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.paleGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${rec.totalScore.toInt()}/100 pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreenDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rec.opportunity.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'How points were allocated:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _scorePill(
              'Causes (Max 40 pts)',
              '${rec.causeScore.toInt()} pts',
              rec.causeMatched,
              'Matches selected cause: ${rec.opportunity.cause}',
            ),
            const SizedBox(height: 8),
            _scorePill(
              'Matching Skills (Max 30 pts)',
              '${rec.skillScore.toInt()} pts',
              rec.skillScore > 0,
              rec.matchedSkills.isEmpty
                  ? 'No matching skills'
                  : 'Skills: ${rec.matchedSkills.join(", ")}',
            ),
            const SizedBox(height: 8),
            _scorePill(
              'Availability (Max 30 pts)',
              '${rec.availabilityScore.toInt()} pts',
              rec.availabilityMatched,
              'Takes place on ${rec.opportunity.dayOfWeek}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Note: This is a 100% transparent, deterministic, rule-based recommendation algorithm without black-box predictive models.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scorePill(String title, String points, bool isPositive, String detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive ? AppTheme.paleGreen.withAlpha(90) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPositive ? AppTheme.mintAccent : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle : Icons.remove_circle_outline,
            size: 18,
            color: isPositive ? AppTheme.forestGreen : Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isPositive ? AppTheme.forestGreenDark : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankedResults = RecommendationEngine.rank(
      opportunities: widget.opportunities ?? sampleOpportunities,
      user: widget.userProfile,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.forestGreenDark, size: 26),
                      const SizedBox(width: 8),
                      const Text(
                        'Matched For You',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestGreenDark,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: widget.onGoToProfile,
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Edit Criteria', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ranked by transparent 40/30/30 rule scoring. Tap any card to review why it was recommended.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 10),

                  // Active Criteria Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _criteriaChip(
                          'Causes (${widget.userProfile.selectedCauses.length})',
                          widget.userProfile.selectedCauses.join(', '),
                        ),
                        const SizedBox(width: 6),
                        _criteriaChip(
                          'Skills (${widget.userProfile.userSkills.length})',
                          widget.userProfile.userSkills.take(3).join(', '),
                        ),
                        const SizedBox(width: 6),
                        _criteriaChip(
                          'Days',
                          widget.userProfile.availableDays.join(', '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 12),

            // Ranked List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                itemCount: rankedResults.length,
                itemBuilder: (ctx, i) {
                  final rec = rankedResults[i];
                  return Column(
                    children: [
                      // Rank indicator badge above the card
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppTheme.forestGreenDark
                                    : Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${i + 1} Best Match',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _showScoreExplainer(rec),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${rec.totalScore.toInt()}% match breakdown',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.forestGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: AppTheme.forestGreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      OpportunityCard(
                        opportunity: rec.opportunity,
                        recommendation: rec,
                        isSaved: widget.userProfile.savedOpportunityIds.contains(rec.opportunity.id),
                        isJoined: widget.userProfile.joinedOpportunityIds.contains(rec.opportunity.id),
                        isCompleted: widget.userProfile.isOpportunityCompleted(rec.opportunity.id),
                        onTap: () => _openDetails(rec.opportunity),
                        onToggleBookmark: () => _toggleBookmark(rec.opportunity.id),
                        onJoin: () => _joinOpportunity(rec.opportunity.id),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criteriaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value, style: const TextStyle(color: AppTheme.forestGreenDark)),
          ],
        ),
      ),
    );
  }
}
