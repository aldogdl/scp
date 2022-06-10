import 'package:get_it/get_it.dart';

import '../vars/globals.dart';
import '../services/status/stts_cache.dart';

GetIt getSngOf = GetIt.instance;

void sngManager() {

  getSngOf.registerLazySingleton(() => Globals());
  getSngOf.registerLazySingleton(() => SttsCache());
}