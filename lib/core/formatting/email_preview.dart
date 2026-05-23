/// Short preview of where a verification email was sent.
abstract final class EmailPreview {
  EmailPreview._();

  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return 'your email';

    final user = email.substring(0, at);
    final domain = email.substring(at + 1);
    final mid = '${user[0]}${'*' * (user.length - 2)}${user[user.length - 1]}';
    return '$mid@$domain';
  }
}
