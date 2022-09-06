import 'dart:math';

import '../services/get_paths.dart';
import '../config/sng_manager.dart';
import '../vars/globals.dart';

class GetPathImages {
  
  static final Globals _globals = getSngOf<Globals>();

  ///
  static String getBase() {

    var base = 'http://${_globals.ipHarbi}/autoparnet/public_html/';
    if(_globals.ipDbs.isNotEmpty) {
      if(_globals.ipDbs.containsKey('base_l')) {
        base = _globals.ipDbs['base_l'];
      }
    }
    return base;
  }

  ///
  static Future<String> getPathPzaTmp(String foto) async {

    const carpeta = 'to_orden_tmp/';
    final dom = await GetPaths.getDominio(isLocal: false);
    return '$dom$carpeta$foto';
  }
  
  ///
  static Future<String> getPathCots(String foto) async {

    const carpeta = 'to_orden_rsp/';
    final dom = await GetPaths.getDominio(isLocal: false);
    return '$dom$carpeta$foto';
  }
  
  ///
  static Future<String> getPathToLogoMarcaOf(String marca) async {

    const carpeta = 'mrks_logos/';
    return '${getBase()}$carpeta$marca';
  }

  ///
  static Future<String?> getPathPortada() async {

    final res = await GetPaths.getFileByPath('portadas');
    int? cant = int.tryParse(res);
    final base = '${getBase()}portadas/';
    if(cant != null) {
      final ran = Random();
      int azar = ran.nextInt(cant);
      azar = (azar == 0) ? 1 : azar;
      return '$base$azar.jpg';
    }
    return '$base${"1.jpg"}';
  }
}