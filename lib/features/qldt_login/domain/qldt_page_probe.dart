import 'dart:convert';

/// Privacy-safe facts collected from the currently loaded QLĐT page.
///
/// The probe deliberately records counts and dimensions instead of page text,
/// cookies, query parameters, or fragments. It can therefore be copied into a
/// bug report without exposing a student's session.
class QldtPageProbe {
  const QldtPageProbe({
    required this.url,
    required this.readyState,
    required this.titleLength,
    required this.hasBody,
    required this.bodyChildren,
    required this.bodyTextLength,
    required this.htmlLength,
    required this.scriptCount,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.documentWidth,
    required this.documentHeight,
    required this.devicePixelRatio,
    required this.backgroundColor,
    required this.visibilityState,
    required this.hasEdu,
    required this.hasEduSystem,
    required this.hasUserId,
    required this.hasRequestFunction,
    required this.hasFlutterBridge,
  });

  const QldtPageProbe.empty()
    : url = '',
      readyState = 'unknown',
      titleLength = -1,
      hasBody = false,
      bodyChildren = -1,
      bodyTextLength = -1,
      htmlLength = -1,
      scriptCount = -1,
      viewportWidth = -1,
      viewportHeight = -1,
      documentWidth = -1,
      documentHeight = -1,
      devicePixelRatio = -1,
      backgroundColor = 'unknown',
      visibilityState = 'unknown',
      hasEdu = false,
      hasEduSystem = false,
      hasUserId = false,
      hasRequestFunction = false,
      hasFlutterBridge = false;

  final String url;
  final String readyState;
  final int titleLength;
  final bool hasBody;
  final int bodyChildren;
  final int bodyTextLength;
  final int htmlLength;
  final int scriptCount;
  final int viewportWidth;
  final int viewportHeight;
  final int documentWidth;
  final int documentHeight;
  final double devicePixelRatio;
  final String backgroundColor;
  final String visibilityState;
  final bool hasEdu;
  final bool hasEduSystem;
  final bool hasUserId;
  final bool hasRequestFunction;
  final bool hasFlutterBridge;

  bool get qldtReady => hasEduSystem && hasUserId && hasRequestFunction;

  bool get documentLoaded =>
      readyState == 'interactive' || readyState == 'complete';

  bool get hasMeaningfulDom =>
      hasBody && (bodyChildren > 0 || bodyTextLength > 0 || htmlLength > 100);

  String get safeUrl => sanitizeQldtDiagnosticUrl(url);

  /// Android returns JavaScript values in slightly different shapes across
  /// WebView versions. Accept both a map and one/two layers of JSON strings.
  static QldtPageProbe? tryParse(Object? value) {
    Object? decoded = value;
    for (var index = 0; index < 2 && decoded is String; index += 1) {
      try {
        decoded = jsonDecode(decoded);
      } on FormatException {
        return null;
      }
    }
    if (decoded is! Map) {
      return null;
    }

    final map = Map<String, Object?>.from(decoded);
    return QldtPageProbe(
      url: _string(map['url']),
      readyState: _string(map['readyState'], fallback: 'unknown'),
      titleLength: _integer(map['titleLength']),
      hasBody: _boolean(map['hasBody']),
      bodyChildren: _integer(map['bodyChildren']),
      bodyTextLength: _integer(map['bodyTextLength']),
      htmlLength: _integer(map['htmlLength']),
      scriptCount: _integer(map['scriptCount']),
      viewportWidth: _integer(map['viewportWidth']),
      viewportHeight: _integer(map['viewportHeight']),
      documentWidth: _integer(map['documentWidth']),
      documentHeight: _integer(map['documentHeight']),
      devicePixelRatio: _number(map['devicePixelRatio']),
      backgroundColor: _string(map['backgroundColor'], fallback: 'unknown'),
      visibilityState: _string(map['visibilityState'], fallback: 'unknown'),
      hasEdu: _boolean(map['hasEdu']),
      hasEduSystem: _boolean(map['hasEduSystem']),
      hasUserId: _boolean(map['hasUserId']),
      hasRequestFunction: _boolean(map['hasRequestFunction']),
      hasFlutterBridge: _boolean(map['hasFlutterBridge']),
    );
  }

  String buildReport({
    required String provider,
    required bool hybridComposition,
    required Iterable<String> consoleMessages,
  }) {
    final messages = consoleMessages.isEmpty
        ? 'none'
        : consoleMessages.join(' | ');
    return <String>[
      'Better Phenikaa WebView diagnostic v1',
      'mode=${hybridComposition ? 'hybrid' : 'compatibility'}',
      'provider=$provider',
      'url=$safeUrl',
      'document=$readyState visibility=$visibilityState '
          'titleLength=$titleLength',
      'dom=body:$hasBody children:$bodyChildren text:$bodyTextLength '
          'html:$htmlLength scripts:$scriptCount',
      'viewport=${viewportWidth}x$viewportHeight@$devicePixelRatio '
          'document=${documentWidth}x$documentHeight '
          'background=$backgroundColor',
      'bridge=flutter:$hasFlutterBridge edu:$hasEdu '
          'system:$hasEduSystem user:$hasUserId request:$hasRequestFunction',
      'console=$messages',
    ].join('\n');
  }

  static String _string(Object? value, {String fallback = ''}) {
    return value is String ? value : fallback;
  }

  static int _integer(Object? value) {
    return value is num ? value.round() : -1;
  }

  static double _number(Object? value) {
    return value is num ? value.toDouble() : -1;
  }

  static bool _boolean(Object? value) {
    return value == true;
  }
}

String sanitizeQldtDiagnosticUrl(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null) {
    return '<invalid-url>';
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return uri.scheme.isEmpty ? '<relative-url>' : '${uri.scheme}:<redacted>';
  }
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
  ).toString();
}
