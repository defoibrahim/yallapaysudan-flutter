import '../exceptions/yalla_pay_exception.dart';

/// Reads [key] as a string. Numbers and booleans are converted with
/// `toString()`, because the gateway is not strict about types. Returns
/// `null` when the key is missing or `null`.
///
/// Throws [InvalidResponseException] for any other type.
String? readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return switch (value) {
    null => null,
    String() => value,
    num() || bool() => value.toString(),
    _ => throw _wrongType(json, key, 'a string', value),
  };
}

/// Like [readString], but the value must be present and non-empty.
String requireString(Map<String, dynamic> json, String key) {
  final value = readString(json, key);
  if (value == null || value.isEmpty) {
    throw InvalidResponseException(
      'Missing required field "$key".',
      rawResponse: json,
    );
  }
  return value;
}

/// Reads [key] as a number. Numeric strings are parsed. Returns `null` when
/// the key is missing or `null`.
///
/// Throws [InvalidResponseException] for any other type.
num? readNum(Map<String, dynamic> json, String key) {
  final value = json[key];
  return switch (value) {
    null => null,
    num() => value,
    String() => num.tryParse(value) ?? (throw _wrongType(json, key, 'a number', value)),
    _ => throw _wrongType(json, key, 'a number', value),
  };
}

/// Like [readNum], but the value must be present and a whole number.
int requireInt(Map<String, dynamic> json, String key) {
  final value = readNum(json, key);
  if (value == null || !value.isFinite || value != value.truncate()) {
    throw InvalidResponseException(
      'Missing or invalid integer field "$key".',
      rawResponse: json,
    );
  }
  return value.toInt();
}

InvalidResponseException _wrongType(
  Map<String, dynamic> json,
  String key,
  String expected,
  Object? value,
) => InvalidResponseException(
  'Expected "$key" to be $expected, got ${value.runtimeType}.',
  rawResponse: json,
);
