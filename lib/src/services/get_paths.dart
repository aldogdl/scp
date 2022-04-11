import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/sng_manager.dart';
import '../vars/globals.dart';

class GetPaths {

  static final Globals globals = getSngOf<Globals>();

  static String env  = 'dev';
  static const int _port = 80;
  static const String package = 'autoparnet';
  static const String nameFilePaths = 'paths_dev.json';
  static const String nameFilePathsP = 'paths_prod.json';
  static const Map<String, dynamic> getPrefix = {
    'cotizador':'ctz',
    'solicitante':'cli'
  };

  ///
  static Future<int> getPort(String from) async {

    if(from == 'self') {
      return _port;
    }

    final puerto = await _getFromFilePathsProd(from);
    int? port = int.tryParse('${puerto['data']}');
    if(port != null) {
      return port;
    }
    return _port;
  }

  /// Recuperamos la data del archivo principal de paths
  static Future<Map<String, dynamic>?> getContentFilePaths() async {

    Map<String, dynamic>? pathsFinder;
    File paths = File('${getPathRoot()}${p.context.separator}$nameFilePaths');
    if(paths.existsSync()) {
      pathsFinder = Map<String, dynamic>.from(json.decode(paths.readAsStringSync()));
    }
    return pathsFinder;
  }

  /// Obtenemos el path a root del proyecto
  static String getPathRoot() {
    var context = p.Context(style: p.Style.windows);
    return context.join(Directory.systemTemp.parent.parent.path, 'Roaming', 'com.$package');
  }

  ///
  static Future<void> deleteFilePathsProd() async {

    File paths = File('${getPathRoot()}${p.context.separator}$nameFilePathsP');
    if(paths.existsSync()) {
      paths.deleteSync();
    }
  }

  /// Revisamos la existencia del archivo paths para produccion
  static Future<bool> existFilePathsProd() async {

    File paths = File('${getPathRoot()}${p.context.separator}$nameFilePathsP');
    return paths.existsSync();
  }

  /// Recuperamos la URI segun key desde el archivo de produccion
  static Future<Map<String, dynamic>> _getFromFilePathsProd(String key) async {

    File paths = File('${getPathRoot()}${p.context.separator}$nameFilePathsP');
    if(paths.existsSync()) {
      Map mapa = json.decode( paths.readAsStringSync() );
      if(mapa.containsKey(key)) {
        return {
          'base': mapa['server'],
          'data': mapa[key],
        };
      }
    }
    return {};
  }

  /// Recuperamos la URI segun key desde el archivo de produccion
  static Directory? getPathsFolderTo(String key) {

    Directory? pathFolder = Directory('${getPathRoot()}${p.context.separator}$key');
    return pathFolder;
  }

  ///
  static Future<String> getFileByPath(String path) async {
    final paths = await _getFromFilePathsProd(path);
    return paths['data'];
  }

  ///
  static Future<String> getDominio({isLocal = true}) async {

    if(isLocal && globals.isLocalConn) {
      return 'http://${globals.ipHarbi}:$_port/$package/public_html/';
    }

    final paths = await _getFromFilePathsProd('server');
    return paths['data'];
  }
  
  ///
  static Future<Map<String, dynamic>> getConnectionFtp() async {

    final pathDt = await _getFromFilePathsProd('ftp');
    return {
      'url': pathDt['base'],
      'u'  : pathDt['data']['u-$env'],
      'p'  : pathDt['data']['p-$env'],
      'ssl': (env == 'dev') ? false : true
    };
  }
  
  ///
  static Future<Map<String, dynamic>> getBaseLocalAndRemoto() async {

    return {
      'local'   : await getDominio(),
      'remoto'  : await getDominio(isLocal: false),
      'my-ip'   : globals.ipHarbi,
      'prto-loc': _port,
    };
  }

  ///
  static Future<String> getUri(String uri, {bool isLocal = true}) async {

    Map<String, dynamic> uriPath = await _getFromFilePathsProd(uri);
    String base = '';
    if(!isLocal) {
      base = '${uriPath['base']}${uriPath['data']}/';
    }else{
      base = '${await getDominio()}${uriPath['data']}/';
    }
    return base;
  }


}