import 'package:better_phenikaa_schedule/core/presentation/shared_widgets.dart';
import 'package:better_phenikaa_schedule/core/utils/date_time_formatters.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:better_phenikaa_schedule/features/widget/presentation/widget_preview.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const new({
    required this.data,
    required this.onLogout,
    required this.onSync,
    super.key,
  });

  final ScheduleSnapshot data;
  final VoidCallback onLogout;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final next = _nextClass(data);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TopTitle(title: 'Tài khoản', badge: null),
          const SizedBox(height: 30),
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFF3F76DC),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  data.displayName.isEmpty
                      ? 'Người dùng QLĐT'
                      : data.displayName,
                  style: const TextStyle(
                    color: Color(0xFF102B73),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _InfoPanel(data: data),
          const SizedBox(height: 18),
          if (next != null) WidgetPreview(item: next),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onSync,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Đồng bộ lại QLĐT'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE55656),
                side: const BorderSide(color: Color(0xFFFFB7B7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 76),
        ],
      ),
    );
  }

  static ScheduleRecord? _nextClass(ScheduleSnapshot data) {
    final reference = DateTime.now();
    final items =
        data.classes
            .where((record) => !record.endAt.isBefore(reference))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return items.isEmpty ? null : items.first;
  }
}

class _InfoPanel extends StatelessWidget {
  const new({required this.data});

  final ScheduleSnapshot data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Dữ liệu trên thiết bị',
            style: TextStyle(
              color: Color(0xFF18336F),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Lịch học', value: '${data.classes.length} mục'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Lịch thi', value: '${data.exams.length} mục'),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Cập nhật lần cuối',
            value:
                '${formatDateShort(data.syncedAt)} ${formatTime(data.syncedAt)}',
          ),
          const SizedBox(height: 8),
          const _InfoRow(label: 'Nguồn', value: 'QLĐT Phenikaa'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF7180A0), fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF244584),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
