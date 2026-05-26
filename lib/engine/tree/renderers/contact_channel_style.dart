import 'package:flutter/material.dart';

/// Default colors and icon names per [contactButton] channel.
class ContactChannelStyle {
  const ContactChannelStyle({
    required this.iconName,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String iconName;
  final Color? backgroundColor;
  final Color? foregroundColor;

  static const whatsAppGreen = Color(0xFF25D366);

  static ContactChannelStyle forChannel(String? channel) {
    switch (channel?.toLowerCase()) {
      case 'whatsapp':
        return const ContactChannelStyle(
          iconName: 'phone',
          backgroundColor: whatsAppGreen,
          foregroundColor: Colors.white,
        );
      case 'tel':
        return const ContactChannelStyle(
          iconName: 'phone',
          backgroundColor: Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        );
      case 'sms':
        return const ContactChannelStyle(
          iconName: 'sms',
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
        );
      case 'email':
        return const ContactChannelStyle(
          iconName: 'mail',
          backgroundColor: Color(0xFF475569),
          foregroundColor: Colors.white,
        );
      case 'url':
        return const ContactChannelStyle(
          iconName: 'help_outline',
          backgroundColor: Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        );
      default:
        return const ContactChannelStyle(iconName: 'phone');
    }
  }
}
