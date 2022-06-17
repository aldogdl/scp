import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class GetPaths {

  static const String package = 'autoparnet';
  static const String nameFilePathsP = 'paths_prod.json';
  static p.Style estiloPlatform = p.Style.windows;

  // static final Globals globals = getSngOf<Globals>();
  // static String env = 'dev';

  // static const String nameFilePaths = 'paths_dev.json';
  // static const Map<String, dynamic> getPrefix = {
  //   'cotizador': 'ctz',
  //   'solicitante': 'cli'
  // };

  // ///
  // static Future<int> getPort(String from) async {
  //   final puerto = await _getFromFilePathsProd(from);

  //   int? port = int.tryParse('${puerto['uri']}');
  //   if (port != null) {
  //     return port;
  //   }
  //   return 80;
  // }

  // /// Recuperamos la data del archivo principal de paths
  // static Future<Map<String, dynamic>?> getContentFilePaths({bool isProd = false}) async {
    
  //   List<String> sep = [getSep()];
  //   Map<String, dynamic>? pathsFinder;
  //   late File paths;
  //   if (!isProd) {
  //     String assets = '${p.context.current}${sep.first}assets${sep.first}';
  //     paths = File('$assets$nameFilePaths');
  //   } else {
  //     paths = File('${getPathRoot()}${sep.first}$nameFilePathsP');
  //   }
  //   if (paths.existsSync()) {
  //     pathsFinder =
  //         Map<String, dynamic>.from(json.decode(paths.readAsStringSync()));
  //   }
  //   return pathsFinder;
  // }

  // ///
  // static Future<void> deleteFilePathsProd() async {
  //   File paths = File('${getPathRoot()}${getSep()}$nameFilePathsP');
  //   if (paths.existsSync()) {
  //     paths.deleteSync();
  //   }
  // }

  // /// Guardamos la ip que apunta a la base de datos local
  // static Future<Map<String, dynamic>> setBaseDbLocal(String ip) async {
    
  //   File paths = File('${getPathRoot()}${getSep()}$nameFilePathsP');
  //   if (paths.existsSync()) {
  //     Map mapa = json.decode(paths.readAsStringSync());
  //     if (mapa.containsKey('server_local')) {
  //       if (mapa['server_local'].toString().contains('_ip_')) {
  //         mapa['server_local'] =
  //             mapa['server_local'].toString().replaceAll('_ip_', ip);
  //         paths.writeAsStringSync(json.encode(mapa));
  //       }
  //     }
  //   }
  //   return {};
  // }

  // /// Recuperamos la URI segun key desde el archivo de produccion
  // static Directory? getPathsFolderTo(String key) {
  //   Directory? pathFolder = Directory('${getPathRoot()}${getSep()}$key');
  //   return pathFolder;
  // }

  // ///
  // static Future<Map<String, dynamic>> getConnectionFtp(
  //   {bool isLocal = true}
  // ) async {

  //   final pathDt = await _getFromFilePathsProd('ftp');
  //   String sufix = (isLocal) ? 'l' : 'r';
  //   return {
  //     'url': pathDt['base_$sufix'],
  //     'u': pathDt['uri']['u_$env'],
  //     'p': pathDt['uri']['p_$env'],
  //     'ssl': true
  //   };
  // }

  // ///
  // static Future<Map<String, dynamic>> getBaseLocalAndRemoto() async {

  //   final paths = await _getFromFilePathsProd('portServer');

  //   return {
  //     'local': paths['base_l'],
  //     'remoto': paths['base_r'],
  //     'ipHarbi': globals.ipHarbi,
  //     'ptoHarbi': globals.portHarbi,
  //     'pto-loc': paths['uri'],
  //   };
  // }

  /// Obtenemos el separador del sistema
  static String getSep() {
    var context = p.Context(style: estiloPlatform);
    return context.separator;
  }

  /// Obtenemos el path a root del proyecto
  static String getPathRoot() {

    var context = p.Context(style: estiloPlatform);
    return context.join(
      Platform.environment['APPDATA']!, 'com.$package'
    );
  }

  /// Obtenemos el path a root del proyecto
  static void existeFileSystemRoot() {
    
    final dir = Directory(getPathRoot());
    if(!dir.existsSync()) {
      dir.createSync();
    }
  }

  /// Revisamos la existencia del archivo paths para produccion
  static Future<String> existFilePathsProd() async {
    File paths = File('${getPathRoot()}${getSep()}$nameFilePathsP');
    if(paths.existsSync()) {
      final content = json.decode(paths.readAsStringSync());
      return content['ver'];
    }
    return '';
  }

  ///
  static Future<String> setPathsProduction(Map<String, dynamic> paths) async {

    final appData = Platform.environment['APPDATA'];
    final sep = getSep();
    if(paths.isNotEmpty) {
      final file = File('${getPathRoot()}$sep$nameFilePathsP');
      paths.forEach((key, value) {
        final valorTipo = value.runtimeType;
        if(valorTipo == String) {
          if(key != 'palcla' && value.contains(paths['palcla'])) {
            paths[key] = value.replaceFirst(paths['palcla'], appData);
          }
        }
      });
      file.writeAsStringSync(json.encode(paths));
      return 'ok';
    }else{
      return 'ERROR, No se recibieron las URIS desde HARBI';
    }
  }

  /// Recuperamos la URI segun key desde el archivo de produccion
  static Future<Map<String, dynamic>> _getFromFilePathsProd(String key) async {

    File paths = File('${getPathRoot()}${getSep()}$nameFilePathsP');
    if (paths.existsSync()) {
      Map mapa = json.decode(paths.readAsStringSync());
      if (mapa.containsKey(key)) {
        return {
          'base_r': mapa['server_remote'],
          'base_l': mapa['server_local'],
          'uri': mapa[key],
        };
      }
    }
    return {};
  }

  ///
  static Future<String> getFileByPath(String path) async {
    
    final paths = await _getFromFilePathsProd(path);
    if(paths.containsKey('uri')) {
      return paths['uri'];
    }
    return '';
  }

  ///
  static Future<String> getDominio({bool isLocal = true}) async {
    final paths = await _getFromFilePathsProd('portServer');
    return (isLocal) ? paths['base_l'] : paths['base_r'];
  }

  ///
  static Future<String> getUri(String uri, {bool isLocal = true}) async {

    Map<String, dynamic> uriPath = await _getFromFilePathsProd(uri);

    String base = '${uriPath['base_l']}${uriPath['uri']}/';
    if (!isLocal) {
      base = '${uriPath['base_r']}${uriPath['uri']}/';
    }
    return base;
  }

  ///
  static Future<String> getApiHarbi(String uri, String ipHarbi) async {

    Map<String, dynamic> uriPath = await _getFromFilePathsProd(uri);
    return 'http://$ipHarbi${uriPath['uri']}/';
  }

  ///
  static Future<void> setDataFixed(String folder, dynamic data) async {

    final dir = await _getFromFilePathsProd(folder);
    final file = File(dir['uri']);
    if(!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(json.encode(data));
  }
}
