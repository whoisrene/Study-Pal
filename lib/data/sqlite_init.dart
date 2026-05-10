import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void configureSqfliteFactoriesForDesktop() {
  assert(!kIsWeb, 'SQLite FFI init is not meant for web builds.');
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
