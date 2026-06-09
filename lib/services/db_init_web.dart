import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// On web, route sqflite through the IndexedDB-backed ffi web factory.
void initDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
