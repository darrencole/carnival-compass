import 'package:carnival_compass_mobile/fete_add.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  test('Fete base price test', () {
    final formatExceptionStr = 'Price must be valid format, eg: 350.00';

    String priceStr = 'i am not a price';
    dynamic result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, formatExceptionStr);

    priceStr = '1.999';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, formatExceptionStr);

    priceStr = '1.990';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, formatExceptionStr);

    priceStr = '1.000';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, formatExceptionStr);

    priceStr = '1';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, null);

    priceStr = '1.0';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, null);

    priceStr = '1.99';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, null);

    priceStr = '-1';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, 'Price must be \$0.00 or more');

    priceStr = '9999.99';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, null);

    priceStr = '10000';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, null);

    priceStr = '10000.01';
    result = FeteFormValidators.validateBasePrice(priceStr);
    expect(result, 'Price must be less than \$10000');
  });

  test('Fete time parsing test', () {
    String timeStr = '8:00 AM';
    TimeOfDay timeOfDay = FeteFormValidators.parsePartyTimeOfDay(timeStr);
    expect(timeOfDay.minute, 0);
    expect(timeOfDay.hour, 8);

    timeStr = '8:00 PM';
    timeOfDay = FeteFormValidators.parsePartyTimeOfDay(timeStr);
    expect(timeOfDay.minute, 0);
    expect(timeOfDay.hour, 20);

    timeStr = 'i am not a time';
    expect(() => FeteFormValidators.parsePartyTimeOfDay(timeStr),
        throwsFormatException);
  });
}
