import 'package:flutter_test/flutter_test.dart';

import 'package:apex_lifter_mobile/models/models.dart';

void main() {
  group('Model parsing', () {
    test('User.fromJson parses full payload', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Budi',
        'email': 'budi@test.com',
        'gender': 'male',
        'birth_date': '2000-05-01',
        'age': 26,
        'age_bracket': '18-29',
        'body_weight_kg': 72,
        'weight_class': '60-74',
      });

      expect(user.name, 'Budi');
      expect(user.bodyWeightKg, 72.0);
      expect(user.ageBracket, '18-29');
    });

    test('LeaderboardEntry.fromJson handles numeric strings', () {
      final entry = LeaderboardEntry.fromJson({
        'rank': 1,
        'user_id': 2,
        'user_name': 'Andi',
        'value': '126.67',
        'weight_kg': 100,
        'reps': 8,
        'performed_at': '2026-07-14T09:13:36+00:00',
      });

      expect(entry.value, 126.67);
      expect(entry.weightKg, 100.0);
    });
  });
}
