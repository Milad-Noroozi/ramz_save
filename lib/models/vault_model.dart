import '../config/app_strings.dart';

/// What a vault entry holds. `account` covers logins; `payment` covers cards.
enum VaultType {
  account,
  payment;

  String get label => switch (this) {
    VaultType.account => AppStrings.tabAccount,
    VaultType.payment => AppStrings.tabPayment,
  };

  static VaultType fromName(String? name) => VaultType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => VaultType.account,
  );
}

/// Category tags shown on the home cards and as filter chips.
enum VaultTag {
  browser,
  mobileApp,
  payment;

  String get label => switch (this) {
    VaultTag.browser => AppStrings.categoryBrowser,
    VaultTag.mobileApp => AppStrings.categoryMobileApp,
    VaultTag.payment => AppStrings.categoryPayment,
  };

  static VaultTag? fromName(String? name) {
    for (final t in VaultTag.values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

/// A single vault entry.
///
/// [password], [cardNumber] and [cvv] hold **plaintext** in memory. They are
/// only ever written to disk through the encrypted Hive box, whose cipher key
/// lives in the OS keystore — see `EncryptionService`.
class VaultModel {
  final String id;
  final VaultType type;
  final String serviceName;
  final String? serviceUrl;
  final String login;
  final String password;
  final List<VaultTag> tags;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Payment-only fields; null for account entries.
  final String? cardBrand;
  final String? cardHolder;
  final String? cardNumber;
  final String? cardExpiry;
  final String? cvv;

  const VaultModel({
    required this.id,
    required this.serviceName,
    required this.login,
    required this.password,
    required this.createdAt,
    this.type = VaultType.account,
    this.serviceUrl,
    this.tags = const [],
    this.note,
    this.updatedAt,
    this.cardBrand,
    this.cardHolder,
    this.cardNumber,
    this.cardExpiry,
    this.cvv,
  });

  VaultModel copyWith({
    String? serviceName,
    String? serviceUrl,
    String? login,
    String? password,
    List<VaultTag>? tags,
    String? note,
    DateTime? updatedAt,
    VaultType? type,
    String? cardBrand,
    String? cardHolder,
    String? cardNumber,
    String? cardExpiry,
    String? cvv,
  }) {
    return VaultModel(
      id: id,
      type: type ?? this.type,
      serviceName: serviceName ?? this.serviceName,
      serviceUrl: serviceUrl ?? this.serviceUrl,
      login: login ?? this.login,
      password: password ?? this.password,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardBrand: cardBrand ?? this.cardBrand,
      cardHolder: cardHolder ?? this.cardHolder,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cvv: cvv ?? this.cvv,
    );
  }

  /// Stored as a plain map rather than a generated Hive adapter — it keeps the
  /// build codegen-free and makes the backup format the same shape as the box.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'serviceName': serviceName,
    'serviceUrl': serviceUrl,
    'login': login,
    'password': password,
    'tags': tags.map((t) => t.name).toList(),
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'cardBrand': cardBrand,
    'cardHolder': cardHolder,
    'cardNumber': cardNumber,
    'cardExpiry': cardExpiry,
    'cvv': cvv,
  };

  factory VaultModel.fromJson(Map<dynamic, dynamic> json) {
    return VaultModel(
      id: json['id'] as String,
      type: VaultType.fromName(json['type'] as String?),
      serviceName: json['serviceName'] as String? ?? '',
      serviceUrl: json['serviceUrl'] as String?,
      login: json['login'] as String? ?? '',
      password: json['password'] as String? ?? '',
      tags: (json['tags'] as List?)
              ?.map((t) => VaultTag.fromName(t as String?))
              .whereType<VaultTag>()
              .toList() ??
          const [],
      note: json['note'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
      cardBrand: json['cardBrand'] as String?,
      cardHolder: json['cardHolder'] as String?,
      cardNumber: json['cardNumber'] as String?,
      cardExpiry: json['cardExpiry'] as String?,
      cvv: json['cvv'] as String?,
    );
  }

  /// Text a search query is matched against. Excludes the password — searching
  /// by secret would leak which entries share one via the result count.
  String get searchHaystack =>
      '$serviceName ${serviceUrl ?? ''} $login ${note ?? ''}'.toLowerCase();

  @override
  bool operator ==(Object other) => other is VaultModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
