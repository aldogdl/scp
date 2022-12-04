import 'dart:convert';
import 'dart:io';

import '../config/sng_manager.dart';
import '../services/get_paths.dart';
import '../vars/globals.dart';

class GetContentFile {

  static final Globals _globals = getSngOf<Globals>();

  /// Es usado solo en desarrollo para no estar pidiendo
  /// de manera remota la IP de harbi.
  static String ipConectionLocal() {

    String pathTo = GetPaths.getPathRoot();
    final File codeF = File('$pathTo${GetPaths.getSep()}swh.txt');
    final codeSwh = codeF.readAsStringSync();

    final File cargosF = File('$pathTo${GetPaths.getSep()}harbi_connx.json');
    if(cargosF.existsSync()) {
      final res = Map<String, dynamic>.from(json.decode(cargosF.readAsStringSync()));
      if(res.isNotEmpty && res.containsKey(codeSwh)) {
        return res[codeSwh];
      }
    }
    return '';
  }

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

  /// Recuperamos los autos marcas y modelos
  static Future<List<Map<String, dynamic>>> getAllAuto() async {

    final String pathRoot = await GetPaths.getFileByPath('autos');
    final regs = File(pathRoot);
    if(regs.existsSync()) {
      return List<Map<String, dynamic>>.from( json.decode(regs.readAsStringSync()) );
    }
    return [];
  }

  ///
  static Future<bool> hidratarUserFromFile(Map<String, dynamic> data) async {

    List<Map<String, dynamic>> users = [];

    final pathTo = await GetPaths.getFileByPath('connpass');
    final regs = File(pathTo);
    if(regs.existsSync()) {
      final txtCont = regs.readAsStringSync();
      if(txtCont.isNotEmpty) {
        users = List<Map<String, dynamic>>.from( json.decode(txtCont) );
        if(users.isNotEmpty) {
          final hasUser = users.firstWhere(
            (element) => element['curc'] == data['username'], orElse: () => {}
          );
          if(hasUser.isNotEmpty) {
            _globals.user.fromFile(hasUser);
            return true;
          }
        }
      }
    }
    
    return false;
  }

  ///
  static Future<void> saveUserValid() async {

    final user = _globals.user.userToJson();
    final pathTo = await GetPaths.getFileByPath('connpass');
    final regs = File(pathTo);

    List<Map<String, dynamic>> users = [];
    
    if(!regs.existsSync()) {
      regs.createSync(recursive: true);
      users.add(user);
    }else{

      final txtCont = regs.readAsStringSync();
      if(txtCont.isNotEmpty) {
        users = List<Map<String, dynamic>>.from( json.decode(txtCont) );
        final hasUser = users.indexWhere((element) => element['curc'] == _globals.user.curc);
        if(hasUser != -1) {
          users[hasUser] = user;
        }else{
          users.add(user);
        }
      }
    }
    regs.writeAsStringSync(json.encode(users));
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

  /// Recuperamos a todos los usuarios que se han registrado en esta SCP
  static Future<List<Map<String, dynamic>>> regOfLogin() async {

    return [];
  }

}