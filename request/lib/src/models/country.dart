class Country {
  final String code;
  final String name;
  final String phoneCode;
  final String flagEmoji;
  final String flag; // Alternative to flagEmoji for compatibility
  final bool isEnabled;
  final String comingSoonMessage;

  const Country({
    required this.code,
    required this.name,
    required this.phoneCode,
    required this.flagEmoji,
    this.isEnabled = true,
    this.comingSoonMessage = '',
  }) : flag = flagEmoji;

  static const List<Country> availableCountries = [
    Country(
      code: 'LK',
      name: 'Sri Lanka',
      phoneCode: '+94',
      flagEmoji: '🇱🇰',
    ),
    Country(
      code: 'US',
      name: 'United States',
      phoneCode: '+1',
      flagEmoji: '🇺🇸',
    ),
    Country(
      code: 'UK',
      name: 'United Kingdom',
      phoneCode: '+44',
      flagEmoji: '🇬🇧',
    ),
    Country(
      code: 'CA',
      name: 'Canada',
      phoneCode: '+1',
      flagEmoji: '🇨🇦',
    ),
    Country(
      code: 'AU',
      name: 'Australia',
      phoneCode: '+61',
      flagEmoji: '🇦🇺',
    ),
    Country(
      code: 'IN',
      name: 'India',
      phoneCode: '+91',
      flagEmoji: '🇮🇳',
    ),
    Country(
      code: 'DE',
      name: 'Germany',
      phoneCode: '+49',
      flagEmoji: '🇩🇪',
    ),
    Country(
      code: 'FR',
      name: 'France',
      phoneCode: '+33',
      flagEmoji: '🇫🇷',
    ),
    Country(
      code: 'JP',
      name: 'Japan',
      phoneCode: '+81',
      flagEmoji: '🇯🇵',
    ),
    Country(
      code: 'SG',
      name: 'Singapore',
      phoneCode: '+65',
      flagEmoji: '🇸🇬',
    ),
  ];

  @override
  String toString() => '$flagEmoji $name ($phoneCode)';
}
