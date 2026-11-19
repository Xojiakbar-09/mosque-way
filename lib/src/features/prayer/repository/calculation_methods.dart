/// Explicit regional defaults avoid the API choosing the nearest authority in
/// another country (for example, Tehran for Tashkent). These are calculations,
/// not a claim to reproduce each country's official published timetable.
class CalculationMethods {
  static const names = <int, String>{
    1: 'Karachi',
    2: 'ISNA',
    3: 'Muslim World League',
    4: 'Umm Al-Qura',
    5: 'Egyptian General Authority',
    7: 'Tehran',
    9: 'Kuwait',
    10: 'Qatar',
    11: 'Singapore',
    13: 'Diyanet',
    14: 'Spiritual Administration of Muslims of Russia',
    16: 'Dubai',
    17: 'JAKIM',
    20: 'Kemenag',
  };
  static int forCountry(String country) => switch (country.toUpperCase()) {
    'UZ' || 'KZ' || 'KG' || 'TJ' || 'TM' || 'PK' || 'AF' || 'IN' || 'BD' => 1,
    'US' || 'CA' => 2,
    'SA' => 4,
    'EG' => 5,
    'IR' => 7,
    'KW' => 9,
    'QA' => 10,
    'SG' => 11,
    'TR' => 13,
    'RU' => 14,
    'AE' => 16,
    'MY' => 17,
    'ID' => 20,
    _ => 3,
  };
}
