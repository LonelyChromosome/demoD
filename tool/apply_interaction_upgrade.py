from pathlib import Path

path = Path('lib/app/app.dart')
text = path.read_text(encoding='utf-8')

# 1) Timetable calendar icon + date label both open a calendar picker.
old = """            _TopTitle(\n              title: 'Lịch học',\n              badge: data.source == 'demo' ? 'DEMO' : null,\n            ),\n            const SizedBox(height: 24),\n            _DateNavigator(\n              date: selectedDate,\n              onPrevious: () =>\n                  onDateChanged(selectedDate.subtract(const Duration(days: 1))),\n              onNext: () =>\n                  onDateChanged(selectedDate.add(const Duration(days: 1))),\n            ),\n"""
new = """            _TopTitle(\n              title: 'Lịch học',\n              badge: data.source == 'demo' ? 'DEMO' : null,\n              onCalendarTap: () =>\n                  _showCalendarPicker(context, selectedDate, onDateChanged),\n            ),\n            const SizedBox(height: 24),\n            _DateNavigator(\n              date: selectedDate,\n              onTap: () =>\n                  _showCalendarPicker(context, selectedDate, onDateChanged),\n              onPrevious: () =>\n                  onDateChanged(selectedDate.subtract(const Duration(days: 1))),\n              onNext: () =>\n                  onDateChanged(selectedDate.add(const Duration(days: 1))),\n            ),\n"""
if old not in text:
    raise SystemExit('Timetable header block not found')
text = text.replace(old, new, 1)

# 2) Slide/fade the schedule body whenever the chosen day changes.
old = """            Expanded(\n              child: items.isEmpty\n                  ? const _EmptyState(\n                      icon: Icons.event_available_outlined,\n                      title: 'Không có lịch học',\n                      message: 'Vuốt sang ngày khác hoặc dùng nút mũi tên để xem lịch.',\n                    )\n                  : ListView.separated(\n                      padding: const EdgeInsets.only(bottom: 82),\n                      itemCount: items.length,\n                      separatorBuilder: (_, _) => const SizedBox(height: 14),\n                      itemBuilder: (context, index) => _ScheduleCard(\n                        item: items[index],\n                        accent: _accentFor(index),\n                      ),\n                    ),\n            ),\n"""
new = """            Expanded(\n              child: AnimatedSwitcher(\n                duration: const Duration(milliseconds: 320),\n                switchInCurve: Curves.easeOutCubic,\n                switchOutCurve: Curves.easeInCubic,\n                transitionBuilder: (child, animation) {\n                  final slide = Tween<Offset>(\n                    begin: const Offset(.14, 0),\n                    end: Offset.zero,\n                  ).animate(animation);\n                  return FadeTransition(\n                    opacity: animation,\n                    child: SlideTransition(position: slide, child: child),\n                  );\n                },\n                child: KeyedSubtree(\n                  key: ValueKey<String>(\n                    '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',\n                  ),\n                  child: items.isEmpty\n                      ? const _EmptyState(\n                          icon: Icons.event_available_outlined,\n                          title: 'Không có lịch học',\n                          message:\n                              'Vuốt sang ngày khác, bấm ngày hoặc biểu tượng lịch để chọn nhanh.',\n                        )\n                      : ListView.separated(\n                          padding: const EdgeInsets.only(bottom: 82),\n                          itemCount: items.length,\n                          separatorBuilder: (_, _) =>\n                              const SizedBox(height: 14),\n                          itemBuilder: (context, index) => _ScheduleCard(\n                            item: items[index],\n                            accent: _accentFor(index),\n                          ),\n                        ),\n                ),\n              ),\n            ),\n"""
if old not in text:
    raise SystemExit('Timetable body block not found')
text = text.replace(old, new, 1)

# 3) Make the top calendar button optionally interactive.
old = """class _TopTitle extends StatelessWidget {\n  const new({required this.title, this.badge});\n\n  final String title;\n  final String? badge;\n"""
new = """class _TopTitle extends StatelessWidget {\n  const new({required this.title, this.badge, this.onCalendarTap});\n\n  final String title;\n  final String? badge;\n  final VoidCallback? onCalendarTap;\n"""
if old not in text:
    raise SystemExit('TopTitle declaration not found')
