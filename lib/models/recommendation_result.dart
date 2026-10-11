import 'opportunity.dart';

/// Represents the transparent score evaluation and rationale for an opportunity.
/// Strictly follows competition scoring rubric:
/// - Causes match: 40 points
/// - Matching skills: 30 points
/// - Availability match: 30 points
/// Total: 100 points
class RecommendationResult {
  final Opportunity opportunity;
  final double totalScore;
  final double causeScore; // max 40
  final double skillScore; // max 30
  final double availabilityScore; // max 30
  final List<String> explanations;
  final List<String> matchedSkills;
  final bool causeMatched;
  final bool availabilityMatched;

  const RecommendationResult({
    required this.opportunity,
    required this.totalScore,
    required this.causeScore,
    required this.skillScore,
    required this.availabilityScore,
    required this.explanations,
    required this.matchedSkills,
    required this.causeMatched,
    required this.availabilityMatched,
  });

  /// High match tier (>= 70), Moderate (>= 40), Low (< 40)
  String get matchTier {
    if (totalScore >= 70) return 'Strong Match';
    if (totalScore >= 40) return 'Moderate Match';
    return 'Alternative Opportunity';
  }
}
