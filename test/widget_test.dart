import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo/theme/app_theme.dart';
import 'package:echo/widgets/offline_badge.dart';

void main() {
  testWidgets('AppTheme and OfflineBadge smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: OfflineBadge(),
          ),
        ),
      ),
    );

    expect(find.text('Offline Ready'), findsOneWidget);
    expect(AppColors.lightPrimary, const Color(0xFF123B46));
    expect(AppColors.lightTeal, const Color(0xFF159A8C));
  });
}
