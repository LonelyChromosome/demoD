import 'dart:async';

import 'package:better_phenikaa_schedule/core/presentation/shared_widgets.dart';
import 'package:better_phenikaa_schedule/core/utils/date_time_formatters.dart';
import 'package:better_phenikaa_schedule/features/exams/presentation/exam_screen.dart';
import 'package:better_phenikaa_schedule/features/qldt_login/presentation/login_screen.dart';
import 'package:better_phenikaa_schedule/features/qldt_login/presentation/qldt_login.dart';
import 'package:better_phenikaa_schedule/features/schedule/presentation/schedule_screen.dart';
import 'package:better_phenikaa_schedule/features/settings/presentation/account_screen.dart';
import 'package:better_phenikaa_schedule/features/sync/application/schedule_sync_coordinator.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:better_phenikaa_schedule/features/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BetterPhenikaaScheduleApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better Phenikaa App',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppRoot(),
    );
  }
}

enum _AppPage { timetable, exam, account }

class _AppRoot extends StatefulWidget {
  const new();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  static const _syncCoordinator = ScheduleSyncCoordinator();

  bool _booting = true;
  bool _syncing = false;
  bool _panelOpen = false;
  ScheduleSnapshot? _data;
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
      final data = await _syncCoordinator.restore();
      if (data != null) {
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
      final imported = await _syncCoordinator.synchronize(
        () => openQldtLogin(context),
      );
      if (imported != null && mounted) {
        setState(() {
          _data = imported;
          _selectedDate = _initialDateFor(imported);
          _page = _AppPage.timetable;
        });
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

  Future<void> _logout() async {
    try {
      await _syncCoordinator.clear(clearSession: clearQldtSession);
      if (mounted) {
        setState(() {
          _data = null;
          _panelOpen = false;
          _page = _AppPage.timetable;
          _errorMessage = null;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Đăng xuất thất bại: $error');
      }
    }
  }

  DateTime _initialDateFor(ScheduleSnapshot data) {
    final today = dateOnly(DateTime.now());
    if (data.classes.any((record) => isSameDay(record.startAt, today))) {
      return today;
    }
    final future =
        data.classes.where((record) => !record.startAt.isBefore(today)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    if (future.isNotEmpty) {
      return dateOnly(future.first.startAt);
    }
    return data.classes.isNotEmpty
        ? dateOnly(data.classes.last.startAt)
        : today;
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
                        ? const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          )
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
                          ? QldtLoginScreen(
                              onLogin: _loginOrSync,
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
                              onTogglePanel: () =>
                                  setState(() => _panelOpen = !_panelOpen),
                              onOpenPage: _openPage,
                              onSync: _loginOrSync,
                              onLogout: _logout,
                              onDateChanged: (date) => setState(
                                () => _selectedDate = dateOnly(date),
                              ),
                              onExamTabChanged: (past) =>
                                  setState(() => _showPastExams = past),
                              onDismissError: () =>
                                  setState(() => _errorMessage = null),
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
  const new();

  @override
  Widget build(BuildContext context) {
    return const PhoneSurface(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AppMark(size: 76),
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

class _MainShell extends StatelessWidget {
  const new({
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

  final ScheduleSnapshot data;
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
      _AppPage.timetable => ScheduleScreen(
        data: data,
        selectedDate: selectedDate,
        onDateChanged: onDateChanged,
      ),
      _AppPage.exam => ExamScreen(
        data: data,
        showPast: showPastExams,
        onTabChanged: onExamTabChanged,
      ),
      _AppPage.account => AccountScreen(
        data: data,
        onLogout: onLogout,
        onSync: onSync,
      ),
    };

    return PhoneSurface(
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
              right: 10,
              bottom: 78,
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
              child: AnimatedRotation(
                turns: panelOpen ? .125 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    panelOpen ? Icons.close : Icons.grid_view_rounded,
                    key: ValueKey<bool>(panelOpen),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
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

class _PanelAction extends StatelessWidget {
  const new({
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
            border: selected
                ? Border.all(color: color.withValues(alpha: .35))
                : null,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x28112452),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
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

class _ErrorBanner extends StatelessWidget {
  const new({required this.message, required this.onDismiss});

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
