import 'dart:io';
import 'dart:convert';

import '../../services/my_http.dart';
import '../../services/get_paths.dart';

class SttsCache {

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

      MyHttp.clean();
      String path = await GetPaths.getFileByPath('rutas');

      File stts = File(path);
      if(stts.existsSync()) {
        _status = Map<String, dynamic>.from(json.decode(stts.readAsStringSync()));
      }
    }
  }

}