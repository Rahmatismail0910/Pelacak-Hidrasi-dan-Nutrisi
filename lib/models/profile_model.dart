class ProfileModel {
  final int? id;
  final int userId;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? gender;
  final String? activityLevel;
  final String updatedAt;

  const ProfileModel({
    this.id,
    required this.userId,
    this.age,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.activityLevel,
    required this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, Object?> map) {
    return ProfileModel(
      id: (map['id'] as num?)?.toInt(),
      userId: (map['user_id'] as num).toInt(),
      age: (map['age'] as num?)?.toInt(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      gender: map['gender'] as String?,
      activityLevel: map['activity_level'] as String?,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'gender': gender,
      'activity_level': activityLevel,
      'updated_at': updatedAt,
    };
  }
}
