class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool useTouchId;
  final bool useFaceId;
  final bool usePasscode;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.useTouchId,
    required this.useFaceId,
    required this.usePasscode,
    required this.createdAt,
  });
}