import 'package:better_phenikaa_schedule/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into the login flow', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BetterPhenikaaScheduleApp()),
    );

    expect(find.text('Better Phenikaa App'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng bạn!'), findsOneWidget);
    expect(find.textContaining('Đăng nhập QLĐT'), findsOneWidget);
  });
}
