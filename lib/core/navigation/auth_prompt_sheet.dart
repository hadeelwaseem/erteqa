import 'package:flutter/material.dart';

import 'app_navigation.dart';
import 'auth_redirect.dart';

/// Modal bottom sheet prompting guests to sign in before auth-gated actions.
class AuthPromptSheet {
  AuthPromptSheet._();

  static const _title = 'تسجيل الدخول مطلوب';
  static const _body =
      'يجب تسجيل الدخول للوصول إلى هذه الميزة. سجّل دخولك للمتابعة.';
  static const _loginLabel = 'تسجيل الدخول';
  static const _cancelLabel = 'إلغاء';

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _title,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _body,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  AppNavigation.navigate(
                    context,
                    route: AuthRedirect.loginRoute,
                    type: NavigationType.push,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(_loginLabel),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text(_cancelLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}
