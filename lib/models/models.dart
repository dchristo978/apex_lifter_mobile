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
    this.bodyWeightUpdatedAt,
    this.bodyWeightStale = false,
    this.avatarUrl,
    this.featuredMachineIds = const [],
    this.weekStreak = 0,
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
  final DateTime? bodyWeightUpdatedAt;
  final bool bodyWeightStale;
  final String? avatarUrl;

  /// Up to 3 machine ids the user pins to the top of their public profile.
  final List<int> featuredMachineIds;

  /// Consecutive weeks (Mon–Sun) with at least one gym session. See the
  /// backend's `User::weekStreak()`.
  final int weekStreak;

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
        bodyWeightUpdatedAt: json['body_weight_updated_at'] == null
            ? null
            : DateTime.parse(json['body_weight_updated_at'] as String).toLocal(),
        bodyWeightStale: json['body_weight_stale'] as bool? ?? false,
        avatarUrl: json['avatar_url'] as String?,
        featuredMachineIds: ((json['featured_machine_ids'] as List?) ?? const [])
            .map((e) => e as int)
            .toList(),
        weekStreak: json['week_streak'] as int? ?? 0,
      );
}

/// A lifter's heaviest lift on one machine — a personal record shown on their
/// public profile.
class MachineRecord {
  MachineRecord({
    required this.machineId,
    required this.machineName,
    this.machineBrand,
    required this.weightKg,
    required this.reps,
    required this.estimated1rm,
    required this.performedAt,
  });

  final int machineId;
  final String machineName;
  final String? machineBrand;
  final double weightKg;
  final int reps;
  final double estimated1rm;
  final DateTime performedAt;

  factory MachineRecord.fromJson(Map<String, dynamic> json) => MachineRecord(
        machineId: json['machine_id'] as int,
        machineName: json['machine_name'] as String,
        machineBrand: json['machine_brand'] as String?,
        weightKg: _toDouble(json['weight_kg']),
        reps: json['reps'] as int,
        estimated1rm: _toDouble(json['estimated_1rm'] ?? 0),
        performedAt: DateTime.parse(json['performed_at'] as String).toLocal(),
      );
}

/// One day's best estimated 1RM on a machine — a point on the progress chart.
class ProgressPoint {
  ProgressPoint({
    required this.date,
    required this.estimated1rm,
    required this.weightKg,
    required this.reps,
  });

  final DateTime date;
  final double estimated1rm;
  final double weightKg;
  final int reps;

  factory ProgressPoint.fromJson(Map<String, dynamic> json) => ProgressPoint(
        date: DateTime.parse(json['date'] as String),
        estimated1rm: _toDouble(json['estimated_1rm']),
        weightKg: _toDouble(json['weight_kg']),
        reps: json['reps'] as int,
      );
}

/// Another lifter's public profile.
class PublicProfile {
  PublicProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.gender,
    this.ageBracket,
    this.weightClass,
    this.bodyWeightStale = false,
    this.homeGymName,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.machinesTrained,
    required this.bestEstimated1rm,
    this.weekStreak = 0,
    this.records = const [],
    this.badges = const [],
    this.medals = 0,
  });

  final int id;
  final String name;
  final String? avatarUrl;
  final String? gender;
  final String? ageBracket;
  final String? weightClass;
  final bool bodyWeightStale;
  final String? homeGymName;
  final int totalSets;
  final double totalVolumeKg;
  final int machinesTrained;
  final double bestEstimated1rm;

  /// Consecutive weeks (Mon–Sun) with at least one gym session. See the
  /// backend's `User::weekStreak()`.
  final int weekStreak;

  /// Heaviest lift per machine, featured machines first (see backend).
  final List<MachineRecord> records;
  final List<String> badges;

  /// Challenge medals — one per challenge won. Shown under the avatar.
  final int medals;

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;
    final homeGym = json['home_gym'] as Map<String, dynamic>?;
    return PublicProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      gender: json['gender'] as String?,
      ageBracket: json['age_bracket'] as String?,
      weightClass: json['weight_class'] as String?,
      bodyWeightStale: json['body_weight_stale'] as bool? ?? false,
      homeGymName: homeGym?['name'] as String?,
      totalSets: stats['total_sets'] as int,
      totalVolumeKg: _toDouble(stats['total_volume_kg']),
      machinesTrained: stats['machines_trained'] as int,
      bestEstimated1rm: _toDouble(stats['best_estimated_1rm'] ?? 0),
      weekStreak: stats['week_streak'] as int? ?? 0,
      records: ((json['records'] as List?) ?? const [])
          .map((r) => MachineRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
      badges: ((json['badges'] as List?) ?? const [])
          .map((b) => b.toString())
          .toList(),
      medals: json['medals'] as int? ?? 0,
    );
  }
}

