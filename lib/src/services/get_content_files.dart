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

  ///
  static Future<List<Map<String, dynamic>>> regOfLogin() async {

    List<Map<String, dynamic>> registros = [];

    final pathTo = await GetPaths.getFileByPath('connpass');
    final pathLog = await GetPaths.getFileByPath('connwho');
    final regs = File(pathTo);
    final logs = File(pathLog);
    if(regs.existsSync()) {

      final mRegs = Map<String, dynamic>.from( json.decode(regs.readAsStringSync()) );
      late final List<Map<String, dynamic>> llogs;
      if(regs.existsSync()) {
        llogs = List<Map<String, dynamic>>.from( json.decode(logs.readAsStringSync()) );
      }else{
        llogs = [];
      }

      mRegs.forEach((key, value) {
        var reg = Map<String, dynamic>.from(value);
        if(llogs.isNotEmpty) {
          reg['logs'] = llogs.where((element) => element['curc'] == reg['curc']).toList();
        }
        registros.add(reg);
      });
    }
    return registros;
  }

  ///
  static Future<bool> deleteRegOfLogin(String curc) async {

    final pathTo = await GetPaths.getFileByPath('connpass');
    final regs = File(pathTo);
    if(regs.existsSync()) {

      Map<String, dynamic> newsRegs = {};
      final mRegs = Map<String, dynamic>.from( json.decode(regs.readAsStringSync()) );
      if(mRegs.isNotEmpty){
        mRegs.forEach((key, value) {
          if(value['curc'] != curc) {
            newsRegs.putIfAbsent(key, () => value);
          }
        });
      }
      if(newsRegs.isNotEmpty) {
        regs.writeAsStringSync( json.encode(newsRegs) );
      }
      return true;
    }
    
    return false;
  }

}