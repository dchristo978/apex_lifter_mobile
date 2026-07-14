double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.parse(v.toString());

double? _toDoubleOrNull(dynamic v) => v == null ? null : _toDouble(v);

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    this.gender,
    this.birthDate,
    this.age,
    this.ageBracket,
    this.bodyWeightKg,
    this.weightClass,
  });

  final int id;
  final String name;
  final String email;
  final String? gender;
  final String? birthDate;
  final int? age;
  final String? ageBracket;
  final double? bodyWeightKg;
  final String? weightClass;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        gender: json['gender'] as String?,
        birthDate: json['birth_date'] as String?,
        age: json['age'] as int?,
        ageBracket: json['age_bracket'] as String?,
        bodyWeightKg: _toDoubleOrNull(json['body_weight_kg']),
        weightClass: json['weight_class'] as String?,
      );
}

class Gym {
  Gym({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  factory Gym.fromJson(Map<String, dynamic> json) => Gym(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
      );
}

class Machine {
  Machine({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.description,
  });

  final int id;
  final String name;
  final String brand;
  final String category;
  final String? description;

  factory Machine.fromJson(Map<String, dynamic> json) => Machine(
        id: json['id'] as int,
        name: json['name'] as String,
        brand: json['brand'] as String,
        category: json['category'] as String,
        description: json['description'] as String?,
      );
}

class WorkoutSet {
  WorkoutSet({
    required this.id,
    required this.weightKg,
    required this.reps,
    required this.estimated1rm,
    required this.performedAt,
    this.machineName,
  });

  final int id;
  final double weightKg;
  final int reps;
  final double estimated1rm;
  final DateTime performedAt;
  final String? machineName;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        id: json['id'] as int,
        weightKg: _toDouble(json['weight_kg']),
        reps: json['reps'] as int,
        estimated1rm: _toDouble(json['estimated_1rm']),
        performedAt: DateTime.parse(json['performed_at'] as String).toLocal(),
        machineName: (json['machine'] as Map<String, dynamic>?)?['name'] as String?,
      );
}

class LeaderboardEntry {
  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.value,
    required this.weightKg,
    required this.reps,
    required this.performedAt,
  });

  final int rank;
  final int userId;
  final String userName;
  final double value;
  final double weightKg;
  final int reps;
  final DateTime performedAt;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int,
        userId: json['user_id'] as int,
        userName: json['user_name'] as String,
        value: _toDouble(json['value']),
        weightKg: _toDouble(json['weight_kg']),
        reps: json['reps'] as int,
        performedAt: DateTime.parse(json['performed_at'] as String).toLocal(),
      );
}

class RankNotification {
  RankNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  factory RankNotification.fromJson(Map<String, dynamic> json) =>
      RankNotification(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String).toLocal(),
      );
}

class CheckinResult {
  CheckinResult({required this.gym, required this.distanceM});

  final Gym gym;
  final int distanceM;
}
