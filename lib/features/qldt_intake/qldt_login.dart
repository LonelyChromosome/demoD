import 'package:flutter/widgets.dart';

import 'qldt_models.dart';
import 'qldt_login_web.dart'
    if (dart.library.io) 'qldt_login_mobile.dart' as implementation;

bool get supportsLiveQldtLogin => implementation.supportsLiveQldtLogin;

Future<ImportedScheduleData?> openQldtLogin(BuildContext context) {
  return implementation.openQldtLogin(context);
}
