import 'package:better_phenikaa_schedule/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots into the login flow and opens the demo', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      const ProviderScope(child: BetterPhenikaaScheduleApp()),
    );

    expect(find.text('Better Phenikaa App'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng bạn!'), findsOneWidget);
    expect(find.text('Xem bản demo từ mockup'), findsOneWidget);

    await tester.tap(find.text('Xem bản demo từ mockup'));
    await tester.pumpAndSettle();

    expect(find.text('Lịch học'), findsOneWidget);
    expect(find.text('Thiết kế web nâng cao'), findsOneWidget);
  });
}