text = text.replace(old, new, 1)

old = """        const Spacer(),\n        const Icon(Icons.calendar_month_outlined, color: Color(0xFF1747B5)),\n"""
new = """        const Spacer(),\n        if (onCalendarTap == null)\n          const Icon(\n            Icons.calendar_month_outlined,\n            color: Color(0xFF1747B5),\n          )\n        else\n          IconButton.filledTonal(\n            tooltip: 'Chọn ngày',\n            onPressed: onCalendarTap,\n            style: IconButton.styleFrom(\n              foregroundColor: const Color(0xFF1747B5),\n              backgroundColor: const Color(0xFFEEF4FF),\n            ),\n            icon: const Icon(Icons.calendar_month_outlined),\n          ),\n"""
if old not in text:
    raise SystemExit('TopTitle calendar icon not found')
text = text.replace(old, new, 1)

# 4) Date navigator center becomes a tappable pill.
old = """class _DateNavigator extends StatelessWidget {\n  const new({\n    required this.date,\n    required this.onPrevious,\n    required this.onNext,\n  });\n\n  final DateTime date;\n  final VoidCallback onPrevious;\n  final VoidCallback onNext;\n"""
new = """class _DateNavigator extends StatelessWidget {\n  const new({\n    required this.date,\n    required this.onTap,\n    required this.onPrevious,\n    required this.onNext,\n  });\n\n  final DateTime date;\n  final VoidCallback onTap;\n  final VoidCallback onPrevious;\n  final VoidCallback onNext;\n"""
if old not in text:
    raise SystemExit('DateNavigator declaration not found')
text = text.replace(old, new, 1)

old = """        Expanded(\n          child: Text(\n            _dateLabel(date),\n            textAlign: TextAlign.center,\n            style: const TextStyle(\n              color: Color(0xFF17367E),\n              fontWeight: FontWeight.w700,\n            ),\n          ),\n        ),\n"""
new = """        Expanded(\n          child: InkWell(\n            onTap: onTap,\n            borderRadius: BorderRadius.circular(18),\n            child: Padding(\n              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),\n              child: Row(\n                mainAxisAlignment: MainAxisAlignment.center,\n                children: <Widget>[\n                  Flexible(\n                    child: Text(\n                      _dateLabel(date),\n                      overflow: TextOverflow.ellipsis,\n                      textAlign: TextAlign.center,\n                      style: const TextStyle(\n                        color: Color(0xFF17367E),\n                        fontWeight: FontWeight.w700,\n                      ),\n                    ),\n                  ),\n                  const SizedBox(width: 7),\n                  const Icon(\n                    Icons.expand_more_rounded,\n                    size: 18,\n                    color: Color(0xFF5D74A7),\n                  ),\n                ],\n              ),\n            ),\n          ),\n        ),\n"""
if old not in text:
    raise SystemExit('DateNavigator center block not found')
text = text.replace(old, new, 1)

# 5) Add a custom animated calendar sheet before schedule card.
marker = 'class _ScheduleCard extends StatelessWidget {'
if marker not in text:
    raise SystemExit('ScheduleCard marker not found')
calendar_helper = r'''Future<void> _showCalendarPicker(
  BuildContext context,
  DateTime selectedDate,
  ValueChanged<DateTime> onDateChanged,
) async {
  DateTime draft = _dateOnly(selectedDate);
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
                            () => draft = _dateOnly(DateTime.now()),
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
                            setModalState(() => draft = _dateOnly(value)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(draft),
                        icon: const Icon(Icons.check_rounded),
                        label: Text('Xem ${_dateLabel(draft)}'),
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
    onDateChanged(_dateOnly(picked));
  }
}

'''
text = text.replace(marker, calendar_helper + marker, 1)

