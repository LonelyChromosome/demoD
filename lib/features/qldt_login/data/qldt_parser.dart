import 'dart:convert';

import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:html/parser.dart' as html_parser;

/// Converts QLĐT responses into the app's normalized sync snapshot.
final class QldtParser {
  const new();

  String parseDisplayName(String html) {
    final document = html_parser.parse(html);
    final preferred = document.querySelector('#lblHoTenNguoiDangNhap');
    final preferredText = preferred?.text.trim() ?? '';
    if (preferredText.isNotEmpty) {
      return preferredText;
    }

    final accountSpans = document.querySelectorAll(
      '.nav-account button > span',
    );
    for (final span in accountSpans) {
      final text = span.text.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  ScheduleSnapshot parseLiveEnvelope(String envelopeJson) {
    final envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
    final displayName = (envelope['name'] as String? ?? '').trim();
    final response = envelope['response'];
    if (response is! Map) {
      throw const FormatException('QLĐT response is not an object.');
    }
    return parseApiResponse(
      Map<String, dynamic>.from(response),
      displayName: displayName,
    );
  }

  ScheduleSnapshot parseApiResponse(
    Map<String, dynamic> response, {
    required String displayName,
  }) {
    if (response['Success'] != true) {
      throw const FormatException('QLĐT returned Success != true.');
    }
    final rawData = response['Data'];
    if (rawData is! List) {
      throw const FormatException('QLĐT Data is not a list.');
    }

    final recordsById = <String, ScheduleRecord>{};
    for (final rawItem in rawData) {
      if (rawItem is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(rawItem);
      final record = _parseRecord(item);
      if (record != null) {
        recordsById[record.id] = record;
      }
    }

    if (rawData.isNotEmpty && recordsById.isEmpty) {
      throw const FormatException('Không có bản ghi QLĐT hợp lệ.');
    }

    final records = recordsById.values.toList(growable: false);
    records.sort((a, b) => a.startAt.compareTo(b.startAt));
    return ScheduleSnapshot(
      displayName: displayName,
      records: records,
      syncedAt: DateTime.now(),
    );
  }

  ScheduleRecord? _parseRecord(Map<String, dynamic> item) {
    final subjectName = _string(item['TENHOCPHAN']);
    final dateText = _string(item['NGAYHOC']);
    if (subjectName.isEmpty || dateText.isEmpty) {
      return null;
    }

    final day = _parseVietnameseDate(dateText);
    if (day == null) {
      return null;
    }

    final startHour = _int(item['GIOBATDAU']);
    final startMinute = _int(item['PHUTBATDAU']);
    final endHour = _int(item['GIOKETTHUC']);
    final endMinute = _int(item['PHUTKETTHUC']);
    if (startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null ||
        startHour < 0 ||
        startHour > 23 ||
        endHour < 0 ||
        endHour > 23 ||
        startMinute < 0 ||
        startMinute > 59 ||
        endMinute < 0 ||
        endMinute > 59) {
      return null;
    }

    final isExam = _string(item['PHANLOAI']).toUpperCase() == 'LICHTHI';
    final room = isExam
        ? _firstNonEmpty(<Object?>[item['PHONGHOC_TEN'], item['PHONGTHI']])
        : _firstNonEmpty(<Object?>[item['PHONGHOC_TEN'], item['TENPHONGHOC']]);
    final startAt = DateTime(
      day.year,
      day.month,
      day.day,
      startHour,
      startMinute,
    );
    final endAt = DateTime(day.year, day.month, day.day, endHour, endMinute);
    if (!endAt.isAfter(startAt)) {
      return null;
    }

    return ScheduleRecord(
      id: <String>[
        if (isExam) 'exam' else 'class',
        dateText,
        subjectName,
        '$startHour:$startMinute',
        room,
      ].join('|'),
      isExam: isExam,
      subjectName: subjectName,
      room: room,
      startAt: startAt,
      endAt: endAt,
      className: _string(item['TENLOPHOCPHAN']),
      examForm: _string(item['DANGKY_LOPHOCPHAN_TEN']),
      periodStart: _int(item['TIETBATDAU']),
      periodEnd: _int(item['TIETKETTHUC']),
    );
  }

  static DateTime? _parseVietnameseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _string(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static int? _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
