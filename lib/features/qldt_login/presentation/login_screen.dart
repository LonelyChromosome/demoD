import 'package:better_phenikaa_schedule/core/presentation/shared_widgets.dart';
import 'package:flutter/material.dart';

class QldtLoginScreen extends StatelessWidget {
  const new({required this.onLogin, required this.supportsLive, super.key});

  final VoidCallback onLogin;
  final bool supportsLive;

  @override
  Widget build(BuildContext context) {
    return PhoneSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 58, 32, 30),
        child: Column(
          children: <Widget>[
            const Spacer(),
            const AppMark(size: 62),
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
                    const MicrosoftMark(),
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
            const SizedBox(height: 4),
            const Text(
              'DevbyCooc',
              style: TextStyle(
                color: Color(0xFF9AA5BD),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
