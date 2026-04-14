import 'package:flutter_test/flutter_test.dart';
import 'package:ictu_community_org/core/validation/course_code_validator.dart';

void main() {
  group('CourseCodeValidator', () {
    test('accepts valid format XXX####', () {
      expect(CourseCodeValidator.isValid('CSC3141'), isTrue);
      expect(CourseCodeValidator.validate('SEN2142'), isNull);
    });

    test('rejects invalid format', () {
      expect(CourseCodeValidator.isValid('CS3141'), isFalse);
      expect(CourseCodeValidator.validate('12ABCD3'), isNotNull);
    });

    test('formats typed input to uppercase and length 7', () {
      expect(CourseCodeValidator.formatTyped('csc31-41test'), 'CSC3141');
    });
  });
}
