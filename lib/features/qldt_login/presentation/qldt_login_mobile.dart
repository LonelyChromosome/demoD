import 'dart:async';

import 'package:better_phenikaa_schedule/features/qldt_login/data/qldt_parser.dart';
import 'package:better_phenikaa_schedule/features/qldt_login/domain/qldt_page_probe.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const bool supportsLiveQldtLogin = true;

Future<void> clearQldtSession() async {
  await CookieManager.instance().deleteAllCookies();
}

Future<ScheduleSnapshot?> openQldtLogin(BuildContext context) {
  return Navigator.of(context).push<ScheduleSnapshot>(
    MaterialPageRoute<ScheduleSnapshot>(
      fullscreenDialog: true,
      builder: (_) => const _QldtWebLoginScreen(),
    ),
  );
}

class _QldtWebLoginScreen extends StatefulWidget {
  const new();

  @override
  State<_QldtWebLoginScreen> createState() => _QldtWebLoginScreenState();
}

class _QldtWebLoginScreenState extends State<_QldtWebLoginScreen> {
  static final WebUri _qldtUri = WebUri(
    'https://qldtbeta.phenikaa-uni.edu.vn/',
  );

  InAppWebViewController? _controller;
  Timer? _readinessTimer;
  bool _pageReady = false;
  bool _syncing = false;
  bool _autoSyncStarted = false;
  bool _rendererGone = false;
  bool _readinessTimedOut = false;
  bool _hybridComposition = true;
  int _webViewGeneration = 0;
  int _readinessCycle = 0;
  int _readinessAttempt = 0;
  QldtPageProbe _lastProbe = QldtPageProbe.empty;
  String _webViewProvider = 'đang xác định';
  final List<String> _consoleMessages = <String>[];
  String _status = 'Đăng nhập bằng tài khoản Microsoft của bạn.';

  @override
  void initState() {
    super.initState();
    unawaited(_logWebViewProvider());
  }

  @override
  void dispose() {
    _readinessTimer?.cancel();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập QLĐT'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Material(
            color: const Color(0xFFF2F6FF),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: <Widget>[
                  Icon(
                    _pageReady
                        ? Icons.verified_user_outlined
                        : Icons.info_outline,
                    color: const Color(0xFF1747B5),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _status,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_syncing) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: _rendererGone
                ? _RendererRecovery(onReload: _reload)
                : ColoredBox(
                    color: Colors.white,
                    child: InAppWebView(
                      key: ValueKey<int>(_webViewGeneration),
                      initialUrlRequest: URLRequest(url: _qldtUri),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        databaseEnabled: true,
                        thirdPartyCookiesEnabled: true,
                        transparentBackground: false,
                        underPageBackgroundColor: Colors.white,
                        forceDark: ForceDark.OFF,
                        algorithmicDarkeningAllowed: false,
                        hardwareAcceleration: true,
                        useHybridComposition: _hybridComposition,
                        useOnRenderProcessGone: true,
                        useShouldOverrideUrlLoading: false,
                      ),
                      onWebViewCreated: _onWebViewCreated,
                      onLoadStart: (_, url) {
                        _trace('load-start', url?.toString());
                        _readinessTimer?.cancel();
                        _readinessCycle += 1;
                        if (mounted) {
                          setState(() {
                            _readinessTimedOut = false;
                            _pageReady = false;
                            _status = 'Đang tải trang đăng nhập QLĐT...';
                          });
                        }
                      },
                      onPageCommitVisible: (_, url) =>
                          _trace('page-visible', url?.toString()),
                      onLoadStop: (_, url) {
                        _trace('load-stop', url?.toString());
                        _beginReadinessChecks();
                      },
                      onUpdateVisitedHistory: (_, url, isReload) => _trace(
                        'history${isReload == true ? '-reload' : ''}',
                        url?.toString(),
                      ),
                      onConsoleMessage: (_, message) =>
                          _recordConsoleMessage(message),
                      onReceivedError: (_, request, error) {
                        if (request.isForMainFrame == true) {
                          _trace(
                            'main-frame-error:'
                            '${error.type}:${error.description}',
                            request.url.toString(),
                          );
                          _showLoadFailure(
                            'Không tải được trang đăng nhập: '
                            '${error.description}',
                          );
                        }
                      },
                      onReceivedHttpError: (_, request, response) {
                        if (request.isForMainFrame == true) {
                          _trace(
                            'main-frame-http:${response.statusCode}',
                            request.url.toString(),
                          );
                          _showLoadFailure(
                            'QLĐT trả lỗi HTTP ${response.statusCode}.',
                          );
                        }
                      },
                      onRenderProcessGone: (_, detail) {
                        _trace(
                          'renderer-gone:crash=${detail.didCrash}:'
                          'priority=${detail.rendererPriorityAtExit}',
                          null,
                        );
                        _readinessTimer?.cancel();
                        _controller = null;
                        if (mounted) {
                          setState(() {
                            _rendererGone = true;
                            _pageReady = false;
                            _syncing = false;
                            _status = detail.didCrash
                                ? 'Tiến trình hiển thị WebView đã bị lỗi.'
                                : 'Tiến trình hiển thị WebView đã bị hệ thống dừng.';
                          });
                        }
                      },
                    ),
                  ),
          ),
          if (_readinessTimedOut && !_syncing)
            _WebViewDiagnosticActions(
              url: _lastProbe.safeUrl,
              compatibilityMode: !_hybridComposition,
              onCopy: _copyDiagnostic,
              onSwitchMode: _switchCompositionMode,
            ),
          if (_pageReady && !_syncing && _autoSyncStarted)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _sync,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử đồng bộ lại'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    _trace('created', null);
    controller.addJavaScriptHandler(
      handlerName: 'betterPhenikaaSyncResult',
      callback: (arguments) async {
        if (!mounted || arguments.isEmpty) {
          return null;
        }
        try {
          final raw = arguments.first?.toString() ?? '';
          final data = const QldtParser().parseLiveEnvelope(raw);
          if (!mounted) {
            return null;
          }
          Navigator.of(context).pop(data);
        } on Object catch (error) {
          if (mounted) {
            setState(() {
              _syncing = false;
              _status = 'Không đọc được dữ liệu QLĐT: $error';
            });
          }
        }
        return null;
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'betterPhenikaaSyncError',
      callback: (arguments) {
        if (mounted) {
          setState(() {
            _syncing = false;
            _status = arguments.isEmpty
                ? 'QLĐT không trả dữ liệu.'
                : arguments.first.toString();
          });
        }
        return null;
      },
    );
  }

