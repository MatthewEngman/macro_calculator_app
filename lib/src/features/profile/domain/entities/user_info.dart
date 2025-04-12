import '../../../profile/presentation/providers/settings_provider.dart';

class UserInfo {
  final double? weight;
  final int? feet;
  final int? inches;
  final int? age;
  final String sex;
  final ActivityLevel activityLevel;
  final Goal goal;
  final Units units;
  final String? id;
  final bool isDefault;
  final String? name;
  final DateTime? lastModified;

  UserInfo({
    this.weight,
    this.feet,
    this.inches,
    this.age,
    required this.sex,
    required this.activityLevel,
    required this.goal,
    required this.units,
    this.id,
    this.isDefault = false,
    this.name,
    this.lastModified,
  });

  UserInfo copyWith({
    double? weight,
    int? feet,
    int? inches,
    int? age,
    String? sex,
    ActivityLevel? activityLevel,
    Goal? goal,
    Units? units,
    String? id,
    bool? isDefault,
    String? name,
    DateTime? lastModified,
  }) {
    return UserInfo(
      weight: weight ?? this.weight,
      feet: feet ?? this.feet,
      inches: inches ?? this.inches,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      units: units ?? this.units,
      id: id ?? this.id,
      isDefault: isDefault ?? this.isDefault,
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'feet': feet,
      'inches': inches,
      'age': age,
      'sex': sex,
      'activityLevel': activityLevel.index,
      'goal': goal.index,
      'units': units.index,
      'id': id,
      'isDefault': isDefault,
      'name': name,
      'lastModified': lastModified?.millisecondsSinceEpoch,
    };
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      weight: json['weight'],
      feet: json['feet'],
      inches: json['inches'],
      age: json['age'],
      sex: json['sex'] ?? 'male',
      activityLevel: ActivityLevel.values[json['activityLevel'] ?? 0],
      goal: Goal.values[json['goal'] ?? 1],
      units: Units.values[json['units'] ?? 0],
      id: json['id'],
      isDefault: json['isDefault'] ?? false,
      name: json['name'],
      lastModified:
          json['lastModified'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
              : null,
    );
  }
}
