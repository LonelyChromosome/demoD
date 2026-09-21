import 'dart:convert';

import 'package:better_phenikaa_schedule/features/qldt_login/domain/qldt_page_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const values = <String, Object?>{
    'url': 'https://qldtbeta.phenikaa-uni.edu.vn/home?token=secret#user',
    'readyState': 'complete',
    'titleLength': 12,
    'hasBody': true,
    'bodyChildren': 4,
    'bodyTextLength': 40,
    'htmlLength': 1200,
    'scriptCount': 9,
    'viewportWidth': 360,
    'viewportHeight': 720,
    'documentWidth': 360,
    'documentHeight': 900,
    'devicePixelRatio': 2.75,
    'backgroundColor': 'rgb(255, 255, 255)',
    'visibilityState': 'visible',
    'hasEdu': true,
    'hasEduSystem': true,
    'hasUserId': true,
    'hasRequestFunction': true,
    'hasFlutterBridge': true,
  };

  test('parses Android JSON-string JavaScript results', () {
    final probe = QldtPageProbe.tryParse(jsonEncode(values));

    expect(probe, isNotNull);
    expect(probe!.qldtReady, isTrue);
    expect(probe.documentLoaded, isTrue);
    expect(probe.hasMeaningfulDom, isTrue);
    expect(probe.safeUrl, 'https://qldtbeta.phenikaa-uni.edu.vn/home');
  });

  test('parses double-encoded JavaScript results', () {
    final probe = QldtPageProbe.tryParse(jsonEncode(jsonEncode(values)));

    expect(probe, isNotNull);
    expect(probe!.viewportHeight, 720);
    expect(probe.devicePixelRatio, 2.75);
  });

  test('diagnostic report never contains query or fragment', () {
    final probe = QldtPageProbe.tryParse(values)!;
    final report = probe.buildReport(
      provider: 'com.google.android.webview 1.2.3',
      hybridComposition: false,
      consoleMessages: const <String>['ERROR:script failed'],
    );

    expect(report, contains('mode=compatibility'));
    expect(report, contains('url=https://qldtbeta.phenikaa-uni.edu.vn/home'));
    expect(report, isNot(contains('secret')));
    expect(report, isNot(contains('#user')));
  });

  test('sanitizes non-http navigation without retaining payload', () {
    expect(
      sanitizeQldtDiagnosticUrl('intent://login?token=secret#Intent;end'),
      'intent:<redacted>',
    );
  });

  test('rejects invalid JavaScript results', () {
    expect(QldtPageProbe.tryParse('not-json'), isNull);
    expect(QldtPageProbe.tryParse(true), isNull);
  });
}