/// One calendar-day gym session in a lifter's history.
class GymSession {
  GymSession({
    required this.date,
    this.gymName,
    required this.setCount,
    required this.totalVolumeKg,
    this.topMachine,
    required this.topEstimated1rm,
  });

  final String date;
  final String? gymName;
  final int setCount;
  final double totalVolumeKg;
  final String? topMachine;
  final double topEstimated1rm;

  factory GymSession.fromJson(Map<String, dynamic> json) => GymSession(
        date: json['date'] as String,
        gymName: json['gym_name'] as String?,
        setCount: json['set_count'] as int,
        totalVolumeKg: _toDouble(json['total_volume_kg']),
        topMachine: json['top_machine'] as String?,
        topEstimated1rm: _toDouble(json['top_estimated_1rm'] ?? 0),
      );
}

/// A lifter currently checked in at the same gym.
class GymPerson {
  GymPerson({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.checkedInAt,
    required this.isMe,
  });

  final int userId;
  final String name;
  final String? avatarUrl;
  final DateTime checkedInAt;
  final bool isMe;

  factory GymPerson.fromJson(Map<String, dynamic> json) => GymPerson(
        userId: json['user_id'] as int,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        checkedInAt:
            DateTime.parse(json['checked_in_at'] as String).toLocal(),
        isMe: json['is_me'] as bool? ?? false,
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
    this.muscleGroup,
    this.description,
  });

  final int id;
  final String name;
  final String brand;
  final String category;

  /// Fine-grained muscle group as shown in the gym catalogue (e.g. "Quadriceps").
  final String? muscleGroup;
  final String? description;

  factory Machine.fromJson(Map<String, dynamic> json) => Machine(
        id: json['id'] as int,
        name: json['name'] as String,
        brand: json['brand'] as String,
        category: json['category'] as String,
        muscleGroup: json['muscle_group'] as String?,
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
    this.machineId,
    this.machineName,
  });

  final int id;
  final double weightKg;
  final int reps;
  final double estimated1rm;
  final DateTime performedAt;
  final int? machineId;
  final String? machineName;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        id: json['id'] as int,
        weightKg: _toDouble(json['weight_kg']),
        reps: json['reps'] as int,
        estimated1rm: _toDouble(json['estimated_1rm']),
        performedAt: DateTime.parse(json['performed_at'] as String).toLocal(),
        machineId: (json['machine'] as Map<String, dynamic>?)?['id'] as int?,
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
    this.type = 'rank',
    this.challengeId,
  });

  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  /// 'rank' for leaderboard alerts, or a 'challenge_*' type that deep-links
  /// to [challengeId].
  final String type;
  final int? challengeId;

  bool get isUnread => readAt == null;
  bool get isChallenge => type.startsWith('challenge') && challengeId != null;

  factory RankNotification.fromJson(Map<String, dynamic> json) =>
      RankNotification(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String).toLocal(),
        type: json['type'] as String? ?? 'rank',
        challengeId: json['challenge_id'] as int?,
      );
}

/// A lifter on either side of a challenge (or its winner).
class ChallengeParticipant {
  ChallengeParticipant({required this.id, required this.name, this.avatarUrl});

  final int id;
  final String name;
  final String? avatarUrl;

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) =>
      ChallengeParticipant(
        id: json['id'] as int,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );
}

/// Arena vote tally for a challenge.
class ChallengeTally {
  ChallengeTally({
    required this.challenger,
    required this.opponent,
    required this.invalid,
    required this.approvers,
    required this.rejecters,
    required this.total,
  });

  final int challenger;
  final int opponent;
  final int invalid;
  final int approvers;
  final int rejecters;
  final int total;

  factory ChallengeTally.fromJson(Map<String, dynamic>? json) => ChallengeTally(
        challenger: json?['challenger'] as int? ?? 0,
        opponent: json?['opponent'] as int? ?? 0,
        invalid: json?['invalid'] as int? ?? 0,
        approvers: json?['approvers'] as int? ?? 0,
        rejecters: json?['rejecters'] as int? ?? 0,
        total: json?['total'] as int? ?? 0,
      );
}

