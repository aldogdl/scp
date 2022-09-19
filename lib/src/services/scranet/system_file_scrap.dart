
import 'dart:convert';
import 'dart:io';

import '../../services/get_paths.dart';

/// Todo lo que tenga que ver con la gestion de archivos 
class SystemFileScrap {

  static const folder = 'scrap';

  static const fileRadecPiezas = 'radec_piezas.json';
  static const fileRadecMrks = 'radec_mrks.json';
  static const fileRadecMods = 'radec_mods.json';

  static const fileAldoPiezas = 'aldo_piezas.json';
  static const fileAldoMrks = 'aldo_mrks.json';
  static const fileAldoMods = 'aldo_mods.json';

  /// Construimos el sistema de archivos en caso de no existir
  /// [RETURN] los archivos que no existieron
  static Future<String> chekSystem({required String craw}) async {

    String result = 'ok';

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
      result = 'nuevo';
    }else{
      // Creamos los archivos
      for (var i = 0; i < files.length; i++) {
        final file = File('${dir.path}$s${files[i]}');
        if(!file.existsSync()) {
          result = 'No se encotró ${files[i]}';
        }else{
          final content = file.readAsStringSync();
          if(content.isEmpty) {
            result = 'Recuperar datos para ${files[i]}';
          }
        }
      }
    }

    return result;
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

  /// Guardamos las marcas recuperadas desde la web de...
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
  static Future<Map<String, dynamic>> getAllModelosBy(String craw) async {

    String filename = '';
    switch (craw) {
      case 'radec':
        filename = fileRadecMods;
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
  static List<String> getPiezasToList() {

    List<String> pzasR = [];
    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    final file = File('${dir.path}$s$fileRadecPiezas');

    if(file.existsSync()) {

      final pzas = List<Map<String, dynamic>>.from(
        json.decode(file.readAsStringSync())
      );

      if(pzas.isNotEmpty) {
        for (var i = 0; i < pzas.length; i++) {
          if(!pzasR.contains(pzas[i]['value'])) {
            pzasR.add(pzas[i]['value'].toString().toUpperCase().trim());
          }
        }
      }
    }

    return pzasR;
  }

  ///
  static List<Map<String, dynamic>> getAllPiezasFromFile() {

    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    final file = File('${dir.path}$s$fileRadecPiezas');

    if(file.existsSync()) {
      return List<Map<String, dynamic>>.from(
        json.decode(file.readAsStringSync())
      );
    }

    return [];
  }

  ///
  static _setFile(String filename, dynamic dt) {

    final s = GetPaths.getSep();
    final root = GetPaths.getPathRoot();
    final dir = Directory('$root$s$folder');

    final file = File('${dir.path}$s$filename');
    if(!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(json.encode(dt));
    return;
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