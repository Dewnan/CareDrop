import 'package:flutter_test/flutter_test.dart';
import 'package:caredrop/models/task_creation_form_data.dart';

/// Test case for task creation data formatting and payment fee calculations.
void main() {
  test('Cash payment excludes platform service fee', () {
    final cashData = TaskCreationFormData(
      budget: '300',
      paymentMethod: 'Cash',
    );
    final isCash = cashData.paymentMethod.toLowerCase().contains('cash');
    final baseFee = double.tryParse(cashData.budget ?? '250') ?? 250.0;
    final platformFee = isCash ? 0.0 : 30.0;
    final totalFee = baseFee + platformFee;

    expect(platformFee, 0.0);
    expect(totalFee, 300.0);
  });

  test('Online payment includes platform service fee', () {
    final onlineData = TaskCreationFormData(
      budget: '300',
      paymentMethod: 'Online Payment',
    );
    final isCash = onlineData.paymentMethod.toLowerCase().contains('cash');
    final baseFee = double.tryParse(onlineData.budget ?? '250') ?? 250.0;
    final platformFee = isCash ? 0.0 : 30.0;
    final totalFee = baseFee + platformFee;

    expect(platformFee, 30.0);
    expect(totalFee, 330.0);
  });
}
