import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:scp/src/services/get_paths.dart';

const fld = 'cotz_tmp';

/// Guardamos la orden que se va a procesar en un archivo
Future<bool> ctzSetOrdenInFile(Map<String, dynamic> orden) async {

  final sep = GetPaths.getSep();
  final root = GetPaths.getPathRoot();
  final dir = Directory('$root$sep${orden['id']}$sep');
  if(!dir.existsSync()) {
    dir.create(recursive: true);
  }
  const nomFile = 'orden';
  final o = File('${dir.path}$sep$nomFile');
  try {
    o.writeAsStringSync(json.encode(orden));
  } catch (e) {
    return false;
  }
  return true;
}