abstract final class OtpValidator {
  OtpValidator._();

  static String? requireComplete(String digits, int expectedLength) {
    if (digits.length != expectedLength) {
      return 'Enter all $expectedLength digits.';
    }
    return null;
  }
}
