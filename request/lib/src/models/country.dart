class Country {
  final String code;
  final String name;
  final String phoneCode; // e.g. "+94"
  final String? flagEmoji; // Computed from code if not provided
  final String? flagUrl; // Server-provided flag URL (optional)
  final bool isEnabled; // true = selectable now
  final String comingSoonMessage; // Shown when disabled

  const Country({
    required this.code,
    required this.name,
    required this.phoneCode,
    this.flagEmoji,
    this.flagUrl,
    this.isEnabled = true,
    this.comingSoonMessage = '',
  });

  /// Fallback flag string for UI (emoji preferred, else placeholder globe)
  String get flag => flagEmoji ?? _countryCodeToEmoji(code) ?? '🌐';

  /// JSON factory mapping backend /api/countries/public response.
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: (json['code'] ?? '').toString().toUpperCase(),
      name: (json['name'] ?? '').toString(),
      phoneCode: (json['phoneCode'] ?? json['phone_prefix'] ?? '').toString(),
      flagEmoji: json['flagEmoji'] as String?,
      flagUrl: json['flagUrl'] as String?,
      isEnabled: _computeEnabled(json),
      comingSoonMessage: (json['comingSoonMessage'] ?? '') as String,
    );
  }

  static bool _computeEnabled(Map<String, dynamic> json) {
    if (json.containsKey('isEnabled')) return json['isEnabled'] == true;
    if (json.containsKey('isActive')) return json['isActive'] == true;
    if (json.containsKey('comingSoon')) return json['comingSoon'] != true;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'phoneCode': phoneCode,
        'flagEmoji': flagEmoji,
        'flagUrl': flagUrl,
        'isEnabled': isEnabled,
        'comingSoonMessage': comingSoonMessage,
      };

  Country copyWith({
    String? code,
    String? name,
    String? phoneCode,
    String? flagEmoji,
    String? flagUrl,
    bool? isEnabled,
    String? comingSoonMessage,
  }) =>
      Country(
        code: code ?? this.code,
        name: name ?? this.name,
        phoneCode: phoneCode ?? this.phoneCode,
        flagEmoji: flagEmoji ?? this.flagEmoji,
        flagUrl: flagUrl ?? this.flagUrl,
        isEnabled: isEnabled ?? this.isEnabled,
        comingSoonMessage: comingSoonMessage ?? this.comingSoonMessage,
      );

  static String? _countryCodeToEmoji(String code) {
    if (code.length != 2) return null;
    final int base = 0x1F1E6; // Regional Indicator Symbol Letter A
    final String upper = code.toUpperCase();
    final int first = upper.codeUnitAt(0) - 0x41 + base;
    final int second = upper.codeUnitAt(1) - 0x41 + base;
    if (first < base || second < base) return null;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  @override
  String toString() => '${flag} $name ($phoneCode)';
}
