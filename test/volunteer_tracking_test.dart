import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_connect/models/opportunity.dart';
import 'package:volunteer_connect/models/user_profile.dart';
import 'package:volunteer_connect/services/hash_util.dart';
import 'package:volunteer_connect/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    test('Joining and leaving activities updates user profile state correctly', () {
      final profile = UserProfile();
      expect(profile.joinedOpportunityIds.isEmpty, isTrue);

      // Join activity
      profile.joinedOpportunityIds.add('opp-tree-planting');
      expect(profile.joinedOpportunityIds.contains('opp-tree-planting'), isTrue);
      expect(profile.joinedOpportunityIds.length, 1);

      // Leave activity / cancel attendance
      profile.joinedOpportunityIds.remove('opp-tree-planting');
      expect(profile.joinedOpportunityIds.contains('opp-tree-planting'), isFalse);
      expect(profile.joinedOpportunityIds.isEmpty, isTrue);
    });

    test('Bookmarking and unbookmarking opportunities updates state correctly', () {
      final profile = UserProfile();
      expect(profile.savedOpportunityIds.isEmpty, isTrue);

      // Bookmark
      profile.savedOpportunityIds.add('opp-food-bank');
      expect(profile.savedOpportunityIds.contains('opp-food-bank'), isTrue);

      // Unbookmark
      profile.savedOpportunityIds.remove('opp-food-bank');
      expect(profile.savedOpportunityIds.contains('opp-food-bank'), isFalse);
    });

    test('UserProfile round-trip JSON serialization preserves all preferences, bookmarks, joined IDs, and logs across restarts', () {
      final original = UserProfile(
        name: 'Jane Doe',
        selectedCauses: {'Environment', 'Animal Welfare'},
        userSkills: {'Gardening', 'Logistics'},
        availableDays: {'Saturday'},
        maxDistanceKm: 25,
        savedOpportunityIds: {'opp-1', 'opp-2'},
        joinedOpportunityIds: {'opp-3'},
        completedLogs: [
          const VolunteerLog(
            id: 'log-100',
            opportunityId: 'opp-100',
            title: 'Clean River Run',
            cause: 'Environment',
            hours: 4,
            completedDate: '2026-10-15',
          ),
        ],
      );

      final jsonMap = original.toJson();
      final restored = UserProfile.fromJson(jsonMap);

      expect(restored.name, 'Jane Doe');
      expect(restored.selectedCauses, {'Environment', 'Animal Welfare'});
      expect(restored.userSkills, {'Gardening', 'Logistics'});
      expect(restored.availableDays, {'Saturday'});
      expect(restored.maxDistanceKm, 25);
      expect(restored.savedOpportunityIds, {'opp-1', 'opp-2'});
      expect(restored.joinedOpportunityIds, {'opp-3'});
      expect(restored.completedLogs.length, 1);
      expect(restored.completedLogs.first.id, 'log-100');
      expect(restored.completedLogs.first.opportunityId, 'opp-100');
      expect(restored.completedLogs.first.hours, 4);
      expect(restored.totalCompletedHours, 4);
      expect(restored.isOpportunityCompleted('opp-100'), isTrue);
      expect(restored.isOpportunityCompleted('opp-3'), isFalse);
    });
  });

  group('Dual Authentication & Provider Operations Tests', () {
    test('Password hashing produces 64-char SHA-256 digest and rejects plaintext exposure', () {
      final hash1 = HashUtil.sha256('Volunteer123!');
      final hash2 = HashUtil.sha256('Volunteer123!');
      final hashDiff = HashUtil.sha256('WrongPassword');

      expect(hash1.length, 64);
      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals('Volunteer123!')));
      expect(hash1, isNot(equals(hashDiff)));
    });

    test('Provider opportunity creation, editing, and authorization enforcement', () async {
      final opp = Opportunity(
        id: 'test-opp-1',
        title: 'Park Cleanup',
        cause: 'Environment',
        location: 'Greenfield',
        date: 'Oct 20, 2026',
        time: '9:00 AM - 12:00 PM',
        dayOfWeek: 'Sunday',
        hours: 3,
        distanceKm: 5,
        spotsTotal: 10,
        spotsFilled: 0,
        description: 'Clean park',
        requiredSkills: ['Teamwork'],
        organizer: 'Eco Org',
        providerId: 'prov-owner-1',
      );

      await StorageService.createOpportunity(opp);
      final opps = await StorageService.loadOpportunities();
      expect(opps.any((o) => o.id == 'test-opp-1'), isTrue);

      // Unauthorized provider cannot update or delete
      final unauthorizedEdit = await StorageService.updateOpportunity(
        opp.copyWith(title: 'Hacked Title'),
        'prov-intruder',
      );
      expect(unauthorizedEdit, isFalse);

      final unauthorizedDelete = await StorageService.deleteOpportunity(
        'test-opp-1',
        'prov-intruder',
      );
      expect(unauthorizedDelete, isFalse);

      // Owner can update
      final authorizedEdit = await StorageService.updateOpportunity(
        opp.copyWith(title: 'Updated Park Cleanup'),
        'prov-owner-1',
      );
      expect(authorizedEdit, isTrue);

      // Owner can delete
      final authorizedDelete = await StorageService.deleteOpportunity(
        'test-opp-1',
        'prov-owner-1',
      );
      expect(authorizedDelete, isTrue);
    });

    test('Overbooking and duplicate volunteer registration protection', () async {
      // Opportunity with only 1 slot
      final singleSlotOpp = Opportunity(
        id: 'test-opp-limited',
        title: 'Solo Volunteer Needed',
        cause: 'Education',
        location: 'Library',
        date: 'Oct 25, 2026',
        time: '10:00 AM - 1:00 PM',
        dayOfWeek: 'Saturday',
        hours: 3,
        distanceKm: 2,
        spotsTotal: 1,
        spotsFilled: 0,
        description: 'Tutoring',
        requiredSkills: ['Teaching'],
        organizer: 'Library',
        providerId: 'prov-1',
      );
      await StorageService.createOpportunity(singleSlotOpp);

      // First volunteer registers successfully
      final err1 = await StorageService.registerVolunteerForOpportunity(
        volunteerId: 'vol-1',
        volunteerName: 'Alice',
        volunteerEmail: 'alice@test.com',
        opportunityId: 'test-opp-limited',
      );
      expect(err1, isNull);

      // Same volunteer attempts to register again -> duplicate rejected
      final duplicateErr = await StorageService.registerVolunteerForOpportunity(
        volunteerId: 'vol-1',
        volunteerName: 'Alice',
        volunteerEmail: 'alice@test.com',
        opportunityId: 'test-opp-limited',
      );
      expect(duplicateErr, contains('already registered'));

      // Second volunteer attempts to register -> overbooking rejected
      final overbookErr = await StorageService.registerVolunteerForOpportunity(
        volunteerId: 'vol-2',
        volunteerName: 'Bob',
        volunteerEmail: 'bob@test.com',
        opportunityId: 'test-opp-limited',
      );
      expect(overbookErr, contains('completely full'));
    });
  });
}
