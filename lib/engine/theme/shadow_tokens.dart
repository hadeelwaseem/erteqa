/*import 'package:flutter/painting.dart';

/// Canonical BoxShadow presets for JSON `shadow`: sm | md | lg | xl.
///
/// Strong presets tuned for clear visibility on page background `#F1F5F9`.
abstract final class ShadowTokens {
  /// Inset fields, chips — visible on light grey without overpowering.
  static const BoxShadow sm = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  /// Floating inputs, filter bars, autocomplete triggers.
  static const BoxShadow md = BoxShadow(
    color: Color(0x47000000),
    blurRadius: 16,
    spreadRadius: 0.5,
    offset: Offset(0, 4),
  );

  /// Product cards, panels, hero promos on light surfaces.
  static const BoxShadow lg = BoxShadow(
    color: Color(0x59000000),
    blurRadius: 24,
    spreadRadius: 1,
    offset: Offset(0, 6),
  );

  /// Checkout dock, modals, dropdown overlays, autocomplete panels.
  static const BoxShadow xl = BoxShadow(
    color: Color(0x66000000),
    blurRadius: 32,
    spreadRadius: 1.5,
    offset: Offset(0, 8),
  );
}
*/
import 'package:flutter/painting.dart';

abstract final class ShadowTokens {
  /// بطاقات صغيرة، حقول إدخال، عناصر واجهة خفيفة جداً (Bento cards)
  /// شفافية ~4% فقط.
  static const BoxShadow sm = BoxShadow(
    color: Color(0x0A000000), 
    blurRadius: 8,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );

  /// بطاقات تفاعلية، أشرطة تصفية، وعناصر عائمة بسيطة
  /// شفافية ~8%
  static const BoxShadow md = BoxShadow(
    color: Color(0x14000000), 
    blurRadius: 16,
    spreadRadius: 0,
    offset: Offset(0, 4),
  );

  /// لوحات بارزة، بطاقات ترويجية، حاويات رئيسية
  /// شفافية ~12% مع زيادة النعومة
  static const BoxShadow lg = BoxShadow(
    color: Color(0x1E000000), 
    blurRadius: 24,
    spreadRadius: -2, // قيمة سالبة لسحب الظل للداخل قليلاً لجعله أكثر نعومة
    offset: Offset(0, 8),
  );

  /// القوائم المنسدلة، النوافذ المنبثقة (Modals)، وعناصر الـ Overlays
  /// شفافية ~16% مع تمويه عالي جداً لرفع العنصر بوضوح عن الخلفية
  static const BoxShadow xl = BoxShadow(
    color: Color(0x29000000), 
    blurRadius: 32,
    spreadRadius: -4, 
    offset: Offset(0, 12),
  );
}