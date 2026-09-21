import 'package:better_phenikaa_schedule/features/qldt_login/presentation/qldt_login_web.dart'
    if (dart.library.io) 'qldt_login_mobile.dart'
    as implementation;

import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:flutter/widgets.dart';

bool get supportsLiveQldtLogin => implementation.supportsLiveQldtLogin;

Future<ScheduleSnapshot?> openQldtLogin(BuildContext context) {
  return implementation.openQldtLogin(context);
}

Future<void> clearQldtSession() => implementation.clearQldtSession();