  Future<void> _logWebViewProvider() async {
    try {
      final provider = await InAppWebViewController.getCurrentWebViewPackage();
      final description =
          '${provider?.packageName ?? 'unknown'} '
          '${provider?.versionName ?? 'unknown'}';
      _trace(
        'provider:${provider?.packageName ?? 'unknown'}:'
        '${provider?.versionName ?? 'unknown'}',
        null,
      );
      if (mounted) {
        setState(() => _webViewProvider = description);
      }
    } on Object catch (error) {
      _trace('provider-error:$error', null);
      if (mounted) {
        setState(() => _webViewProvider = 'không xác định');
      }
    }
  }

  void _beginReadinessChecks() {
    _readinessTimer?.cancel();
    _readinessAttempt = 0;
    final cycle = ++_readinessCycle;
    unawaited(_checkReady(cycle));
  }

  Future<void> _checkReady(int cycle) async {
    final controller = _controller;
    if (controller == null || cycle != _readinessCycle) {
      return;
    }
    try {
      final result = await controller.evaluateJavascript(
        source: '''
          (function () {
            var body = document.body;
            var root = document.documentElement;
            var styleTarget = body || root;
            var style = styleTarget ? window.getComputedStyle(styleTarget) : null;
            var eduValue = window.edu;
            var system = eduValue && eduValue.system;
            return JSON.stringify({
              url: String(window.location.href || ''),
              readyState: String(document.readyState || 'unknown'),
              titleLength: String(document.title || '').length,
              hasBody: Boolean(body),
              bodyChildren: body ? body.childElementCount : -1,
              bodyTextLength: body
                ? String(body.innerText || '').trim().length
                : -1,
              htmlLength: root ? String(root.outerHTML || '').length : -1,
              scriptCount: document.scripts ? document.scripts.length : -1,
              viewportWidth: Math.round(window.innerWidth || 0),
              viewportHeight: Math.round(window.innerHeight || 0),
              documentWidth: root
                ? Math.max(root.scrollWidth || 0, root.clientWidth || 0)
                : -1,
              documentHeight: root
                ? Math.max(root.scrollHeight || 0, root.clientHeight || 0)
                : -1,
              devicePixelRatio: Number(window.devicePixelRatio || 1),
              backgroundColor: style
                ? String(style.backgroundColor || 'unknown')
                : 'unknown',
              visibilityState: String(document.visibilityState || 'unknown'),
              hasEdu: Boolean(eduValue),
              hasEduSystem: Boolean(system),
              hasUserId: Boolean(system && system.userId),
              hasRequestFunction: Boolean(
                system && typeof system.makeRequest === 'function'
              ),
              hasFlutterBridge: Boolean(window.flutter_inappwebview)
            });
          })();
        ''',
      );
      final probe = QldtPageProbe.tryParse(result);
      final ready = probe?.qldtReady ?? false;
      if (!mounted || cycle != _readinessCycle) {
        return;
      }

      setState(() {
        if (probe != null) {
          _lastProbe = probe;
        }
        _pageReady = ready;
        _readinessTimedOut = false;
        _status = ready
            ? 'Đã nhận phiên QLĐT. App đang tự lấy lịch và sẽ quay lại ngay khi hoàn tất.'
            : 'Hoàn tất đăng nhập Microsoft; app sẽ tự đồng bộ khi QLĐT sẵn sàng.';
      });

      if (ready && !_autoSyncStarted && !_syncing) {
        _readinessTimer?.cancel();
        _autoSyncStarted = true;
        await _sync();
      } else if (!ready && _readinessAttempt < 24) {
        _readinessAttempt += 1;
        _readinessTimer = Timer(
          const Duration(milliseconds: 500),
          () => unawaited(_checkReady(cycle)),
        );
      } else if (!ready) {
        _trace('readiness-timeout', null);
        setState(() {
          _readinessTimedOut = true;
          _status = _lastProbe.documentLoaded && _lastProbe.hasMeaningfulDom
              ? 'Trang đã tải nhưng chưa thấy phiên QLĐT. Nếu màn hình đang đen, '
                    'hãy thử chế độ tương thích bên dưới.'
              : 'WebView chưa dựng được nội dung đăng nhập. Hãy thử chế độ '
                    'tương thích bên dưới.';
        });
      }
    } on Object catch (error) {
      _trace('readiness-error:$error', null);
      if (mounted) {
        setState(() => _pageReady = false);
      }
    }
  }

