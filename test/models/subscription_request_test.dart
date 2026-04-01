import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

void main() {
  group('SubscriptionConfiguration', () {
    test('toJson produces correct API values', () {
      const config = SubscriptionConfiguration(
        interval: SubscriptionInterval.month,
        intervalCycle: 1,
        totalCycles: 12,
      );

      final json = config.toJson();

      expect(json['interval'], 'MONTH');
      expect(json['intervalCycle'], '1');
      expect(json['totalCycles'], '12');
    });

    test('toJson omits totalCycles when null', () {
      const config = SubscriptionConfiguration(
        interval: SubscriptionInterval.day,
        intervalCycle: 7,
      );

      final json = config.toJson();

      expect(json.containsKey('totalCycles'), false);
    });

    test('validate throws on intervalCycle < 1', () {
      const config = SubscriptionConfiguration(
        interval: SubscriptionInterval.month,
        intervalCycle: 0,
      );

      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate throws on totalCycles < 1', () {
      const config = SubscriptionConfiguration(
        interval: SubscriptionInterval.year,
        intervalCycle: 1,
        totalCycles: 0,
      );

      expect(() => config.validate(), throwsArgumentError);
    });
  });

  group('SubscriptionRequest', () {
    test('toJson includes subscriptionConfiguration', () {
      const request = SubscriptionRequest(
        amount: 5000,
        clientReferenceId: 'sub-123',
        subscriptionConfiguration: SubscriptionConfiguration(
          interval: SubscriptionInterval.month,
          intervalCycle: 1,
        ),
      );

      final json = request.toJson();

      expect(json['amount'], 5000);
      expect(json['clientReferenceId'], 'sub-123');
      expect(json['subscriptionConfiguration'], isA<Map<String, dynamic>>());
      expect(json['subscriptionConfiguration']['interval'], 'MONTH');
    });

    test('validate validates both request and configuration', () {
      const request = SubscriptionRequest(
        amount: 500,
        clientReferenceId: 'sub-123',
        subscriptionConfiguration: SubscriptionConfiguration(
          interval: SubscriptionInterval.month,
          intervalCycle: 1,
        ),
      );

      expect(() => request.validate(), throwsArgumentError);
    });
  });

  group('SubscriptionInterval', () {
    test('toApiValue returns correct strings', () {
      expect(SubscriptionInterval.day.toApiValue(), 'DAY');
      expect(SubscriptionInterval.month.toApiValue(), 'MONTH');
      expect(SubscriptionInterval.year.toApiValue(), 'YEAR');
    });

    test('fromString parses valid values case-insensitively', () {
      expect(SubscriptionInterval.fromString('day'), SubscriptionInterval.day);
      expect(
        SubscriptionInterval.fromString('MONTH'),
        SubscriptionInterval.month,
      );
      expect(
        SubscriptionInterval.fromString('Year'),
        SubscriptionInterval.year,
      );
    });

    test('fromString throws on invalid value', () {
      expect(
        () => SubscriptionInterval.fromString('WEEK'),
        throwsArgumentError,
      );
    });
  });
}
