class ScheduleModel {
  final bool waterEnabled;
  final int waterStartMinutes;
  final int waterEndMinutes;
  final int waterIntervalMinutes;

  final bool breakfastEnabled;
  final int breakfastMinutes;

  final bool lunchEnabled;
  final int lunchMinutes;

  final bool dinnerEnabled;
  final int dinnerMinutes;

  const ScheduleModel({
    this.waterEnabled = false,
    this.waterStartMinutes = 8 * 60,
    this.waterEndMinutes = 22 * 60,
    this.waterIntervalMinutes = 60,
    this.breakfastEnabled = false,
    this.breakfastMinutes = 8 * 60,
    this.lunchEnabled = false,
    this.lunchMinutes = 12 * 60,
    this.dinnerEnabled = false,
    this.dinnerMinutes = 19 * 60,
  });

  ScheduleModel copyWith({
    bool? waterEnabled,
    int? waterStartMinutes,
    int? waterEndMinutes,
    int? waterIntervalMinutes,
    bool? breakfastEnabled,
    int? breakfastMinutes,
    bool? lunchEnabled,
    int? lunchMinutes,
    bool? dinnerEnabled,
    int? dinnerMinutes,
  }) {
    return ScheduleModel(
      waterEnabled: waterEnabled ?? this.waterEnabled,
      waterStartMinutes: waterStartMinutes ?? this.waterStartMinutes,
      waterEndMinutes: waterEndMinutes ?? this.waterEndMinutes,
      waterIntervalMinutes: waterIntervalMinutes ?? this.waterIntervalMinutes,
      breakfastEnabled: breakfastEnabled ?? this.breakfastEnabled,
      breakfastMinutes: breakfastMinutes ?? this.breakfastMinutes,
      lunchEnabled: lunchEnabled ?? this.lunchEnabled,
      lunchMinutes: lunchMinutes ?? this.lunchMinutes,
      dinnerEnabled: dinnerEnabled ?? this.dinnerEnabled,
      dinnerMinutes: dinnerMinutes ?? this.dinnerMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waterEnabled': waterEnabled,
      'waterStartMinutes': waterStartMinutes,
      'waterEndMinutes': waterEndMinutes,
      'waterIntervalMinutes': waterIntervalMinutes,
      'breakfastEnabled': breakfastEnabled,
      'breakfastMinutes': breakfastMinutes,
      'lunchEnabled': lunchEnabled,
      'lunchMinutes': lunchMinutes,
      'dinnerEnabled': dinnerEnabled,
      'dinnerMinutes': dinnerMinutes,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      waterEnabled: map['waterEnabled'] ?? false,
      waterStartMinutes: map['waterStartMinutes'] ?? 480,
      waterEndMinutes: map['waterEndMinutes'] ?? 1320,
      waterIntervalMinutes: map['waterIntervalMinutes'] ?? 60,
      breakfastEnabled: map['breakfastEnabled'] ?? false,
      breakfastMinutes: map['breakfastMinutes'] ?? 480,
      lunchEnabled: map['lunchEnabled'] ?? false,
      lunchMinutes: map['lunchMinutes'] ?? 720,
      dinnerEnabled: map['dinnerEnabled'] ?? false,
      dinnerMinutes: map['dinnerMinutes'] ?? 1140,
    );
  }
}
