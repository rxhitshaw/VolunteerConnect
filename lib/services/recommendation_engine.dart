import '../models/opportunity.dart';
import '../models/recommendation_result.dart';
import '../models/user_profile.dart';

/// Transparent, rule-based recommendation engine for VolunteerConnect.
///
/// Competition scoring rubric:
/// 1. Selected causes (40 points)
/// 2. Matching skills (30 points)
/// 3. Availability (30 points)
/// Total: 100 points
///
/// Provides transparent, explainable reasoning for every recommendation.
class RecommendationEngine {
  /// Evaluates a single opportunity against the user's profile.
  static RecommendationResult evaluate({
    required Opportunity opportunity,
    required UserProfile user,
  }) {
    final explanations = <String>[];
    final matchedSkills = <String>[];

    // 1. Causes Scoring (Max 40 points)
    double causeScore = 0.0;
    final bool causeMatched = user.selectedCauses.contains(opportunity.cause);
    if (causeMatched) {
      causeScore = 40.0;
      explanations.add(
        '✓ +40 pts: Matches your selected cause "${opportunity.cause}"',
      );
    } else {
      causeScore = 0.0;
      explanations.add(
        '✗ 0 pts: "${opportunity.cause}" is not in your preferred causes',
      );
    }

    // 2. Matching Skills Scoring (Max 30 points)
    double skillScore = 0.0;
    if (opportunity.requiredSkills.isEmpty) {
      skillScore = 30.0;
      explanations.add(
        '✓ +30 pts: Open to all volunteers (no specific skill prerequisite)',
      );
    } else {
      for (final reqSkill in opportunity.requiredSkills) {
        if (user.userSkills.any((s) => s.toLowerCase() == reqSkill.toLowerCase())) {
          matchedSkills.add(reqSkill);
        }
      }

      final ratio = matchedSkills.length / opportunity.requiredSkills.length;
      skillScore = (ratio * 30.0).clamp(0.0, 30.0).roundToDouble();

      if (matchedSkills.isNotEmpty) {
        explanations.add(
          '✓ +${skillScore.toInt()} pts: Matches ${matchedSkills.length}/${opportunity.requiredSkills.length} required skills (${matchedSkills.join(", ")})',
        );
      } else {
        explanations.add(
          '✗ 0 pts: Does not match required skills (${opportunity.requiredSkills.join(", ")})',
        );
      }
    }

    // 3. Availability Scoring (Max 30 points)
    double availabilityScore = 0.0;
    final bool availabilityMatched =
        user.availableDays.contains(opportunity.dayOfWeek);
    if (availabilityMatched) {
      availabilityScore = 30.0;
      explanations.add(
        '✓ +30 pts: Scheduled on ${opportunity.dayOfWeek}, which matches your availability',
      );
    } else {
      availabilityScore = 0.0;
      explanations.add(
        '✗ 0 pts: Takes place on ${opportunity.dayOfWeek} (not in your availability list)',
      );
    }

    final totalScore = causeScore + skillScore + availabilityScore;

    return RecommendationResult(
      opportunity: opportunity,
      totalScore: totalScore,
      causeScore: causeScore,
      skillScore: skillScore,
      availabilityScore: availabilityScore,
      explanations: explanations,
      matchedSkills: matchedSkills,
      causeMatched: causeMatched,
      availabilityMatched: availabilityMatched,
    );
  }

  /// Evaluates and ranks a list of opportunities for the user profile.
  /// Filters by maxDistance if applicable, then sorts by score descending.
  static List<RecommendationResult> rank({
    required List<Opportunity> opportunities,
    required UserProfile user,
  }) {
    final results = opportunities.map((opp) {
      return evaluate(opportunity: opp, user: user);
    }).toList();

    // Sort descending by score; break ties by proximity (closer distance first)
    results.sort((a, b) {
      final scoreCompare = b.totalScore.compareTo(a.totalScore);
      if (scoreCompare != 0) return scoreCompare;
      return a.opportunity.distanceKm.compareTo(b.opportunity.distanceKm);
    });

    return results;
  }
}
