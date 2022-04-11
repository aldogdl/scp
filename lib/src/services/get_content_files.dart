import 'dart:convert';
import 'dart:io';

import 'package:scp/src/services/get_paths.dart';

class GetContentFile {

  ///
  static Future<List<String>> cargos() async {

    String pathTo = await GetPaths.getFileByPath('cargos');
    final File cargosF = File(pathTo);
    if(cargosF.existsSync()) {
      return List<String>.from( json.decode(cargosF.readAsStringSync()) );
    }
    return [];
  }

  ///
  static Future<List<Map<String, dynamic>>> roles() async {

    String pathTo = await GetPaths.getFileByPath('roles');
    final File cargosF = File(pathTo);
    if(cargosF.existsSync()) {
      return List<Map<String, dynamic>>.from( json.decode(cargosF.readAsStringSync()) );
    }
    return [];
  }
}