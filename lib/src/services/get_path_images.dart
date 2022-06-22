import 'package:scp/src/services/get_paths.dart';

class GetPathImages {
  
  ///
  static Future<String> getPathPzaTmp(String foto) async {

    const carpeta = 'to_orden_tmp/';
    final dom = await GetPaths.getDominio(isLocal: false);
    return '$dom$carpeta$foto';
  }
  
  ///
  static Future<String> getPathToLogoMarcaOf(String marca) async {

    const carpeta = 'mrks_logos/';
    final dom = await GetPaths.getDominio();
    return '$dom$carpeta$marca';
  }


}