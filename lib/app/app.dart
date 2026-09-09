import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/qldt_intake/qldt_login.dart';
import '../features/qldt_intake/qldt_models.dart';

class BetterPhenikaaScheduleApp extends StatelessWidget {
  const BetterPhenikaaScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF12358B);
    return MaterialApp(
      title: 'Better Phenikaa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FD),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const _AppRoot(),
    );
  }
}

enum _AppPage { timetable, exam, account }

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  static const _storageKey = 'better_phenikaa_snapshot_v1';

  bool _booting = true;
  bool _syncing = false;
  bool _panelOpen = false;
  ImportedScheduleData? _data;
  _AppPage _page = _AppPage.timetable;
  DateTime _selectedDate = DateTime.now();
  bool _showPastExams = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = ImportedScheduleData.decode(raw);
        _data = data;
        _selectedDate = _initialDateFor(data);
      }
    } on Object catch (error) {
      _errorMessage = 'Không đọc được dữ liệu cục bộ: $error';
    }
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() => _booting = false);
    }
  }

  Future<void> _save(ImportedScheduleData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, data.encode());
    await _publishWidget(data);
  }

  Future<void> _publishWidget(ImportedScheduleData data) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final next = _nextClass(data);
    await HomeWidget.saveWidgetData<String>(
      'subjectName',
      next?.subjectName ?? 'Không có lịch học sắp tới',
    );
    await HomeWidget.saveWidgetData<String>('room', next?.room ?? '');
    await HomeWidget.saveWidgetData<String>(
      'time',
      next == null ? '' : '${_time(next.startAt)} - ${_time(next.endAt)}',
    );
    await HomeWidget.updateWidget(
      name: 'ScheduleWidgetProvider',
      androidName: 'ScheduleWidgetProvider',
    );
  }

  ScheduleRecord? _nextClass(ImportedScheduleData data) {
    final now = data.source == 'demo'
        ? DateTime(2026, 8, 26, 6)
        : DateTime.now();
    final future = data.classes.where((item) => !item.endAt.isBefore(now)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return future.isEmpty ? null : future.first;
  }

  Future<void> _loginOrSync() async {
    if (!supportsLiveQldtLogin) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'GitHub Pages không thể đọc phiên đăng nhập QLĐT khác tên miền. Đăng nhập thật được bật trong APK Android bằng WebView.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _syncing = true;
      _errorMessage = null;
      _panelOpen = false;
    });
    try {
      final imported = await openQldtLogin(context);
      if (imported != null) {
        await _save(imported);
        if (mounted) {
          setState(() {
            _data = imported;
            _selectedDate = _initialDateFor(imported);
            _page = _AppPage.timetable;
          });
        }
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Đồng bộ thất bại: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _loadDemo() async {
    final demo = _buildDemoData();
    await _save(demo);
    if (mounted) {
      setState(() {
        _data = demo;
        _selectedDate = DateTime(2026, 8, 26);
        _page = _AppPage.timetable;
        _errorMessage = null;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await HomeWidget.saveWidgetData<String>('subjectName', '');
      await HomeWidget.saveWidgetData<String>('room', '');
      await HomeWidget.saveWidgetData<String>('time', '');
      await HomeWidget.updateWidget(
        name: 'ScheduleWidgetProvider',
        androidName: 'ScheduleWidgetProvider',
      );
    }
    if (mounted) {
      setState(() {
        _data = null;
        _panelOpen = false;
        _page = _AppPage.timetable;
        _errorMessage = null;
      });
    }
  }

  DateTime _initialDateFor(ImportedScheduleData data) {
    if (data.source == 'demo') {
      return DateTime(2026, 8, 26);
    }
    final today = _dateOnly(DateTime.now());
    if (data.classes.any((record) => _sameDay(record.startAt, today))) {
      return today;
    }
    final future = data.classes.where((record) => !record.startAt.isBefore(today)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    if (future.isNotEmpty) {
      return _dateOnly(future.first.startAt);
    }
    return data.classes.isNotEmpty ? _dateOnly(data.classes.last.startAt) : today;
  }

  void _openPage(_AppPage page) {
    setState(() {
      _page = page;
      _panelOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF9FBFF), Color(0xFFF2F6FF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth > 680;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktop ? 470 : constraints.maxWidth,
                    maxHeight: desktop ? 860 : constraints.maxHeight,
                  ),
                  child: Container(
                    margin: desktop
                        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(desktop ? 28 : 0),
                      boxShadow: desktop
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x140B2259),
                                blurRadius: 36,
                                offset: Offset(0, 14),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: _booting
                          ? const _SplashScreen()
                          : _data == null
                              ? _LoginScreen(
                                  onLogin: _loginOrSync,
                                  onDemo: _loadDemo,
                                  supportsLive: supportsLiveQldtLogin,
                                )
                              : _MainShell(
                                  data: _data!,
                                  page: _page,
                                  selectedDate: _selectedDate,
                                  showPastExams: _showPastExams,
                                  panelOpen: _panelOpen,
                                  syncing: _syncing,
                                  errorMessage: _errorMessage,
                                  onTogglePanel: () => setState(
                                    () => _panelOpen = !_panelOpen,
                                  ),
                                  onOpenPage: _openPage,
                                  onSync: _loginOrSync,
                                  onLogout: _logout,
                                  onDateChanged: (date) => setState(
                                    () => _selectedDate = _dateOnly(date),
                                  ),
                                  onExamTabChanged: (past) => setState(
                                    () => _showPastExams = past,
                                  ),
                                  onDismissError: () => setState(
                                    () => _errorMessage = null,
                                  ),
                                ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const _PhoneSurface(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _AppMark(size: 76),
          SizedBox(height: 26),
          Text(
            'Better Phenikaa App',
            style: TextStyle(
              color: Color(0xFF102B73),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Lịch học & Lịch thi',
            style: TextStyle(color: Color(0xFF6F7C9B), fontSize: 15),
          ),
          SizedBox(height: 120),
          SizedBox(
            width: 88,
            child: LinearProgressIndicator(
              minHeight: 4,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              backgroundColor: Color(0xFFDCE5F8),
              color: Color(0xFF1747B5),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Đang khởi động...',
            style: TextStyle(color: Color(0xFF607095), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen({
    required this.onLogin,
    required this.onDemo,
    required this.supportsLive,
  });

  final VoidCallback onLogin;
  final VoidCallback onDemo;
  final bool supportsLive;

  @override
  Widget build(BuildContext context) {
    return _PhoneSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 58, 32, 30),
        child: Column(
          children: <Widget>[
            const Spacer(),
            const _AppMark(size: 62),
            const SizedBox(height: 22),
            const Text(
              'Chào mừng bạn!',
              style: TextStyle(
                color: Color(0xFF102B73),
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Kết nối với QLĐT để xem lịch học và lịch thi của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF67789E),
                height: 1.55,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 38),
            SizedBox(
              width: double.infinity,
              height: 62,
              child: FilledButton(
                onPressed: onLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF143B98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const _MicrosoftMark(),
                    const SizedBox(width: 14),
                    Text(
                      supportsLive
                          ? 'Đăng nhập QLĐT\n(Microsoft)'
                          : 'Đăng nhập QLĐT thật\n(Android APK)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onDemo,
                icon: const Icon(Icons.preview_outlined),
                label: const Text('Xem bản demo từ mockup'),
              ),
            ),
            const SizedBox(height: 22),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.lock_outline, size: 17, color: Color(0xFF8290AF)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Dữ liệu chỉ lưu cục bộ trên thiết bị của bạn',
                    style: TextStyle(color: Color(0xFF8290AF), fontSize: 12),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
            const Text(
              'Better Phenikaa App',
              style: TextStyle(
                color: Color(0xFF9AA5BD),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell({
    required this.data,
    required this.page,
    required this.selectedDate,
    required this.showPastExams,
    required this.panelOpen,
    required this.syncing,
    required this.errorMessage,
    required this.onTogglePanel,
    required this.onOpenPage,
    required this.onSync,
    required this.onLogout,
    required this.onDateChanged,
    required this.onExamTabChanged,
    required this.onDismissError,
  });

  final ImportedScheduleData data;
  final _AppPage page;
  final DateTime selectedDate;
  final bool showPastExams;
  final bool panelOpen;
  final bool syncing;
  final String? errorMessage;
  final VoidCallback onTogglePanel;
  final ValueChanged<_AppPage> onOpenPage;
  final VoidCallback onSync;
  final VoidCallback onLogout;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<bool> onExamTabChanged;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final child = switch (page) {
      _AppPage.timetable => _TimetableScreen(
          data: data,
          selectedDate: selectedDate,
          onDateChanged: onDateChanged,
        ),
      _AppPage.exam => _ExamScreen(
          data: data,
          showPast: showPastExams,
          onTabChanged: onExamTabChanged,
        ),
      _AppPage.account => _AccountScreen(
          data: data,
          onLogout: onLogout,
          onSync: onSync,
        ),
    };

    return _PhoneSurface(
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: child),
          if (errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              top: 14,
              child: _ErrorBanner(
                message: errorMessage!,
                onDismiss: onDismissError,
              ),
            ),
          if (syncing)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (panelOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: onTogglePanel,
                child: Container(color: const Color(0x770B2259)),
              ),
            ),
          if (panelOpen)
            Positioned(
              right: 24,
              bottom: 106,
              child: _ControlPanel(
                page: page,
                onOpenPage: onOpenPage,
                onSync: onSync,
              ),
            ),
          Positioned(
            right: 22,
            bottom: 28,
            child: FloatingActionButton(
              heroTag: 'control-panel',
              onPressed: onTogglePanel,
              backgroundColor: const Color(0xFF1647B6),
              foregroundColor: Colors.white,
              elevation: 8,
              child: Icon(panelOpen ? Icons.close : Icons.grid_view_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableScreen extends StatelessWidget {
  const _TimetableScreen({
    required this.data,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final ImportedScheduleData data;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final items = data.classes
        .where((record) => _sameDay(record.startAt, selectedDate))
        .toList(growable: false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 180) {
          return;
        }
        onDateChanged(
          selectedDate.add(Duration(days: velocity < 0 ? 1 : -1)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _TopTitle(
              title: 'Lịch học',
              badge: data.source == 'demo' ? 'DEMO' : null,
            ),
            const SizedBox(height: 24),
            _DateNavigator(
              date: selectedDate,
              onPrevious: () => onDateChanged(
                selectedDate.subtract(const Duration(days: 1)),
              ),
              onNext: () => onDateChanged(
                selectedDate.add(const Duration(days: 1)),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'Không có lịch học',
                      message: 'Vuốt sang ngày khác hoặc dùng nút mũi tên để xem lịch.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 82),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => _ScheduleCard(
                        item: items[index],
                        accent: _accentFor(index),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamScreen extends StatelessWidget {
  const _ExamScreen({
    required this.data,
    required this.showPast,
    required this.onTabChanged,
  });

  final ImportedScheduleData data;
  final bool showPast;
  final ValueChanged<bool> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final referenceNow = data.source == 'demo'
        ? DateTime(2026, 8, 26, 6)
        : DateTime.now();
    final exams = data.exams.where((record) {
      return showPast
          ? record.endAt.isBefore(referenceNow)
          : !record.endAt.isBefore(referenceNow);
    }).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TopTitle(
            title: 'Lịch thi',
            badge: data.source == 'demo' ? 'DEMO' : null,
          ),
          const SizedBox(height: 20),
          _SegmentTabs(
            showPast: showPast,
            onChanged: onTabChanged,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: exams.isEmpty
                ? _EmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: showPast ? 'Chưa có kỳ thi đã qua' : 'Chưa có lịch thi sắp tới',
                    message: 'Dữ liệu sẽ được cập nhật sau lần đồng bộ QLĐT tiếp theo.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 82),
                    itemCount: exams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ExamCard(item: exams[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen({
    required this.data,
    required this.onLogout,
    required this.onSync,
  });

  final ImportedScheduleData data;
  final VoidCallback onLogout;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final next = _nextForAccount(data);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TopTitle(
            title: 'Tài khoản',
            badge: data.source == 'demo' ? 'DEMO' : null,
          ),
          const SizedBox(height: 30),
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFF3F76DC),
                child: Icon(Icons.person_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  data.displayName.isEmpty ? 'Người dùng QLĐT' : data.displayName,
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
          if (next != null) _WidgetPreview(item: next),
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
              label: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 76),
        ],
      ),
    );
  }

  static ScheduleRecord? _nextForAccount(ImportedScheduleData data) {
    if (data.classes.isEmpty) {
      return null;
    }
    final reference = data.source == 'demo'
        ? DateTime(2026, 8, 26, 6)
        : DateTime.now();
    final items = data.classes.where((record) => !record.endAt.isBefore(reference)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return items.isEmpty ? null : items.first;
  }
}

class _TopTitle extends StatelessWidget {
  const _TopTitle({required this.title, this.badge});

  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102B73),
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (badge != null) ...<Widget>[
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Color(0xFF1747B5),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const Spacer(),
        const Icon(Icons.calendar_month_outlined, color: Color(0xFF1747B5)),
      ],
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left_rounded)),
        Expanded(
          child: Text(
            _dateLabel(date),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF17367E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item, required this.accent});

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
          BoxShadow(color: Color(0x0F193B80), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              _time(item.startAt),
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
                    _MetaLine(icon: Icons.location_on_outlined, text: item.room),
                  ],
                  const SizedBox(height: 5),
                  _MetaLine(
                    icon: Icons.access_time_rounded,
                    text: '${_time(item.startAt)} - ${_time(item.endAt)}',
                  ),
                  if (item.periodStart != null && item.periodEnd != null) ...<Widget>[
                    const SizedBox(height: 5),
                    _MetaLine(
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

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.item});

  final ScheduleRecord item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0E193B80), blurRadius: 16, offset: Offset(0, 5)),
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
                  style: const TextStyle(color: Color(0xFF7583A4), fontSize: 10),
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
                    style: const TextStyle(color: Color(0xFF8A5A3B), fontSize: 11),
                  ),
                ],
                const SizedBox(height: 7),
                _MetaLine(
                  icon: Icons.access_time_rounded,
                  text: '${_time(item.startAt)} - ${_time(item.endAt)}',
                ),
                if (item.room.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  _MetaLine(icon: Icons.location_on_outlined, text: item.room),
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
  const _SegmentTabs({required this.showPast, required this.onChanged});

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
  const _TabButton({required this.label, required this.selected, required this.onTap});

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

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.data});

  final ImportedScheduleData data;

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
          _AccountInfoRow(label: 'Lịch học', value: '${data.classes.length} mục'),
          const SizedBox(height: 8),
          _AccountInfoRow(label: 'Lịch thi', value: '${data.exams.length} mục'),
          const SizedBox(height: 8),
          _AccountInfoRow(
            label: 'Cập nhật lần cuối',
            value: '${_dateShort(data.syncedAt)} ${_time(data.syncedAt)}',
          ),
          const SizedBox(height: 8),
          _AccountInfoRow(
            label: 'Nguồn',
            value: data.source == 'demo' ? 'Demo từ mockup' : 'QLĐT Phenikaa',
          ),
        ],
      ),
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF7180A0), fontSize: 12)),
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

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({required this.item});

  final ScheduleRecord item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Widget 1×4',
          style: TextStyle(color: Color(0xFF18336F), fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF173A8E), Color(0xFF315AB5)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.subjectName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Row(
                children: <Widget>[
                  const Icon(Icons.location_on_outlined, color: Colors.white70, size: 15),
                  const SizedBox(width: 5),
                  Text(item.room, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.access_time_rounded, color: Colors.white70, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    '${_time(item.startAt)} - ${_time(item.endAt)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.page,
    required this.onOpenPage,
    required this.onSync,
  });

  final _AppPage page;
  final ValueChanged<_AppPage> onOpenPage;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        _PanelAction(
          label: 'Lịch học',
          icon: Icons.event_available_rounded,
          color: const Color(0xFF4A89FF),
          selected: page == _AppPage.timetable,
          onTap: () => onOpenPage(_AppPage.timetable),
        ),
        const SizedBox(height: 10),
        _PanelAction(
          label: 'Lịch thi',
          icon: Icons.assignment_rounded,
          color: const Color(0xFF32C489),
          selected: page == _AppPage.exam,
          onTap: () => onOpenPage(_AppPage.exam),
        ),
        const SizedBox(height: 10),
        _PanelAction(
          label: 'Đồng bộ',
          icon: Icons.sync_rounded,
          color: const Color(0xFFFFA51E),
          selected: false,
          onTap: onSync,
        ),
        const SizedBox(height: 10),
        _PanelAction(
          label: 'Tài khoản',
          icon: Icons.person_rounded,
          color: const Color(0xFF8154D9),
          selected: page == _AppPage.account,
          onTap: () => onOpenPage(_AppPage.account),
        ),
      ],
    );
  }
}

class _PanelAction extends StatelessWidget {
  const _PanelAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 50,
          padding: const EdgeInsets.fromLTRB(18, 5, 5, 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: selected ? Border.all(color: color.withValues(alpha: .35)) : null,
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x28112452), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF203A76),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: const Color(0xFF6F7FA2)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF6F7FA2), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 52, color: const Color(0xFFA4B2CE)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF244584),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A88A7), height: 1.45, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFFFFF0F0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline, color: Color(0xFFC63C3C), size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF8B2F2F), fontSize: 12),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneSurface extends StatelessWidget {
  const _PhoneSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox.expand(child: child),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .2),
        border: Border.all(color: const Color(0xFF183F9C), width: size * .08),
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * .62,
        color: const Color(0xFF183F9C),
      ),
    );
  }
}

class _MicrosoftMark extends StatelessWidget {
  const _MicrosoftMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 25,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: <Widget>[
          _MsTile(Color(0xFFF25022)),
          _MsTile(Color(0xFF7FBA00)),
          _MsTile(Color(0xFF00A4EF)),
          _MsTile(Color(0xFFFFB900)),
        ],
      ),
    );
  }
}

