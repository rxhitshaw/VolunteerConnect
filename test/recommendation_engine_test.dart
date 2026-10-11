import 'package:flutter_test/flutter_test.dart';
import 'package:volunteer_connect/models/opportunity.dart';
import 'package:volunteer_connect/models/user_profile.dart';
import 'package:volunteer_connect/services/recommendation_engine.dart';

void main() {
  group('RecommendationEngine Scoring Tests', () {
    const opp = Opportunity(
      id: 'opp-1',
      title: 'Community Tree Planting',
      cause: 'Environment',
      location: 'City Green Park',
      date: 'Oct 18, 2026',
      time: '9:00 AM - 12:00 PM',
      dayOfWeek: 'Saturday',
      hours: 3,
      distanceKm: 4,
      spotsTotal: 15,
      spotsFilled: 5,
      description: 'Plant indigenous saplings.',
      requiredSkills: ['Teamwork', 'Gardening'],
      organizer: 'Green Earth Alliance',
    );

    test('Full 100 points when cause, all skills, and availability match', () {
      final user = UserProfile(
        selectedCauses: {'Environment'},
        userSkills: {'Teamwork', 'Gardening'},
        availableDays: {'Saturday'},
      );

      final result = RecommendationEngine.evaluate(opportunity: opp, user: user);

      expect(result.causeScore, 40.0);
      expect(result.skillScore, 30.0);
      expect(result.availabilityScore, 30.0);
      expect(result.totalScore, 100.0);
      expect(result.matchTier, 'Strong Match');
      expect(result.explanations.length, 3);
    });

    test('Partial score when cause matches (40) and day matches (30) but only 1 skill matches (15)', () {
      final user = UserProfile(
        selectedCauses: {'Environment'},
        userSkills: {'Teamwork'}, // Gardening missing
        availableDays: {'Saturday'},
      );

      final result = RecommendationEngine.evaluate(opportunity: opp, user: user);

      expect(result.causeScore, 40.0);
      expect(result.skillScore, 15.0); // 1 out of 2 skills = 50% of 30 = 15
      expect(result.availabilityScore, 30.0);
      expect(result.totalScore, 85.0);
    });

    test('Zero score when none of the criteria match', () {
      final user = UserProfile(
        selectedCauses: {'Animal Welfare'},
        userSkills: {'Coding'},
        availableDays: {'Sunday'},
      );

      final result = RecommendationEngine.evaluate(opportunity: opp, user: user);

      expect(result.causeScore, 0.0);
      expect(result.skillScore, 0.0);
      expect(result.availabilityScore, 0.0);
      expect(result.totalScore, 0.0);
      expect(result.matchTier, 'Alternative Opportunity');
    });
  });
}
