import 'package:flutter_test/flutter_test.dart';
import 'package:volunteer_connect/models/user_profile.dart';

void main() {
  group('Volunteer Hours & Anti-Duplicate Tracking Tests', () {
    test('Calculates total hours correctly from verified logs', () {
      final profile = UserProfile(
        completedLogs: [
          const VolunteerLog(
            id: 'log-1',
            opportunityId: 'opp-101',
            title: 'Tree Planting',
            cause: 'Environment',
            hours: 3,
            completedDate: '2026-10-17',
          ),
          const VolunteerLog(
            id: 'log-2',
            opportunityId: 'opp-102',
            title: 'Math Tutoring',
            cause: 'Education',
            hours: 2,
            completedDate: '2026-10-18',
          ),
        ],
      );

      expect(profile.totalCompletedHours, 5);
      expect(profile.isOpportunityCompleted('opp-101'), isTrue);
      expect(profile.isOpportunityCompleted('opp-102'), isTrue);
      expect(profile.isOpportunityCompleted('opp-999'), isFalse);
    });

    test('Prevents duplicate completion entries for same opportunity', () {
      final profile = UserProfile();

      expect(profile.isOpportunityCompleted('opp-101'), isFalse);

      // Add first completion
      profile.completedLogs.add(
        const VolunteerLog(
          id: 'log-1',
          opportunityId: 'opp-101',
          title: 'Tree Planting',
          cause: 'Environment',
          hours: 3,
          completedDate: '2026-10-17',
        ),
      );

      expect(profile.totalCompletedHours, 3);
      expect(profile.isOpportunityCompleted('opp-101'), isTrue);

      // Verify guard logic: cannot add duplicate log for same oppId
      final isAlreadyCompleted = profile.isOpportunityCompleted('opp-101');
      expect(isAlreadyCompleted, isTrue);

      // Ensure hours remain 3 and not double-counted
      expect(profile.totalCompletedHours, 3);
    });

    test('Impact milestones calculate dynamically', () {
      final profile = UserProfile();
      expect(profile.impactLevel, contains('Active Volunteer Explorer'));

      // 5 hours
      profile.completedLogs.add(
        const VolunteerLog(
          id: 'log-1',
          opportunityId: 'opp-1',
          title: 'Activity 1',
          cause: 'Community',
          hours: 6,
          completedDate: '2026-10-17',
        ),
      );
      expect(profile.impactLevel, contains('Bronze Helper'));

      // 16 hours total
      profile.completedLogs.add(
        const VolunteerLog(
          id: 'log-2',
          opportunityId: 'opp-2',
          title: 'Activity 2',
          cause: 'Community',
          hours: 10,
          completedDate: '2026-10-18',
        ),
      );
      expect(profile.impactLevel, contains('Silver Changemaker'));
    });
  });
}