class _MsTile extends StatelessWidget {
  const _MsTile(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: 11.5, child: ColoredBox(color: color));
  }
}

ImportedScheduleData _buildDemoData() {
  DateTime at(int month, int day, int hour, int minute) =>
      DateTime(2026, month, day, hour, minute);

  return ImportedScheduleData(
    displayName: 'Nguyễn Văn A',
    syncedAt: DateTime(2026, 8, 26, 9, 41),
    source: 'demo',
    records: <ScheduleRecord>[
      ScheduleRecord(
        id: 'demo-class-1',
        isExam: false,
        subjectName: 'Thiết kế web nâng cao',
        room: 'A6-101',
        startAt: at(8, 26, 6, 45),
        endAt: at(8, 26, 9, 25),
      ),
      ScheduleRecord(
        id: 'demo-class-2',
        isExam: false,
        subjectName: 'Lập trình mobile',
        room: 'A6-205',
        startAt: at(8, 26, 9, 30),
        endAt: at(8, 26, 12, 10),
      ),
      ScheduleRecord(
        id: 'demo-class-3',
        isExam: false,
        subjectName: 'Phân tích & thiết kế hệ thống',
        room: 'A6-105',
        startAt: at(8, 26, 13, 0),
        endAt: at(8, 26, 15, 40),
      ),
      ScheduleRecord(
        id: 'demo-exam-1',
        isExam: true,
        subjectName: 'Lập trình C++',
        room: 'A6-201',
        startAt: at(8, 26, 7, 30),
        endAt: at(8, 26, 9, 0),
      ),
      ScheduleRecord(
        id: 'demo-exam-2',
        isExam: true,
        subjectName: 'Cơ sở dữ liệu',
        room: 'A5-302',
        startAt: at(8, 30, 13, 30),
        endAt: at(8, 30, 15, 0),
      ),
      ScheduleRecord(
        id: 'demo-exam-3',
        isExam: true,
        subjectName: 'Kỹ thuật phần mềm',
        room: 'A6-105',
        startAt: at(9, 2, 7, 30),
        endAt: at(9, 2, 9, 0),
      ),
      ScheduleRecord(
        id: 'demo-exam-4',
        isExam: true,
        subjectName: 'Mạng máy tính',
        room: 'A6-206',
        startAt: at(9, 9, 13, 30),
        endAt: at(9, 9, 15, 0),
      ),
    ],
  );
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

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _dateShort(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateLabel(DateTime value) {
  const weekdays = <String>[
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];
  return '${weekdays[value.weekday - 1]}, ${value.day} tháng ${value.month}';
}
