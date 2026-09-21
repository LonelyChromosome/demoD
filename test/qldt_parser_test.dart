import 'package:better_phenikaa_schedule/features/qldt_login/data/qldt_parser.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = QldtParser();

  test('extracts the display name from the QLĐT account element', () {
    const html = '''
      <div class="nav-account">
        <span id="lblHoTenNguoiDangNhap">Nguyễn Minh Đạo</span>
      </div>
    ''';

    expect(parser.parseDisplayName(html), 'Nguyễn Minh Đạo');
  });

  test('separates study schedule and exam schedule using PHANLOAI', () {
    final parsed = parser.parseApiResponse(<String, dynamic>{
      'Success': true,
      'Data': <Map<String, dynamic>>[
        <String, dynamic>{
          'PHANLOAI': 'LICHHOC',
          'NGAYHOC': '26/08/2026',
          'TENHOCPHAN': 'Thiết kế web nâng cao',
          'PHONGHOC_TEN': 'A6-101',
          'GIOBATDAU': 6,
          'PHUTBATDAU': 45,
          'GIOKETTHUC': 9,
          'PHUTKETTHUC': 25,
        },
        <String, dynamic>{
          'PHANLOAI': 'LICHTHI',
          'NGAYHOC': '26/08/2026',
          'TENHOCPHAN': 'Lập trình C++',
          'PHONGTHI': 'A6-201',
          'GIOBATDAU': 7,
          'PHUTBATDAU': 30,
          'GIOKETTHUC': 9,
          'PHUTKETTHUC': 0,
        },
      ],
    }, displayName: 'Nguyễn Minh Đạo');

    expect(parsed.displayName, 'Nguyễn Minh Đạo');
    expect(parsed.classes, hasLength(1));
    expect(parsed.exams, hasLength(1));
    expect(parsed.classes.single.subjectName, 'Thiết kế web nâng cao');
    expect(parsed.exams.single.room, 'A6-201');
  });

  test('deduplicates identical QLĐT records by normalized id', () {
    final item = <String, dynamic>{
      'PHANLOAI': 'LICHHOC',
      'NGAYHOC': '26/08/2026',
      'TENHOCPHAN': 'Lập trình mobile',
      'PHONGHOC_TEN': 'A6-205',
      'GIOBATDAU': 9,
      'PHUTBATDAU': 30,
      'GIOKETTHUC': 12,
      'PHUTKETTHUC': 10,
    };

    final parsed = parser.parseApiResponse(<String, dynamic>{
      'Success': true,
      'Data': <Map<String, dynamic>>[item, Map<String, dynamic>.from(item)],
    }, displayName: 'Sinh viên');

    expect(parsed.records, hasLength(1));
  });

  test('rejects a non-empty response with no valid records', () {
    expect(
      () => parser.parseApiResponse(<String, dynamic>{
        'Success': true,
        'Data': <Map<String, dynamic>>[
          <String, dynamic>{
            'PHANLOAI': 'LICHHOC',
            'NGAYHOC': '26/08/2026',
            'TENHOCPHAN': 'Dữ liệu lỗi',
            'PHONGHOC_TEN': 'A6-205',
            'GIOBATDAU': 12,
            'PHUTBATDAU': 0,
            'GIOKETTHUC': 9,
            'PHUTKETTHUC': 0,
          },
        ],
      }, displayName: 'Sinh viên'),
      throwsFormatException,
    );
  });

  test('local snapshot JSON round-trip preserves records', () {
    final original = ScheduleSnapshot(
      displayName: 'Nguyễn Minh Đạo',
      syncedAt: DateTime(2026, 9, 9, 14),
      records: <ScheduleRecord>[
        ScheduleRecord(
          id: 'one',
          isExam: false,
          subjectName: 'Lập trình mobile',
          room: 'A6-205',
          startAt: DateTime(2026, 8, 26, 9, 30),
          endAt: DateTime(2026, 8, 26, 12, 10),
        ),
      ],
    );

    final restored = ScheduleSnapshot.decode(original.encode());
    expect(restored.displayName, original.displayName);
    expect(restored.records.single.room, 'A6-205');
    expect(restored.records.single.startAt, DateTime(2026, 8, 26, 9, 30));
  });
}
