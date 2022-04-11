
import 'dart:io';

import '../config/sng_manager.dart';
import '../services/get_paths.dart';
import '../vars/globals.dart';
import 'logs_entity.dart';


class Logs {

  static final Globals globals = getSngOf<Globals>();

  ///
  static LogsEntity initLog() {

    LogsEntity entity = LogsEntity();
    // entity.call = globals.call;
    // entity.func = globals.fnc;
    entity.timeIni = DateTime.now().millisecond;
    return entity;
  }

  ///
  static Future<void> finLog(LogsEntity entity) async {

    entity.timeFin = DateTime.now().millisecond;
    final newReg = entity.toFile();
    String path = await GetPaths.getFileByPath('logs');

    File fileLog = File(path);
    if(!fileLog.existsSync()) {
      fileLog.createSync();
    }
    IOSink open = fileLog.openWrite(mode: FileMode.append);
    open.writeln(newReg);
    open.close();
  }

}