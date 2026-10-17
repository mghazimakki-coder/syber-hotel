import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/services/profile_service.dart';

void main() {
  group('AppRole.fromDatabaseValue', () {
    test('accepts only exact privileged and customer database roles', () {
      expect(AppRole.fromDatabaseValue('customer'), AppRole.customer);
      expect(AppRole.fromDatabaseValue('receptionist'), AppRole.receptionist);
      expect(AppRole.fromDatabaseValue('manager'), AppRole.manager);
    });

    test('fails closed for missing, invalid, or differently-cased roles', () {
      expect(AppRole.fromDatabaseValue(null), isNull);
      expect(AppRole.fromDatabaseValue(''), isNull);
      expect(AppRole.fromDatabaseValue('admin'), isNull);
      expect(AppRole.fromDatabaseValue('MANAGER'), isNull);
      expect(AppRole.fromDatabaseValue(' manager '), isNull);
    });
  });
}
