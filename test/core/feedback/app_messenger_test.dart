import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/models/mobile_theme_config.dart';
import 'package:sooq_merchant/core/feedback/app_messenger.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';

void main() {
  tearDown(AppMessenger.dismiss);

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    return hostContext;
  }

  testWidgets('showError displays title and message', (tester) async {
    final context = await pumpHost(tester);
    AppMessenger.showError(context, 'Validation failed');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('خطأ'), findsOneWidget);
    expect(find.text('Validation failed'), findsOneWidget);
    AppMessenger.dismiss();
  });

  testWidgets('second show replaces first message', (tester) async {
    final context = await pumpHost(tester);
    AppMessenger.showError(context, 'First');
    await tester.pump();
    AppMessenger.showError(context, 'Second');
    await tester.pump();

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    AppMessenger.dismiss();
  });

  testWidgets('dismiss removes active overlay', (tester) async {
    final context = await pumpHost(tester);
    AppMessenger.showError(context, 'Temporary');
    await tester.pump();
    AppMessenger.dismiss();
    await tester.pump();

    expect(find.text('Temporary'), findsNothing);
  });

  testWidgets('showInfo can be message-only without title', (tester) async {
    final context = await pumpHost(tester);
    AppMessenger.showInfo(
      context,
      'OTP sent',
      dataContext: {
        EngineTheme.contextKey: EngineTheme.fromConfig(
          MobileThemeConfig.defaults(),
        ),
      },
    );
    await tester.pump();

    expect(find.text('OTP sent'), findsOneWidget);
    expect(find.text('خطأ'), findsNothing);
    expect(find.text('تم بنجاح'), findsNothing);
    AppMessenger.dismiss();
  });
}