  void _reload() {
    _readinessTimer?.cancel();
    _readinessCycle += 1;
    if (_rendererGone) {
      setState(() {
        _rendererGone = false;
        _webViewGeneration += 1;
        _pageReady = false;
        _syncing = false;
        _autoSyncStarted = false;
        _readinessTimedOut = false;
        _status = 'Đang tải lại trang đăng nhập QLĐT...';
      });
      return;
    }
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.reload());
    }
  }

  void _showLoadFailure(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _pageReady = false;
      _syncing = false;
      _status = message;
    });
  }

  void _trace(String event, String? url) {
    debugPrint(
      '[QLDT-WebView] ${DateTime.now().toIso8601String()} $event'
      '${url == null ? '' : ' url=${sanitizeQldtDiagnosticUrl(url)}'}',
    );
  }

  void _recordConsoleMessage(ConsoleMessage message) {
    final level = message.messageLevel.toString();
    if (level != 'ERROR' && level != 'WARNING') {
      return;
    }
    final safeMessage = _sanitizeConsoleMessage(message.message);
    if (_consoleMessages.length == 4) {
      _consoleMessages.removeAt(0);
    }
    _consoleMessages.add('$level:$safeMessage');
    _trace('console-$level:$safeMessage', null);
  }

  static String _sanitizeConsoleMessage(String raw) {
    var value = raw.replaceAllMapped(
      RegExp(r'''https?://[^\s"']+'''),
      (match) => sanitizeQldtDiagnosticUrl(match.group(0) ?? ''),
    );
    value = value.replaceAll(
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
      '<email>',
    );
    value = value.replaceAll(RegExp(r'\b[A-Za-z0-9_-]{24,}\b'), '<redacted>');
    value = value.replaceAll(RegExp(r'\b\d{7,}\b'), '<number>');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return value.length <= 180 ? value : '${value.substring(0, 177)}...';
  }

  Future<void> _copyDiagnostic() async {
    final report = _lastProbe.buildReport(
      provider: _webViewProvider,
      hybridComposition: _hybridComposition,
      consoleMessages: _consoleMessages,
    );
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép chẩn đoán an toàn. Gửi đoạn này cho dev.'),
      ),
    );
  }

  void _switchCompositionMode() {
    _readinessTimer?.cancel();
    _readinessCycle += 1;
    _controller = null;
    setState(() {
      _hybridComposition = !_hybridComposition;
      _webViewGeneration += 1;
      _rendererGone = false;
      _pageReady = false;
      _syncing = false;
      _autoSyncStarted = false;
      _readinessTimedOut = false;
      _lastProbe = QldtPageProbe.empty;
      _consoleMessages.clear();
      _status = _hybridComposition
          ? 'Đang tải lại bằng chế độ hiển thị chuẩn...'
          : 'Đang tải lại bằng chế độ tương thích màn hình đen...';
    });
  }

  Future<void> _sync() async {
    final controller = _controller;
    if (controller == null || _syncing) {
      return;
    }
    setState(() {
      _syncing = true;
      _status = 'Đang lấy lịch cá nhân từ QLĐT...';
    });

    final now = DateTime.now();
    final academicStartYear = now.month >= 8 ? now.year : now.year - 1;
    final start = DateTime(academicStartYear, 8);
    final end = DateTime(academicStartYear + 1, 7, 31);
    final startText = _formatDate(start);
    final endText = _formatDate(end);

    final script =
        '''
      (function () {
        try {
          if (!(window.edu && edu.system && edu.system.userId &&
                edu.system.iM != null && typeof edu.system.makeRequest === 'function')) {
            window.flutter_inappwebview.callHandler(
              'betterPhenikaaSyncError',
              'Phiên QLĐT chưa sẵn sàng.'
            );
            return;
          }

          var requestData = {
            action: 'SV_ThongTin_MH/DSA4BRINKCIpAiAPKSAv',
            func: 'pkg_congthongtin_hssv_thongtin.LayDSLichCaNhan',
            iM: edu.system.iM,
            strQLSV_NguoiHoc_Id: edu.system.userId,
            strNgayBatDau: '$startText',
            strNgayKetThuc: '$endText'
          };

          edu.system.makeRequest({
            success: function (response) {
              var nameNode = document.querySelector('#lblHoTenNguoiDangNhap');
              var name = nameNode ? (nameNode.textContent || '').trim() : '';
              if (!name) {
                var spans = document.querySelectorAll('.nav-account button > span');
                for (var i = 0; i < spans.length; i++) {
                  var candidate = (spans[i].textContent || '').trim();
                  if (candidate) {
                    name = candidate;
                    break;
                  }
                }
              }
              window.flutter_inappwebview.callHandler(
                'betterPhenikaaSyncResult',
                JSON.stringify({name: name, response: response})
              );
            },
            error: function () {
              window.flutter_inappwebview.callHandler(
                'betterPhenikaaSyncError',
                'QLĐT báo lỗi khi tải lịch cá nhân.'
              );
            },
            type: 'POST',
            action: requestData.action,
            contentType: true,
            data: requestData,
            fakedb: []
          }, false, false, false, null);
        } catch (error) {
          window.flutter_inappwebview.callHandler(
            'betterPhenikaaSyncError',
            'Lỗi JavaScript: ' + error
          );
        }
      })();
    ''';

    try {
      await controller.evaluateJavascript(source: script);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _syncing = false;
          _status = 'Không thể yêu cầu QLĐT: $error';
        });
      }
    }
  }

  static String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }
}

class _WebViewDiagnosticActions extends StatelessWidget {
  const new({
    required this.url,
    required this.compatibilityMode,
    required this.onCopy,
    required this.onSwitchMode,
  });

  final String url;
  final bool compatibilityMode;
  final VoidCallback onCopy;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: const Color(0xFFFFF8E8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '${compatibilityMode ? 'Tương thích' : 'Chuẩn'} • $url',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onSwitchMode,
                icon: const Icon(Icons.layers_outlined, size: 18),
                label: Text(
                  compatibilityMode
                      ? 'Dùng lại chế độ hiển thị chuẩn'
                      : 'Thử chế độ tương thích màn hình đen',
                ),
              ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                label: const Text('Sao chép chẩn đoán'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RendererRecovery extends StatelessWidget {
  const new({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.web_asset_off_outlined,
              size: 48,
              color: Color(0xFF607095),
            ),
            const SizedBox(height: 14),
            const Text(
              'WebView đã dừng hiển thị',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}
