import 'package:better_phenikaa_schedule/core/presentation/shared_widgets.dart';
import 'package:better_phenikaa_schedule/core/utils/date_time_formatters.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:flutter/material.dart';

class ExamScreen extends StatelessWidget {
  const new({
    required this.data,
    required this.showPast,
    required this.onTabChanged,
    super.key,
  });

  final ScheduleSnapshot data;
  final bool showPast;
  final ValueChanged<bool> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final referenceNow = DateTime.now();
    final exams = data.exams
        .where((record) {
          return showPast
              ? record.endAt.isBefore(referenceNow)
              : !record.endAt.isBefore(referenceNow);
        })
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TopTitle(title: 'Lịch thi', badge: null),
          const SizedBox(height: 20),
          _SegmentTabs(showPast: showPast, onChanged: onTabChanged),
          const SizedBox(height: 18),
          Expanded(
            child: exams.isEmpty
                ? EmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: showPast
                        ? 'Chưa có kỳ thi đã qua'
                        : 'Chưa có lịch thi sắp tới',
                    message: 'Dữ liệu sẽ được cập nhật sau lần đồng bộ QLĐT tiếp theo.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 82),
                    itemCount: exams.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _ExamCard(item: exams[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const new({required this.item});

  final ScheduleRecord item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0E193B80),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  item.startAt.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Color(0xFF173A87),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'THG ${item.startAt.month}',
                  style: const TextStyle(
                    color: Color(0xFF7583A4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.subjectName,
                  style: const TextStyle(
                    color: Color(0xFF18336F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.examForm.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    item.examForm,
                    style: const TextStyle(
                      color: Color(0xFF8A5A3B),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                MetaLine(
                  icon: Icons.access_time_rounded,
                  text:
                      '${formatTime(item.startAt)} - ${formatTime(item.endAt)}',
                ),
                if (item.room.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  MetaLine(icon: Icons.location_on_outlined, text: item.room),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const new({required this.showPast, required this.onChanged});

  final bool showPast;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TabButton(
              label: 'Sắp tới',
              selected: !showPast,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Đã qua',
              selected: showPast,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const <BoxShadow>[
                  BoxShadow(color: Color(0x15193B80), blurRadius: 8),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1747B5) : const Color(0xFF7180A0),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
