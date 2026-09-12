import 'dart:async';

import 'package:better_phenikaa_schedule/app/app.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _StartupCredit(child: BetterPhenikaaScheduleApp()));
}

class _StartupCredit extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_StartupCredit> createState() => _StartupCreditState();
}

class _StartupCreditState extends State<_StartupCredit> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    unawaited(_hideCredit());
  }

  Future<void> _hideCredit() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: widget.child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: const Text(
                  'devbycooc',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9AA5BD),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .35,
                    decoration: TextDecoration.none,
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
