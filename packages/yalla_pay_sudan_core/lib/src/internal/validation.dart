/// Validation and serialisation shared by the request models.
library;

/// Throws [ArgumentError] unless [amount] is finite and at least [minimum].
void validateAmount(num amount, num minimum) {
  if (!amount.isFinite || amount < minimum) {
    throw ArgumentError.value(
      amount,
      'amount',
      'Must be a finite amount of at least $minimum SDG',
    );
  }
}

/// Throws [ArgumentError] if [clientReferenceId] is empty or blank.
void validateReference(String clientReferenceId) {
  if (clientReferenceId.trim().isEmpty) {
    throw ArgumentError.value(
      clientReferenceId,
      'clientReferenceId',
      'Must not be empty',
    );
  }
}

/// Throws [ArgumentError] unless [url] is null or an absolute http(s) URL.
void validateRedirectUrl(String? url, String name) {
  if (url == null) return;
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !(uri.isScheme('https') || uri.isScheme('http')) ||
      uri.host.isEmpty) {
    throw ArgumentError.value(url, name, 'Must be an absolute http(s) URL');
  }
}

/// Whole amounts are sent as integers (`5000`, not `5000.0`).
num amountToJson(num amount) =>
    amount == amount.truncate() ? amount.toInt() : amount;
