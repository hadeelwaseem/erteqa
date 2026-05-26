/// Builds external URIs for [openContact] actions (WhatsApp, tel, sms, email, url).
class ContactUriBuilder {
  ContactUriBuilder._();

  static String? buildUri({
    required String channel,
    required String target,
  }) {
    final trimmed = target.trim();
    if (trimmed.isEmpty) return null;

    switch (channel.toLowerCase()) {
      case 'whatsapp':
        final digits = _digitsOnly(trimmed);
        if (digits.isEmpty) return null;
        return 'https://wa.me/$digits';
      case 'tel':
        final digits = _digitsOnly(trimmed);
        if (digits.isEmpty) return null;
        return 'tel:$digits';
      case 'sms':
        final digits = _digitsOnly(trimmed);
        if (digits.isEmpty) return null;
        return 'sms:$digits';
      case 'email':
        return 'mailto:$trimmed';
      case 'url':
        return trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';
      default:
        return null;
    }
  }

  static String _digitsOnly(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }
}