# 6) Give the control panel more room for the quarter-circle layout.
old = """            Positioned(\n              right: 24,\n              bottom: 106,\n              child: _ControlPanel(\n"""
new = """            Positioned(\n              right: 10,\n              bottom: 78,\n              child: _ControlPanel(\n"""
if old not in text:
    raise SystemExit('Control panel Positioned block not found')
text = text.replace(old, new, 1)

# 7) Animate the FAB icon while opening/closing.
old = """              child: Icon(panelOpen ? Icons.close : Icons.grid_view_rounded),\n"""
new = """              child: AnimatedRotation(\n                turns: panelOpen ? .125 : 0,\n                duration: const Duration(milliseconds: 260),\n                curve: Curves.easeOutCubic,\n                child: AnimatedSwitcher(\n                  duration: const Duration(milliseconds: 180),\n                  child: Icon(\n                    panelOpen ? Icons.close : Icons.grid_view_rounded,\n                    key: ValueKey<bool>(panelOpen),\n                  ),\n                ),\n              ),\n"""
if old not in text:
    raise SystemExit('FAB icon block not found')
text = text.replace(old, new, 1)

# 8) Replace the vertical menu with a staggered quarter-circle / arc menu.
start = text.find('class _ControlPanel extends StatelessWidget {')
end = text.find('class _PanelAction extends StatelessWidget {')
if start == -1 or end == -1 or end <= start:
    raise SystemExit('ControlPanel block bounds not found')
control_panel = r'''class _ControlPanel extends StatelessWidget {
  const new({
    required this.page,
    required this.onOpenPage,
    required this.onSync,
  });

  final _AppPage page;
  final ValueChanged<_AppPage> onOpenPage;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return SizedBox(
          width: 286,
          height: 292,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _ArcPanelAction(
                progress: progress,
                start: 0,
                right: 4,
                bottom: 205,
                originOffset: const Offset(20, 78),
                child: _PanelAction(
                  label: 'Lịch học',
                  icon: Icons.event_available_rounded,
                  color: const Color(0xFF4A89FF),
                  selected: page == _AppPage.timetable,
                  onTap: () => onOpenPage(_AppPage.timetable),
                ),
              ),
              _ArcPanelAction(
                progress: progress,
                start: .10,
                right: 48,
                bottom: 148,
                originOffset: const Offset(34, 62),
                child: _PanelAction(
                  label: 'Lịch thi',
                  icon: Icons.assignment_rounded,
                  color: const Color(0xFF32C489),
                  selected: page == _AppPage.exam,
                  onTap: () => onOpenPage(_AppPage.exam),
                ),
              ),
              _ArcPanelAction(
                progress: progress,
                start: .20,
                right: 82,
                bottom: 84,
                originOffset: const Offset(46, 46),
                child: _PanelAction(
                  label: 'Đồng bộ',
                  icon: Icons.sync_rounded,
                  color: const Color(0xFFFFA51E),
                  selected: false,
                  onTap: onSync,
                ),
              ),
              _ArcPanelAction(
                progress: progress,
                start: .30,
                right: 96,
                bottom: 16,
                originOffset: const Offset(54, 26),
                child: _PanelAction(
                  label: 'Tài khoản',
                  icon: Icons.person_rounded,
                  color: const Color(0xFF8154D9),
                  selected: page == _AppPage.account,
                  onTap: () => onOpenPage(_AppPage.account),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPanelAction extends StatelessWidget {
  const new({
    required this.progress,
    required this.start,
    required this.right,
    required this.bottom,
    required this.originOffset,
    required this.child,
  });

  final double progress;
  final double start;
  final double right;
  final double bottom;
  final Offset originOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
    final curved = Curves.easeOutBack.transform(t);
    return Positioned(
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: t < .55,
        child: Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset.lerp(originOffset, Offset.zero, curved)!,
            child: Transform.scale(
              alignment: Alignment.centerRight,
              scale: .72 + (.28 * curved),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

'''
text = text[:start] + control_panel + text[end:]

path.write_text(text, encoding='utf-8')
print('Interaction upgrade applied.')
