import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class GetPaths {

  static const String package = 'autoparnet';
  static const String nameFilePathsP = 'paths_prod.json';
  static p.Style estiloPlatform = p.Style.windows;

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
      if(key == 'all') {

        return {
          'port_harbi': mapa['portHarbi'],
          'port_server': mapa['portServer'],
          'ip_harbi': mapa['ip_harbi'],
          'base_r': mapa['server_remote'],
          'base_l': mapa['server_local'],
        };
      }else{
        if (mapa.containsKey(key)) {
          return {
            'port_harbi': mapa['portHarbi'],
            'port_server': mapa['portServer'],
            'ip_harbi': mapa['ip_harbi'],
            'base_r': mapa['server_remote'],
            'base_l': mapa['server_local'],
            'uri': mapa[key],
          };
        }
      }
    }
    return {};
  }

  ///
  static Future<String> getFileByPath(String path) async {
    
    final paths = await _getFromFilePathsProd(path);
    if(paths.containsKey('uri')) {
      return '${paths['uri']}';
    }
    return '';
  }

  ///
  static Future<String> getDominio({bool isLocal = true}) async {
    final paths = await _getFromFilePathsProd('portServer');
    return (isLocal) ? paths['base_l'] : paths['base_r'];
  }

  ///
  static List<Map<String, dynamic>> getContentFileAvos() {

    final namefile = 'data_share${getSep()}avos.json';
    final root = getPathRoot();
    final file = File('$root${getSep()}$namefile');
    if(!file.existsSync()) {
      file.createSync(recursive: true);
      return [];
    }
    return List<Map<String, dynamic>>.from(json.decode(file.readAsStringSync()));
  }

  ///
  static void setContentFileAvos(List<Map<String, dynamic>> avos) {

    final namefile = 'data_share${getSep()}avos.json';
    final root = getPathRoot();
    final file = File('$root${getSep()}$namefile');
    file.writeAsStringSync(json.encode(avos));
  }

  ///
  static void setFileCotzFromHarbi(Map<String, dynamic> cotz) {

    final namefile = 'data_share${getSep()}cotz_scp.json';
    final root = getPathRoot();
    final file = File('$root${getSep()}$namefile');
    if(file.existsSync()) {

      final current = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));

      // Tratar con los cotizadores
      final cotizad = List<Map<String, dynamic>>.from(current['cotz']);
      final newsCtz = List<Map<String, dynamic>>.from(cotz['cotz']);
      for (var i = 0; i < newsCtz.length; i++) {
        final has = cotizad.indexWhere((c) => c['c_id'] == newsCtz[i]['c_id']);
        if(has != -1) {
          cotizad[has] = newsCtz[i];
        }else{
          cotizad.add(newsCtz[i]);
        }
      }
      current['cotz'] = cotizad;

      // Tratar con los filtros
      if(current.containsKey('filtros')) {

        final filters = Map<String, dynamic>.from(current['filtros']);
        final newsFil = Map<String, dynamic>.from(cotz['filtros']);
        newsFil.forEach((key, value) {
          if(filters.containsKey(key)) {
            filters[key] = value;
          }else{
            filters.putIfAbsent(key, () => value);
          }
        });
        current['filtros'] = filters;
      }

      file.writeAsStringSync(json.encode(current));

    }else{
      file.writeAsStringSync(json.encode(cotz));
    }
  }

  ///
  static Map<String, dynamic> getCotzFromFileById(String idC) {

    final namefile = 'data_share${getSep()}cotz_scp.json';
    final root = getPathRoot();
    final file = File('$root${getSep()}$namefile');
    if(file.existsSync()) {

      final current = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
      final cotizad = List<Map<String, dynamic>>.from(current['cotz']);
      final has = cotizad.indexWhere((c) => c['c_id'] == idC);
      if(has != -1) { return cotizad[has]; }
    }
    
    return {};
  }

  ///
  static List<Map<String, dynamic>> getCotzFromFileByIds(List<int> idsC) {

    final namefile = 'data_share${getSep()}cotz_scp.json';
    final root = getPathRoot();
    final file = File('$root${getSep()}$namefile');
    List<Map<String, dynamic>> results = [];

    if(file.existsSync()) {

      final current = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
      final cotizad = List<Map<String, dynamic>>.from(current['cotz']);
      for (var i = 0; i < idsC.length; i++) {
        final has = cotizad.indexWhere((c) => c['c_id'] == idsC[i]);
        if(has != -1) {
          results.add(cotizad[has]);
        }else{
          results.add({
            'c_id': idsC[i], 'e_nombre':'recovery', 'c_nombre': 'recovery'
          });
        }
      }
    }

    return results;
  }

  ///
  static Future<String> getUriCtc(String uri, {bool isLocal = true}) async {

    Map<String, dynamic> uriPath = await _getFromFilePathsProd('all');
    final paths = {
      'set_filtro': 'scp/cotizadores/set-filtro',
      'get_filtros_emp': 'scp/cotizadores/get-filtro-by-emp',
      'del_filtro_by_id': 'scp/cotizadores/del-filtro-by-id',
    };

    String base = '${uriPath['base_l']}${paths[uri]}/';
    if (!isLocal) {
      base = '${uriPath['base_r']}${paths[uri]}/';
    }
    return base;
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

  /// Retornamos el URI del path a la ap de harbi solicitada
  static Future<Uri> getUriApiHarbi(String uri, String query) async {

    Map<String, dynamic> uriPath = await _getFromFilePathsProd(uri);
    if(query.isNotEmpty) {
      query = '/$query';
    }
    return Uri.http('${uriPath['ip_harbi']}:${uriPath['port_harbi']}', '${uriPath['uri']}$query');
  }

  /// Retornamos el String del path a la ap de harbi solicitada
  static Future<String> getPathToApiHarbi(String uri) async {

    Map<String, dynamic> uriPath = await _getFromFilePathsProd(uri);
    return '${uriPath['ip_harbi']}:${uriPath['port_harbi']}/${uriPath['uri']}';
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
