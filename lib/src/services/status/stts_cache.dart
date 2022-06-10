import 'dart:io';
import 'dart:convert';

import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/services/my_http.dart';
import 'package:scp/src/vars/globals.dart';
import 'package:scp/src/vars/harbi_api.dart';

import '../../services/get_paths.dart';

class SttsCache {

  final Globals _globals = getSngOf<Globals>();

  Map<String, dynamic> _status = {};
  Map<String, dynamic> get status => _status;

  ///
  Future<Map<String, dynamic>> getStatus() async {

    if(_status.isNotEmpty) {
      return _status;
    }else{
      await hidratar();
      if(_status.isNotEmpty) {
        return _status;
      }
    }
    return {};
  }

  ///
  Future<void> hidratar() async {

    if(_status.isEmpty) {

      /// Si las ip de harbi y del sistema son distintos es por que harbi se esta
      /// ejecutando en otra maquina.
      if(_globals.ipHarbi != _globals.myIp) {
        String uri = HarbiApi.getUri('getAllRutas');
        await MyHttp.get(uri);
        if(!MyHttp.result['abort']) {
          _status = Map<String, dynamic>.from(MyHttp.result['body']);
        }
      }else{

        String path = await GetPaths.getFileByPath('rutas');

        File stts = File(path);
        if(stts.existsSync()) {
          _status = Map<String, dynamic>.from(json.decode(stts.readAsStringSync()));
        }
      }
    }
  }

}