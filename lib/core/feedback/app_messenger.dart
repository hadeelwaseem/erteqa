// Use AppMessenger for transient user messages; do not use SnackBar.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';

enum AppMessageKind { error, success, info, warning }

class AppMessage {
  const AppMessage({
    required this.kind,
    required this.message,
    this.title,
    this.duration = const Duration(seconds: 4),
  });

  final AppMessageKind kind;
  final String message;
  final String? title;
  final Duration duration;
}

class _ResolvedMessageStyle {
  const _ResolvedMessageStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.borderRadius,
    this.defaultTitle,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final BorderRadius borderRadius;
  final String? defaultTitle;
}

/// Centralized top-of-screen transient messages (validation, auth, success/info).
class AppMessenger {
  AppMessenger._();

  static const _horizontalPadding = 16.0;
  static const _topGap = 8.0;
  static const _defaultDuration = Duration(seconds: 4);

  static OverlayEntry? _entry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    AppMessage message, {
    Map<String, dynamic>? dataContext,
  }) {
    final overlay = _resolveOverlay(context);
    if (overlay == null) {
      assert(() {
        debugPrint('[AppMessenger] No overlay found for context.');
        return false;
      }());
      return;
    }

    dismiss();

    final resolved = _resolveStyle(context, message.kind, dataContext: dataContext);
    final title = _effectiveTitle(message, resolved.defaultTitle);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return _AppMessageBanner(
          title: title,
          message: message.message,
          style: resolved,
          onDismiss: () {
            if (_entry == entry) {
              dismiss();
            }
          },
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(message.duration, dismiss);
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    Map<String, dynamic>? dataContext,
  }) {
    show(
      context,
      AppMessage(
        kind: AppMessageKind.error,
        message: message,
        title: title ?? 'خطأ',
        duration: duration ?? _defaultDuration,
      ),
      dataContext: dataContext,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    Map<String, dynamic>? dataContext,
  }) {
    show(
      context,
      AppMessage(
        kind: AppMessageKind.success,
        message: message,
        title: title ?? 'تم بنجاح',
        duration: duration ?? _defaultDuration,
      ),
      dataContext: dataContext,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    Map<String, dynamic>? dataContext,
  }) {
    show(
      context,
      AppMessage(
        kind: AppMessageKind.info,
        message: message,
        title: title,
        duration: duration ?? _defaultDuration,
      ),
      dataContext: dataContext,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    Map<String, dynamic>? dataContext,
  }) {
    show(
      context,
      AppMessage(
        kind: AppMessageKind.warning,
        message: message,
        title: title ?? 'تحذير',
        duration: duration ?? _defaultDuration,
      ),
      dataContext: dataContext,
    );
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _entry?.remove();
    _entry = null;
  }

  static OverlayState? _resolveOverlay(BuildContext context) {
    final rootOverlay =
        Navigator.maybeOf(context, rootNavigator: true)?.overlay;
    return rootOverlay ?? Overlay.maybeOf(context);
  }

  static String? _effectiveTitle(AppMessage message, String? defaultTitle) {
    final explicit = message.title?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    final fallback = defaultTitle?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    return null;
  }

  static _ResolvedMessageStyle _resolveStyle(
    BuildContext context,
    AppMessageKind kind, {
    Map<String, dynamic>? dataContext,
  }) {
    final theme = Theme.of(context);
    final engine = EngineTheme.fromDataContext(dataContext);

    final surface = engine?.surfaceColor ?? theme.colorScheme.surface;
    final text = engine?.textColor ?? theme.colorScheme.onSurface;
    final primary = engine?.primaryColor ?? theme.colorScheme.primary;
    final error = engine?.errorColor ?? theme.colorScheme.error;
    final radius = BorderRadius.circular(engine?.radiusMd ?? 10);

    switch (kind) {
      case AppMessageKind.error:
        return _ResolvedMessageStyle(
          backgroundColor: Color.alphaBlend(
            error.withValues(alpha: 0.08),
            surface,
          ),
          textColor: text,
          accentColor: error,
          borderRadius: radius,
          defaultTitle: 'خطأ',
        );
      case AppMessageKind.success:
        return _ResolvedMessageStyle(
          backgroundColor: surface,
          textColor: text,
          accentColor: primary,
          borderRadius: radius,
          defaultTitle: 'تم بنجاح',
        );
      case AppMessageKind.info:
        return _ResolvedMessageStyle(
          backgroundColor: surface,
          textColor: text,
          accentColor: engine?.mutedColor ?? theme.colorScheme.outline,
          borderRadius: radius,
        );
      case AppMessageKind.warning:
        const amber = Color(0xFFF59E0B);
        return _ResolvedMessageStyle(
          backgroundColor: Color.lerp(surface, amber, 0.15) ?? surface,
          textColor: text,
          accentColor: amber,
          borderRadius: radius,
          defaultTitle: 'تحذير',
        );
    }
  }
}

class _AppMessageBanner extends StatefulWidget {
  const _AppMessageBanner({
    required this.title,
    required this.message,
    required this.style,
    required this.onDismiss,
  });

  final String? title;
  final String message;
  final _ResolvedMessageStyle style;
  final VoidCallback onDismiss;

  @override
  State<_AppMessageBanner> createState() => _AppMessageBannerState();
}

class _AppMessageBannerState extends State<_AppMessageBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (!mounted) {
      return;
    }
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;

    return Positioned(
      top: topInset + AppMessenger._topGap,
      left: AppMessenger._horizontalPadding,
      right: AppMessenger._horizontalPadding,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _handleDismiss,
              behavior: HitTestBehavior.opaque,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.style.backgroundColor,
                  borderRadius: widget.style.borderRadius,
                  border: BorderDirectional(
                    start: BorderSide(
                      color: widget.style.accentColor,
                      width: 4,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: widget.title == null
                      ? Text(
                          widget.message,
                          style: textTheme.bodyMedium?.copyWith(
                            color: widget.style.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title!,
                              style: textTheme.titleSmall?.copyWith(
                                color: widget.style.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.message,
                              style: textTheme.bodyMedium?.copyWith(
                                color: widget.style.textColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