/// A head-to-head challenge and its arena-judging state.
class Challenge {
  Challenge({
    required this.id,
    required this.status,
    this.machineId,
    this.machineName,
    this.machineMuscleGroup,
    this.gymName,
    required this.targetWeightKg,
    required this.targetReps,
    required this.targetSets,
    this.challenger,
    this.opponent,
    required this.challengerSubmitted,
    required this.opponentSubmitted,
    this.challengerVideoUrl,
    this.opponentVideoUrl,
    this.votingEndsAt,
    this.winnerId,
    this.winner,
    this.createdAt,
    required this.myRole,
    required this.iSubmitted,
    this.myVote,
    required this.canVote,
    required this.tally,
  });

  final int id;

  /// pending | active | completed | declined | cancelled
  final String status;
  final int? machineId;
  final String? machineName;
  final String? machineMuscleGroup;
  final String? gymName;
  final double targetWeightKg;
  final int targetReps;
  final int targetSets;
  final ChallengeParticipant? challenger;
  final ChallengeParticipant? opponent;
  final bool challengerSubmitted;
  final bool opponentSubmitted;
  final String? challengerVideoUrl;
  final String? opponentVideoUrl;
  final DateTime? votingEndsAt;
  final int? winnerId;
  final ChallengeParticipant? winner;
  final DateTime? createdAt;

  /// challenger | opponent | judge
  final String myRole;
  final bool iSubmitted;

  /// challenger | opponent | invalid — the current user's arena vote, if any.
  final String? myVote;
  final bool canVote;
  final ChallengeTally tally;

  bool get isParticipant => myRole == 'challenger' || myRole == 'opponent';

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final machine = json['machine'] as Map<String, dynamic>?;
    final gym = json['gym'] as Map<String, dynamic>?;
    ChallengeParticipant? part(String key) {
      final m = json[key] as Map<String, dynamic>?;
      return m == null ? null : ChallengeParticipant.fromJson(m);
    }

    return Challenge(
      id: json['id'] as int,
      status: json['status'] as String,
      machineId: machine?['id'] as int?,
      machineName: machine?['name'] as String?,
      machineMuscleGroup: machine?['muscle_group'] as String?,
      gymName: gym?['name'] as String?,
      targetWeightKg: _toDouble(json['target_weight_kg']),
      targetReps: json['target_reps'] as int,
      targetSets: json['target_sets'] as int,
      challenger: part('challenger'),
      opponent: part('opponent'),
      challengerSubmitted: json['challenger_submitted'] as bool? ?? false,
      opponentSubmitted: json['opponent_submitted'] as bool? ?? false,
      challengerVideoUrl: json['challenger_video_url'] as String?,
      opponentVideoUrl: json['opponent_video_url'] as String?,
      votingEndsAt: json['voting_ends_at'] == null
          ? null
          : DateTime.parse(json['voting_ends_at'] as String).toLocal(),
      winnerId: json['winner_id'] as int?,
      winner: part('winner'),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String).toLocal(),
      myRole: json['my_role'] as String? ?? 'judge',
      iSubmitted: json['i_submitted'] as bool? ?? false,
      myVote: json['my_vote'] as String?,
      canVote: json['can_vote'] as bool? ?? false,
      tally: ChallengeTally.fromJson(json['tally'] as Map<String, dynamic>?),
    );
  }
}

/// A row on a gym's public leaderboard: the lifter's best set at that gym
/// within the period, ranked by estimated 1RM.
class GymLeaderboardEntry {
  GymLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.value,
    required this.weightKg,
    required this.reps,
    required this.machineName,
    required this.performedAt,
  });

  final int rank;
  final int userId;
  final String userName;
  final String? avatarUrl;
  final double value;
  final double weightKg;
  final int reps;
  final String machineName;
  final DateTime performedAt;

  factory GymLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      GymLeaderboardEntry(
        rank: json['rank'] as int,
        userId: json['user_id'] as int,
        userName: json['user_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        value: _toDouble(json['value']),
        weightKg: _toDouble(json['weight_kg']),
        reps: json['reps'] as int,
        machineName: json['machine_name'] as String,
        performedAt: DateTime.parse(json['performed_at'] as String).toLocal(),
      );
}

class CheckinResult {
  CheckinResult({required this.gym, required this.distanceM});

  final Gym gym;
  final int distanceM;
}
