import '../config/app_strings.dart';

/// How long the app may stay unlocked in the background before it re-locks.
enum AutoLockDuration {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5)),
  fifteenMinutes(Duration(minutes: 15)),
  never(null);

  const AutoLockDuration(this.duration);

  /// `null` means never re-lock automatically.
  final Duration? duration;

  String get label => switch (this) {
    AutoLockDuration.immediately => AppStrings.autoLockImmediately,
    AutoLockDuration.never => AppStrings.autoLockNever,
    _ => '${duration!.inMinutes} ${AppStrings.minute}',
  };

  static AutoLockDuration fromName(String? name) =>
      AutoLockDuration.values.firstWhere(
        (d) => d.name == name,
        orElse: () => AutoLockDuration.fiveMinutes,
      );
}

/// The account holder's profile and preferences.
///
/// Deliberately holds no password material: the master password is never
/// stored, and the vault key lives in the OS keystore.
class UserModel {
  final String name;
  final String? email;
  final String? phone;
  final bool useBiometric;
  final AutoLockDuration autoLock;
  final bool checkBreachesOnline;
  final DateTime createdAt;

  const UserModel({
    required this.name,
    required this.createdAt,
    this.email,
    this.phone,
    this.useBiometric = false,
    this.autoLock = AutoLockDuration.fiveMinutes,
    this.checkBreachesOnline = false,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    bool? useBiometric,
    AutoLockDuration? autoLock,
    bool? checkBreachesOnline,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      useBiometric: useBiometric ?? this.useBiometric,
      autoLock: autoLock ?? this.autoLock,
      checkBreachesOnline: checkBreachesOnline ?? this.checkBreachesOnline,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'useBiometric': useBiometric,
    'autoLock': autoLock.name,
    'checkBreachesOnline': checkBreachesOnline,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<dynamic, dynamic> json) {
    return UserModel(
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      useBiometric: json['useBiometric'] as bool? ?? false,
      autoLock: AutoLockDuration.fromName(json['autoLock'] as String?),
      checkBreachesOnline: json['checkBreachesOnline'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
