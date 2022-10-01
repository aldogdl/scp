
import 'dart:convert';
import 'dart:io';

import '../../services/get_paths.dart';

/// Todo lo que tenga que ver con la gestion de archivos 
class SystemFileScrap {

  static const folder = 'scrap';

  static const fileRadecPiezas = 'radec_piezas.json';
  static const fileRadecMrks   = 'radec_mrks.json';
  static const fileRadecMods   = 'radec_mods.json';
  static const fileAldoPiezas  = 'aldo_piezas.json';
  static const fileAldoMrks    = 'aldo_mrks.json';
  static const fileAldoMods    = 'aldo_mods.json';
  static const fileAnetPiezas  = 'anet_piezas.json';

  /// Construimos el sistema de archivos en caso de no existir
  /// [RETURN] los archivos que no existieron
  static Future<String> chekSystem({required String craw}) async {

    List<String> filesRadec = [
      fileRadecPiezas,
      fileRadecMrks,
      fileRadecMods,
    ];

    List<String> filesAldo = [
      fileAldoPiezas,
      fileAldoMrks,
      fileAldoMods
    ];

    List<String> files = [];

    if(craw == 'radec') {
      files = filesRadec;
    }

    if(craw == 'aldo') {
      files = filesAldo;
    }

    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    if(!dir.existsSync()) {
      return 'Construir Data';
    }else{

      // Creamos los archivos
      for (var i = 0; i < files.length; i++) {
        final file = File('${dir.path}$s${files[i]}');
        if(!file.existsSync()) {
          return 'No se encotró ${files[i]}';
        }else{
          final content = file.readAsStringSync();
          if(content.isEmpty) {
            return 'Recuperar datos para ${files[i]}';
          }
        }
      }
    }

    return 'ok';
  }

  /// Construimos el sistema de archivos en caso de no existir
  /// [RETURN] los archivos que no existieron
  static Future<void> buildFileSystem() async {

    List<String> files = [
      fileRadecPiezas,
      fileRadecMrks,
      fileRadecMods,

      fileAldoPiezas,
      fileAldoMrks,
      fileAldoMods
    ];

    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    if(!dir.existsSync()) {
      dir.createSync();
    }

    // Creamos los archivos
    for (var i = 0; i < files.length; i++) {
      final file = File('${dir.path}$s${files[i]}');
      if(!file.existsSync()) {
        file.createSync();
      }
    }

    return;
  }

  /// Guardamos las piezas recuperadas desde la web de...
  static Future<String> setPiezaBy(String craw, Map<String, dynamic> pza) async {

    var pzasCurrent = getAllPiezasFromFile(craw: craw);
    final has = pzasCurrent.indexWhere( (element) => element['id'] == pza['id']);
    if(has == -1) {
      pzasCurrent.add(pza);
    }else{
      pzasCurrent[has] = pza;
    }

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecPiezas;
        break;
      case 'aldo':
        filename = fileAldoPiezas;
        break;
      case 'anet':
        filename = fileAnetPiezas;
        break;
      default:
    }
    
    return _setFile(filename, pzasCurrent);
  }

  /// Guardamos las piezas recuperadas desde la web de...
  static Future<void> setPiezasBy(String craw, List<Map<String, dynamic>> dt) async {

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecPiezas;
        break;
      case 'aldo':
        filename = fileAldoPiezas;
        break;
      default:
    }
    
    _setFile(filename, dt);
  }

  /// Recuperamos las marcas desde el archivo
  static Future<List<Map<String, dynamic>>> getAllMarcasBy(String craw) async {

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecMrks;
        break;
      case 'aldo':
        filename = fileAldoMrks;
        break;
      default:
    }

    return _getFile(filename);
  }

  /// Guardamos las marcas recuperadas desde la web de...
  static Future<List<Map<String, dynamic>>> getAllModelosByIdMarca(String craw, String idMrk) async {

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecMods;
        break;
      case 'aldo':
        filename = fileAldoMods;
        break;
      default:
    }

    Map<String, dynamic> mods = _getFileContentMap(filename);
    if(idMrk != '0') {
      return List<Map<String, dynamic>>.from(mods[idMrk]);
    }
    return [];
  }

  /// Guardamos las marcas recuperadas desde la web de...
  static Future<Map<String, dynamic>> getAllModelosBy(String craw) async {

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecMods;
        break;
      case 'aldo':
        filename = fileAldoMods;
        break;
      default:
    }

    return _getFileContentMap(filename);
  }

  /// Guardamos las marcas recuperadas desde la web de...
  static Future<void> setMarcasBy(String craw, List<Map<String, dynamic>> dt) async {

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecMrks;
        break;
      case 'aldo':
        filename = fileAldoMrks;
        break;
      default:
    }

    _setFile(filename, dt);
    return;
  }

  /// Guardamos los modelos recuperadas desde la web de...
  static Future<void> setModelosBy(String craw, Map<String, dynamic> dt) async {

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecMods;
        break;
      case 'aldo':
        filename = fileAldoMods;
        break;
      default:
    }

    _setFile(filename, dt);
    return;
  }

  ///
  static List<Map<String, dynamic>> getPiezasToList(String craw) {

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecPiezas;
        break;
      case 'aldo':
        filename = fileAldoPiezas;
        break;
      case 'anet':
        filename = fileAnetPiezas;
        break;
      default:
    }

    List<Map<String, dynamic>> pzasR = [];
    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    final file = File('${dir.path}$s$filename');

    if(file.existsSync()) {

      return List<Map<String, dynamic>>.from(
        json.decode(file.readAsStringSync())
      );
    }

    return pzasR;
  }

  ///
  static List<Map<String, dynamic>> getAllPiezasFromFile({String craw = 'radec'}) {

    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecPiezas;
        break;
      case 'aldo':
        filename = fileAldoPiezas;
        break;
      case 'anet':
        filename = fileAnetPiezas;
        break;
      default:
    }

    final file = File('${dir.path}$s$filename');

    if(file.existsSync()) {
      return List<Map<String, dynamic>>.from(
        json.decode(file.readAsStringSync())
      );
    }

    return [];
  }

  ///
  static String _setFile(String filename, dynamic dt) {

    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    final file = File('${dir.path}$s$filename');
    if(!file.existsSync()) {
      file.createSync(recursive: true);
    }
    try {
      file.writeAsStringSync(json.encode(dt));
    } catch (_) {
      return 'No se pudo guardar la Pieza en el Archivo';
    }
    return 'ok';
  }

  ///
  static List<Map<String, dynamic>> _getFile(String filename) {

    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    final file = File('${dir.path}$s$filename');
    if(file.existsSync()) {
      return List<Map<String, dynamic>>.from(
        json.decode(file.readAsStringSync())
      );
    }
    return [];
  }

  ///
  static Map<String, dynamic> _getFileContentMap(String filename) {

    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    final file = File('${dir.path}$s$filename');
    if(file.existsSync()) {
      return Map<String, dynamic>.from(
        json.decode(file.readAsStringSync())
      );
    }
    return {};
  }

}