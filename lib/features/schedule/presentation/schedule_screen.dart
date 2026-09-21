import 'package:better_phenikaa_schedule/core/presentation/shared_widgets.dart';
import 'package:better_phenikaa_schedule/core/utils/date_time_formatters.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const new({
    required this.data,
    required this.selectedDate,
    required this.onDateChanged,
    super.key,
  });

  final ScheduleSnapshot data;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final items = data.classes
        .where((record) => isSameDay(record.startAt, selectedDate))
        .toList(growable: false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 180) {
          return;
        }
        onDateChanged(selectedDate.add(Duration(days: velocity < 0 ? 1 : -1)));
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TopTitle(
              title: 'Lịch học',
              badge: null,
              onCalendarTap: () =>
                  _showCalendarPicker(context, selectedDate, onDateChanged),
            ),
            const SizedBox(height: 24),
            _DateNavigator(
              date: selectedDate,
              onTap: () =>
                  _showCalendarPicker(context, selectedDate, onDateChanged),
              onPrevious: () =>
                  onDateChanged(selectedDate.subtract(const Duration(days: 1))),
              onNext: () =>
                  onDateChanged(selectedDate.add(const Duration(days: 1))),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(.14, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                  ),
                  child: items.isEmpty
                      ? const EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'Không có lịch học',
                          message: 'Vuốt sang ngày khác, bấm ngày hoặc biểu tượng lịch để chọn nhanh.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 82),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) => _ScheduleCard(
                            item: items[index],
                            accent: _accentFor(index),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const new({
    required this.date,
    required this.onTap,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      formatDateLabel(date),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF17367E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: Color(0xFF5D74A7),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

Future<void> _showCalendarPicker(
  BuildContext context,
  DateTime selectedDate,
  ValueChanged<DateTime> onDateChanged,
) async {
  var draft = dateOnly(selectedDate);
  final picked = await showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x660B2259),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: .94, end: 1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(
              alignment: Alignment.bottomCenter,
              scale: value,
              child: child,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x2510245A),
                      blurRadius: 28,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DFEE),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Chọn ngày xem lịch',
                            style: TextStyle(
                              color: Color(0xFF102B73),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setModalState(
                            () => draft = dateOnly(DateTime.now()),
                          ),
                          child: const Text('Hôm nay'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFF1747B5),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: draft,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035, 12, 31),
                        onDateChanged: (value) =>
                            setModalState(() => draft = dateOnly(value)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(draft),
                        icon: const Icon(Icons.check_rounded),
                        label: Text('Xem ${formatDateLabel(draft)}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  if (picked != null) {
    onDateChanged(dateOnly(picked));
  }
}

class _ScheduleCard extends StatelessWidget {
  const new({required this.item, required this.accent});

  final ScheduleRecord item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 106),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F193B80),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              formatTime(item.startAt),
              style: const TextStyle(
                color: Color(0xFF173A87),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    item.subjectName,
                    style: const TextStyle(
                      color: Color(0xFF18336F),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (item.room.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    MetaLine(icon: Icons.location_on_outlined, text: item.room),
                  ],
                  const SizedBox(height: 5),
                  MetaLine(
                    icon: Icons.access_time_rounded,
                    text:
                        '${formatTime(item.startAt)} - ${formatTime(item.endAt)}',
                  ),
                  if (item.periodStart != null &&
                      item.periodEnd != null) ...<Widget>[
                    const SizedBox(height: 5),
                    MetaLine(
                      icon: Icons.menu_book_outlined,
                      text: 'Tiết ${item.periodStart} - ${item.periodEnd}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _accentFor(int index) {
  const accents = <Color>[
    Color(0xFF4A89FF),
    Color(0xFF32C489),
    Color(0xFFFF941A),
    Color(0xFF8154D9),
  ];
  return accents[index % accents.length];
}
