class VaultModel {
  final String id;
  final String serviceName;
  final String? serviceUrl;
  final String email;
  final String password; // encrypted
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VaultModel({
    required this.id,
    required this.serviceName,
    this.serviceUrl,
    required this.email,
    required this.password,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
  });
}