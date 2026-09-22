import 'dart:async';

import 'package:better_phenikaa_schedule/features/qldt_login/data/qldt_parser.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:flutter/material.dart';
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
  int _webViewGeneration = 0;
  int _readinessCycle = 0;
  int _readinessAttempt = 0;
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
                : InAppWebView(
                    key: ValueKey<int>(_webViewGeneration),
                    initialUrlRequest: URLRequest(url: _qldtUri),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      databaseEnabled: true,
                      thirdPartyCookiesEnabled: true,
                      useHybridComposition: true,
                      useOnRenderProcessGone: true,
                      useShouldOverrideUrlLoading: false,
                    ),
                    onWebViewCreated: _onWebViewCreated,
                    onLoadStart: (_, url) {
                      _trace('load-start', url?.toString());
                      _readinessTimer?.cancel();
                      _readinessCycle += 1;
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
                    onReceivedError: (_, request, error) {
                      if (request.isForMainFrame == true) {
                        _trace(
                          'main-frame-error:${error.type}:${error.description}',
                          request.url.toString(),
                        );
                        _showLoadFailure(
                          'Không tải được trang đăng nhập: ${error.description}',
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
      _trace(
        'provider:${provider?.packageName ?? 'unknown'}:'
        '${provider?.versionName ?? 'unknown'}',
        null,
      );
    } on Object catch (error) {
      _trace('provider-error:$error', null);
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
          Boolean(
            window.edu && edu.system && edu.system.userId &&
            edu.system.iM != null && typeof edu.system.makeRequest === 'function'
          );
        ''',
      );
      final ready = result == true || result?.toString() == 'true';
      if (!mounted || cycle != _readinessCycle) {
        return;
      }

      setState(() {
        _pageReady = ready;
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
          _status =
              'Trang đã tải nhưng phiên QLĐT chưa sẵn sàng. '
              'Hãy hoàn tất đăng nhập hoặc tải lại.';
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
      '${url == null ? '' : ' url=${_safeUrl(url)}'}',
    );
  }

  static String _safeUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      return '<invalid-url>';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return uri.scheme.isEmpty
          ? '<relative-url>'
          : '${uri.scheme}:${uri.path}';
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    ).toString();
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
