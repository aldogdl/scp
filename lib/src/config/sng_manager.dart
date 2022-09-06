import 'package:get_it/get_it.dart';

import '../services/status/stts_cache.dart';
import '../vars/globals.dart';
import '../vars/ordenes_cache.dart';

GetIt getSngOf = GetIt.instance;

void sngManager() {

  getSngOf.registerLazySingleton(() => Globals());
  getSngOf.registerLazySingleton(() => SttsCache());
  getSngOf.registerLazySingleton(() => OrdenesCache());
}