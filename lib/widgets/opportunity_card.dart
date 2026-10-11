import 'package:flutter/material.dart';
import '../models/opportunity.dart';
import '../models/recommendation_result.dart';
import '../theme/app_theme.dart';

/// Reusable card displaying an opportunity in lists.
class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final RecommendationResult? recommendation;
  final bool isSaved;
  final bool isJoined;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onToggleBookmark;
  final VoidCallback onJoin;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    this.recommendation,
    required this.isSaved,
    required this.isJoined,
    required this.isCompleted,
    required this.onTap,
    required this.onToggleBookmark,
    required this.onJoin,
  });

  IconData _iconForCause(String cause) {
    switch (cause) {
      case 'Environment':
        return Icons.eco;
      case 'Education':
        return Icons.school;
      case 'Animal Welfare':
        return Icons.pets;
      case 'Healthcare':
        return Icons.favorite;
      case 'Community':
      default:
        return Icons.volunteer_activism;
    }
  }

  Color _colorForCause(String cause) {
    switch (cause) {
      case 'Environment':
        return const Color(0xFF2D6A4F);
      case 'Education':
        return const Color(0xFF1D4ED8);
      case 'Animal Welfare':
        return const Color(0xFFB45309);
      case 'Healthcare':
        return const Color(0xFFBE123C);
      case 'Community':
      default:
        return const Color(0xFF0F766E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final causeColor = _colorForCause(opportunity.cause);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Cause chip, spots badge, and bookmark icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: causeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconForCause(opportunity.cause), size: 14, color: causeColor),
                        const SizedBox(width: 5),
                        Text(
                          opportunity.cause,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: causeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.paleGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${opportunity.spotsRemaining} spots left',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.forestGreenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: isSaved ? 'Remove bookmark' : 'Bookmark opportunity',
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? AppTheme.forestGreen : Colors.grey.shade600,
                    ),
                    onPressed: onToggleBookmark,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                opportunity.title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),

              // Date, time, duration, and location row
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    opportunity.date,
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    '${opportunity.hours} hrs',
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${opportunity.location} • ${opportunity.distanceKm} km away',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Recommendation Score Banner (if provided)
              if (recommendation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.paleGreen.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.mintAccent.withAlpha(100)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 16, color: AppTheme.forestGreenDark),
                          const SizedBox(width: 6),
                          Text(
                            'Match: ${recommendation!.totalScore.toInt()}/100 pts (${recommendation!.matchTier})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.forestGreenDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation!.explanations.first,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Skills & Action Row
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: opportunity.requiredSkills.take(2).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.paleGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppTheme.forestGreen),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available, size: 14, color: Colors.blue.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'Joined',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onJoin,
                      child: const Text('Join', style: TextStyle(fontSize: 12.5)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
