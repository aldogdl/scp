import 'dart:io';
import 'dart:convert';

import '../../services/get_paths.dart';

class SystemFilePush {

  // Push recien llgedos con exito "scp_pushin"
  // Push ya procesados por el scp "scp_pushout"
  // Push recien llgedos con con error de recuperacion "scp_pushlost"
  static Map<String, dynamic> foldersPush = {
    'pushin' : 'scp_pushin', 'pushlost' : 'scp_pushlost'
  };
  // Push que se deben procesar antes que otros y son intrusivos "scp_pushalta"
  // Push que se deben procesar lo antes posible pero no son intrusivos "scp_pushmedia"
  // Push que pueden esperar hasta el final sin problema "scp_pushbaja"
  static Map<String, dynamic> foldersPriority = {
    'alta' : 'scp_pushalta', 'media': 'scp_pushmedia', 'baja' : 'scp_pushbaja'
  };
  static List<String> sufix = ['t1.json', 't2.json', 't3.json', 't4.json'];
  
  ///
  static makeSystemFiles() {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    for (var folder in foldersPriority.values) {
      var dir = Directory('$root$sep$folder');
      if(!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }
    for (var folder in foldersPush.values) {
      var dir = Directory('$root$sep$folder');
      if(!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }
  }

  /// Recuperamos el contenido del archivo solicitado
  static Map<String, dynamic> getContentIn(String folder, String filename) {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    
    final path = '$root$sep$folder$sep$filename';
    final file = File(path);
    if(file.existsSync()) {
      return Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
    }
    return {};
  }

  /// Guardamos el contenido del archivo indicado por parametro
  static void setContentIn(String folder, String filename, Map<String, dynamic> data) {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    
    if(filename.startsWith('centinela_update')) {
      final partes = filename.split('-');
      int indx = sufix.indexWhere((element) => element == partes.last);
      if(indx != -1) {
        filename = filename.replaceAll('push_notification-${sufix[indx]}', '${data['data']['newv']}.json');
      }else{
        filename = filename.replaceAll('push_notification', data['data']['newv']);
      }
    }
    final path = '$root$sep$folder$sep$filename';
    
    final file = File(path);
    if(!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(json.encode(data));
  }

  /// Eliminamos el archivo del folder
  static void delFileOf(String folder, String filename) {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final path = '$root$sep$folder$sep$filename';
    
    final file = File(path);
    if(file.existsSync()) {
      file.deleteSync(recursive: true);
    }
  }

  /// Para ordenar por prioridad cada push en sus respectivos folders
  static void sortPerPriority() {

    String folder = foldersPush['pushin'];
    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final lst = getListFilesBy(folder);

    if(lst.isNotEmpty) {

      for (var i = 0; i < lst.length; i++) {
        
        final path = '$root$sep$folder$sep${lst[i]}';

        final file = File(path);
        if(file.existsSync()) {
          final content = Map<String, dynamic>.from(
            json.decode(file.readAsStringSync())
          );

          if(content.containsKey('priority')) {
            final folderTo = foldersPriority[content['priority']];            
            final pathTo = '$root$sep$folderTo$sep${lst[i]}';
            file.renameSync(pathTo);
          }
        }
      }
    }

    return;
  }

  ///
  static Map<String, String> cuantificar(Map<String, String> currents) {
    
    int tot = 0;
    for (var folder in foldersPush.values) {
      final cant = getCountFilesByFolder(folder);
      tot = tot + cant;
      switch (folder) {
        case 'scp_pushin':
          currents['bandeja'] = '$cant';
          break;
        case 'scp_pushlost':
          currents['pap'] = '$cant';
          break;
        default:
      }
    }

    for (var folder in foldersPriority.values) {
      final cant = getCountFilesByFolder(folder);
      tot = tot + cant;
      switch (folder) {
        case 'scp_pushalta':
          currents['alta'] = '$cant';
          break;
        case 'scp_pushmedia':
          currents['media'] = '$cant';
          break;
        case 'scp_pushbaja':
          currents['baja'] = '$cant';
          break;
        default:
      }
    }

    currents['all'] = '$tot';
    return currents;
  }

  ///
  static Map<String, String> cleanAll(Map<String, String> currents) {
    
    for (var folder in foldersPush.values) {
      ereaseContentFilesByFolder(folder);
      switch (folder) {
        case 'scp_pushin':
          currents['bandeja'] = '0';
          break;
        case 'scp_pushlost':
          currents['pap'] = '0';
          break;
        default:
      }
    }

    for (var folder in foldersPriority.values) {

      ereaseContentFilesByFolder(folder);
      switch (folder) {
        case 'scp_pushalta':
          currents['alta'] = '0';
          break;
        case 'scp_pushmedia':
          currents['media'] = '0';
          break;
        case 'scp_pushbaja':
          currents['baja'] = '0';
          break;
        default:
      }
    }

    currents['all'] = '0';
    return currents;
  }

  /// Recuperamos la lista de archivos dentro del folder por parametro
  static void ereaseContentFilesByFolder(String folder) {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir  = Directory('$root$sep$folder');
    if(dir.existsSync()) {
      final lstFiles = dir.listSync().toList();
      lstFiles.map((e) => e.deleteSync()).toList();
    }
    return;
  }

  /// Recuperamos el cuantificado de los archivos dentro del folder por parametro
  static int getCountFilesByFolder(String folder) {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir  = Directory('$root$sep$folder');
    if(dir.existsSync()) {
      final lstFiles = dir.listSync().toList();
      return lstFiles.length;
    }
    return 0;
  }

  /// Recuperamos la lista de archivos dentro del folder por parametro
  static List<String> getListFilesBy(String folder, {bool getForWork = false}) {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final lstFiles = Directory('$root$sep$folder').listSync().toList();
    List<String> currents = [];
    for (var i = 0; i < lstFiles.length; i++) {
      
      if(!lstFiles[i].path.contains('-echo.')) {
        final partes = lstFiles[i].path.split(sep);
        final filename = partes.removeLast();
        final nFilename = filename.replaceAll('.json', '-echo.json');
        if(getForWork) {
          currents.add(nFilename);
          lstFiles[i].renameSync('${ partes.join(sep) }$sep$nFilename');
        }else{
          currents.add(filename);
        }
      }
    }
    return currents;
  }

  /// Creamos un archivo de notificacion para informar nueva asignacion
  static void crearFileNewAsign(List<String> ordenesNews, int user) {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$sep${foldersPriority['alta']}');
    final metas = getSchemaMain(
      priority: 'alta',
      secc: 'notiff',
      titulo: 'ORDEN(es) ASIGNADA(s)',
      descrip: 'Se te han otorgado la(s) orden(es) ${ordenesNews.join(', ')}',
      data: {}
    );

    final f = '${dir.path}$sep$user-${DateTime.now().millisecondsSinceEpoch}.json';
    File(f).writeAsStringSync(json.encode(metas));
    return;
  }

  /// Recuperamos todos los metadatos para mostrarce en consola
  static List<Map<String, dynamic>> getMetadatosBy(String subF) {

    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();

    String folder = '';
    if(foldersPush.containsKey(subF)) {
      folder = foldersPush[subF];
    }
    if(foldersPriority.containsKey(subF)) {
      folder = foldersPriority[subF];
    }

    List<Map<String, dynamic>> currents = [];
    final lstFiles = Directory('$root$sep$folder').listSync().toList();
    if(lstFiles.isNotEmpty) {
      for (var i = 0; i < lstFiles.length; i++) {

        final file = File(lstFiles[i].path);
        final content = file.readAsStringSync();
        if(content.isNotEmpty) {
          var map = Map<String, dynamic>.from( json.decode(content) );
          map.remove('data');
          currents.insert(0, map);
        }
      }
    }
    return currents;
  }

  /// Guardamos archivos en la carpeta de perdidos
  static void setFilesLost(List<String> lstFiles) {

    const subF = 'pushlost';
    final sep = GetPaths.getSep();
    final root = GetPaths.getPathRoot();

    String folder = '';
    if(foldersPush.containsKey(subF)) {
      folder = foldersPush[subF];
    }

    final dir = Directory('$root$sep$folder');
    if(dir.existsSync()) {
      for (var i = 0; i < lstFiles.length; i++) {

        final file = File('${dir.path}$sep${lstFiles[i]}');
        if(!file.existsSync()) {
          file.writeAsStringSync('');
        }
      }
    }
    return;
  }
  
  ///
  static Map<String, dynamic> getSchemaMain({
    required String priority,
    required String secc,
    required String titulo,
    required String descrip,
    required Map<String, dynamic> data
  }) {

    return {
      'secc'    : secc,
      'priority': priority,
      'titulo'  : titulo,
      'descrip' : descrip,
      'sended'  : DateTime.now().toIso8601String(),
      'data'    : data,
    };
  }
}