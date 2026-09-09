import 'dart:async';

import 'package:flutter/material.dart';

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
      home: const _DemoRoot(),
    );
  }
}

enum _AppPage { timetable, exam, account }

class _DemoRoot extends StatefulWidget {
  const _DemoRoot();

  @override
  State<_DemoRoot> createState() => _DemoRootState();
}

class _DemoRootState extends State<_DemoRoot> {
  bool _splash = true;
  bool _loggedIn = false;
  bool _panelOpen = false;
  _AppPage _page = _AppPage.timetable;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 950), () {
        if (mounted) {
          setState(() => _splash = false);
        }
      }),
    );
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x140B2259),
                    blurRadius: 36,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _splash
                    ? const _SplashScreen()
                    : !_loggedIn
                        ? _LoginScreen(
                            onLogin: () => setState(() => _loggedIn = true),
                          )
                        : _MainShell(
                            page: _page,
                            panelOpen: _panelOpen,
                            onTogglePanel: () => setState(
                              () => _panelOpen = !_panelOpen,
                            ),
                            onOpenPage: _openPage,
                            onSync: () {
                              setState(() => _panelOpen = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đồng bộ demo hoàn tất. Dữ liệu cũ luôn được giữ an toàn.',
                                  ),
                                ),
                              );
                            },
                            onLogout: () => setState(() {
                              _loggedIn = false;
                              _panelOpen = false;
                              _page = _AppPage.timetable;
                            }),
                          ),
              ),
            ),
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
  const _LoginScreen({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return _PhoneSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 78, 32, 34),
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
            const SizedBox(height: 40),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _MicrosoftMark(),
                    SizedBox(width: 14),
                    Text(
                      'Đăng nhập QLĐT\n(Microsoft)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.lock_outline, size: 17, color: Color(0xFF8290AF)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Dữ liệu chỉ lưu trên thiết bị của bạn',
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
    required this.page,
    required this.panelOpen,
    required this.onTogglePanel,
    required this.onOpenPage,
    required this.onSync,
    required this.onLogout,
  });

  final _AppPage page;
  final bool panelOpen;
  final VoidCallback onTogglePanel;
  final ValueChanged<_AppPage> onOpenPage;
  final VoidCallback onSync;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final child = switch (page) {
      _AppPage.timetable => const _TimetableScreen(),
      _AppPage.exam => const _ExamScreen(),
      _AppPage.account => _AccountScreen(onLogout: onLogout),
    };

    return _PhoneSurface(
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: child),
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
              child: AnimatedRotation(
                turns: panelOpen ? .125 : 0,
                duration: const Duration(milliseconds: 220),
                child: Icon(panelOpen ? Icons.close : Icons.grid_view_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableScreen extends StatelessWidget {
  const _TimetableScreen();

  static const _items = <_ScheduleItem>[
    _ScheduleItem(
      time: '06:45',
      title: 'Thiết kế web nâng cao',
      room: 'A6-101',
      range: '06:45 - 09:25',
      accent: Color(0xFF4A89FF),
    ),
    _ScheduleItem(
      time: '09:30',
      title: 'Lập trình mobile',
      room: 'A6-205',
      range: '09:30 - 12:10',
      accent: Color(0xFF32C489),
    ),
    _ScheduleItem(
      time: '13:00',
      title: 'Phân tích & thiết kế hệ thống',
      room: 'A6-105',
      range: '13:00 - 15:40',
      accent: Color(0xFFFF941A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _TopTitle(title: 'Lịch học'),
          const SizedBox(height: 24),
          const _DateNavigator(label: 'Thứ Tư, 26 tháng 8'),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 82),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _ScheduleCard(item: _items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamScreen extends StatelessWidget {
  const _ExamScreen();

  static const _exams = <_ExamItem>[
    _ExamItem(day: '26', month: 'THG 8', title: 'Lập trình C++', time: '07:30 - 09:00', room: 'Phòng A6-201'),
    _ExamItem(day: '30', month: 'THG 8', title: 'Cơ sở dữ liệu', time: '13:30 - 15:00', room: 'Phòng A5-302'),
    _ExamItem(day: '02', month: 'THG 9', title: 'Kỹ thuật phần mềm', time: '07:30 - 09:00', room: 'Phòng A6-105'),
    _ExamItem(day: '09', month: 'THG 9', title: 'Mạng máy tính', time: '13:30 - 15:00', room: 'Phòng A6-206'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _TopTitle(title: 'Lịch thi'),
          const SizedBox(height: 20),
          const _SegmentTabs(),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 82),
              itemCount: _exams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ExamCard(item: _exams[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _TopTitle(title: 'Tài khoản'),
          const SizedBox(height: 34),
          const Row(
            children: <Widget>[
              CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFF3F76DC),
                child: Icon(Icons.person_rounded, color: Colors.white, size: 48),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Nguyễn Văn A',
                      style: TextStyle(
                        color: Color(0xFF102B73),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text('23xxxxxxx', style: TextStyle(color: Color(0xFF7180A0))),
                    SizedBox(height: 4),
                    Text(
                      'abc@st.phenikaa-uni.edu.vn',
                      style: TextStyle(color: Color(0xFF7180A0), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const _InfoPanel(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
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
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF397CF6),
          selected: page == _AppPage.timetable,
          onTap: () => onOpenPage(_AppPage.timetable),
        ),
        const SizedBox(height: 12),
        _PanelAction(
          label: 'Lịch thi',
          icon: Icons.description_rounded,
          color: const Color(0xFF2CC980),
          selected: page == _AppPage.exam,
          onTap: () => onOpenPage(_AppPage.exam),
        ),
        const SizedBox(height: 12),
        _PanelAction(
          label: 'Đồng bộ',
          icon: Icons.sync_rounded,
          color: const Color(0xFFFF9D14),
          selected: false,
          onTap: onSync,
        ),
        const SizedBox(height: 12),
        _PanelAction(
          label: 'Tài khoản',
          icon: Icons.person_outline_rounded,
          color: const Color(0xFF8158DC),
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
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 7, 7, 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF2F6FF) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x180B2259), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF23355E),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 21),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopTitle extends StatelessWidget {
  const _TopTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102B73),
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const Icon(Icons.calendar_month_outlined, color: Color(0xFF1647B6), size: 23),
      ],
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.chevron_left_rounded, color: Color(0xFF244A9F)),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF23355E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B9AB7)),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item});

  final _ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x100B2259), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(width: 4, color: item.accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 64,
                    child: Text(
                      item.time,
                      style: const TextStyle(
                        color: Color(0xFF143B98),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF18336F),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _MetaLine(icon: Icons.location_on_outlined, text: item.room),
                        const SizedBox(height: 6),
                        _MetaLine(icon: Icons.schedule_rounded, text: item.range),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        Icon(icon, size: 15, color: const Color(0xFF7182A5)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Color(0xFF66799F), fontSize: 12)),
      ],
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2E6DEC), width: 2)),
            ),
            child: const Text(
              'Sắp tới',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF1D5ED8), fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Đã qua',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6E7E9E), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.item});

  final _ExamItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F0B2259), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  item.day,
                  style: const TextStyle(
                    color: Color(0xFF153C98),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.month,
                  style: const TextStyle(color: Color(0xFF7282A4), fontSize: 10),
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
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF23355E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                _MetaLine(icon: Icons.schedule_rounded, text: item.time),
                const SizedBox(height: 5),
                _MetaLine(icon: Icons.location_on_outlined, text: item.room),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F0B2259), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Dữ liệu trên thiết bị',
            style: TextStyle(color: Color(0xFF33466F), fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 16),
          Text('Cập nhật lần cuối:', style: TextStyle(color: Color(0xFF7282A4), fontSize: 12)),
          SizedBox(height: 4),
          Row(
            children: <Widget>[
              Text(
                '26/08/2025 09:41',
                style: TextStyle(color: Color(0xFF1647B6), fontWeight: FontWeight.w800),
              ),
              Spacer(),
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF25B875)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneSurface extends StatelessWidget {
  const _PhoneSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('phone-surface'),
      height: MediaQuery.sizeOf(context).height.clamp(640, 920).toDouble(),
      child: SafeArea(child: child),
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
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(size * .22),
      ),
      child: Icon(
        Icons.event_available_rounded,
        size: size * .68,
        color: const Color(0xFF12358B),
      ),
    );
  }
}

class _MicrosoftMark extends StatelessWidget {
  const _MicrosoftMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 27,
      height: 27,
      child: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: const <Widget>[
          ColoredBox(color: Color(0xFFF35325)),
          ColoredBox(color: Color(0xFF81BC06)),
          ColoredBox(color: Color(0xFF05A6F0)),
          ColoredBox(color: Color(0xFFFFBA08)),
        ],
      ),
    );
  }
}

class _ScheduleItem {
  const _ScheduleItem({
    required this.time,
    required this.title,
    required this.room,
    required this.range,
    required this.accent,
  });

  final String time;
  final String title;
  final String room;
  final String range;
  final Color accent;
}

class _ExamItem {
  const _ExamItem({
    required this.day,
    required this.month,
    required this.title,
    required this.time,
    required this.room,
  });

  final String day;
  final String month;
  final String title;
  final String time;
  final String room;
}
