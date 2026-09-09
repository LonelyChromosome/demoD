// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'package:better_phenikaa_schedule/features/qldt_intake/qldt_models.dart';
import 'package:flutter/material.dart';

const bool supportsLiveQldtLogin = true;

Future<ImportedScheduleData?> openQldtLogin(BuildContext context) {
  return showDialog<ImportedScheduleData>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WebQldtBridgeDialog(),
  );
}

class _WebQldtBridgeDialog extends StatefulWidget {
  const new();

  @override
  State<_WebQldtBridgeDialog> createState() => _WebQldtBridgeDialogState();
}

class _WebQldtBridgeDialogState extends State<_WebQldtBridgeDialog> {
  static const _requestEvent = 'better-phenikaa-request-qldt';
  static const _resultEvent = 'better-phenikaa-qldt-result';
  static const _errorEvent = 'better-phenikaa-qldt-error';

  bool _syncing = false;
  String _status = '';

  bool get _bridgeReady =>
      html.document.documentElement?.dataset['betterPhenikaaBridge'] == 'ready';

  @override
  void initState() {
    super.initState();
    html.window.addEventListener(_resultEvent, _onResult);
    html.window.addEventListener(_errorEvent, _onError);
  }

  @override
  void dispose() {
    html.window.removeEventListener(_resultEvent, _onResult);
    html.window.removeEventListener(_errorEvent, _onError);
    super.dispose();
  }

  void _openQldt() {
    html.window.open('https://qldt.phenikaa-uni.edu.vn/', 'betterPhenikaaQldt');
    setState(() {
      _status = 'Đăng nhập Microsoft trên tab QLĐT chính thức. Giữ tab đó mở rồi quay lại đây.';
    });
  }

  void _requestSync() {
    if (!_bridgeReady) {
      setState(() {
        _status = 'Chưa phát hiện Better Phenikaa Web Bridge. Hãy bật tiện ích cầu nối rồi tải lại trang.';
      });
      return;
    }

    final now = DateTime.now();
    final academicStartYear = now.month >= 8 ? now.year : now.year - 1;
    final start = DateTime(academicStartYear, 8);
    final end = DateTime(academicStartYear + 1, 7, 31);
    final payload = jsonEncode(<String, String>{
      'start': _formatDate(start),
      'end': _formatDate(end),
    });

    setState(() {
      _syncing = true;
      _status = 'Đang đọc lịch từ tab QLĐT đã đăng nhập...';
    });
    html.window.dispatchEvent(html.CustomEvent(_requestEvent, detail: payload));
  }

  void _onResult(html.Event event) {
    if (event is! html.CustomEvent) {
      return;
    }
    try {
      final raw = event.detail?.toString() ?? '';
      final response = jsonDecode(raw) as Map<String, dynamic>;
      final envelope = response['envelope'] as String? ?? '';
      if (envelope.isEmpty) {
        throw const FormatException('Web bridge returned an empty envelope.');
      }
      final data = const QldtParser().parseLiveEnvelope(envelope);
      if (mounted) {
        Navigator.of(context).pop(data);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _syncing = false;
          _status = 'Không đọc được dữ liệu QLĐT: $error';
        });
      }
    }
  }

  void _onError(html.Event event) {
    if (event is! html.CustomEvent || !mounted) {
      return;
    }
    var message = 'Không thể kết nối QLĐT.';
    try {
      final raw = event.detail?.toString() ?? '';
      final response = jsonDecode(raw) as Map<String, dynamic>;
      message = response['message'] as String? ?? message;
    } on Object {
      // Keep the safe fallback message.
    }
    setState(() {
      _syncing = false;
      _status = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bridgeReady = _bridgeReady;
    return AlertDialog(
      title: const Row(
        children: <Widget>[
          Icon(Icons.verified_user_outlined, color: Color(0xFF1747B5)),
          SizedBox(width: 10),
          Expanded(child: Text('Kết nối QLĐT trên web')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              bridgeReady
                  ? 'Web Bridge đã sẵn sàng. Mật khẩu chỉ được nhập trên trang Microsoft/QLĐT chính thức.'
                  : 'GitHub Pages bị giới hạn bởi same-origin/CORS. Bản web dùng một tiện ích cầu nối cục bộ để đọc đúng tab QLĐT bạn đã đăng nhập, không gửi mật khẩu qua server trung gian.',
              style: const TextStyle(height: 1.45),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bridgeReady
                    ? const Color(0xFFEAF8F1)
                    : const Color(0xFFFFF5E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    bridgeReady
                        ? Icons.check_circle_outline_rounded
                        : Icons.extension_off_outlined,
                    color: bridgeReady
                        ? const Color(0xFF16875B)
                        : const Color(0xFFB36B00),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bridgeReady ? 'Better Phenikaa Web Bridge: đã bật' : 'Chưa phát hiện Web Bridge. Nạp thư mục tools/web_qldt_bridge dưới dạng Chrome extension rồi tải lại trang.',
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            if (_status.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                _status,
                style: const TextStyle(
                  color: Color(0xFF4F628B),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _syncing ? null : () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        OutlinedButton.icon(
          onPressed: _syncing ? null : _openQldt,
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Mở QLĐT'),
        ),
        FilledButton.icon(
          onPressed: bridgeReady && !_syncing ? _requestSync : null,
          icon: _syncing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sync_rounded),
          label: Text(_syncing ? 'Đang đồng bộ' : 'Đã đăng nhập · Đồng bộ'),
        ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
