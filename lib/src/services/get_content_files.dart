import 'dart:convert';
import 'dart:io';

import '../config/sng_manager.dart';
import '../services/get_paths.dart';
import '../vars/globals.dart';

class GetContentFile {

  static final Globals _globals = getSngOf<Globals>();

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

  /// Cambiar la ip en el archivo local paths
  static Future<void> cambiarIpEnArchivoPath(String nuevaIp) async {

    nuevaIp = nuevaIp.trim();
    final pathRoot = GetPaths.getPathRoot();
    final regs = File('$pathRoot${GetPaths.getSep()}${GetPaths.nameFilePathsP}');
    if(regs.existsSync()) {

      Map<String, dynamic> mRegs = Map<String, dynamic>.from( json.decode(regs.readAsStringSync()) );

      late Uri ipF;
      late Uri ipG;
      String baseT  = (_globals.isLocalConn) ? 'base_l' : 'base_r';
      String baseTF = (_globals.isLocalConn) ? 'server_local' : 'server_remote';
      String ipCF   = mRegs[baseTF];

      ipF = Uri.parse(ipCF);
      ipG = Uri.parse(_globals.ipDbs[baseT]);

      if(ipF.host.trim() != nuevaIp) {
        ipF = ipF.replace(host: nuevaIp, port: _globals.ipDbs['port_s']);
        mRegs[baseTF] = ipF.toString();
        regs.writeAsStringSync(json.encode(mRegs));
      }
      
      if(ipG.host.trim() != nuevaIp) {
        ipG = ipG.replace(host: nuevaIp, port: _globals.ipDbs['port_s']);
        _globals.ipDbs[baseT] = ipG.toString();
      }
    }

  }

  /// REcuperamos los autos marcas y modelos
  static Future<List<Map<String, dynamic>>> getAllAuto() async {

    
    final String pathRoot = await GetPaths.getFileByPath('autos');
    final regs = File(pathRoot);
    if(regs.existsSync()) {
      return List<Map<String, dynamic>>.from( json.decode(regs.readAsStringSync()) );
    }
    return [];
  }
}