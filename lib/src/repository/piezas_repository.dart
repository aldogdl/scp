import '../services/get_paths.dart';
import '../services/my_http.dart';
import '../vars/globals.dart';

class PiezasRepository {

  final _globals = Globals();
  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> getPiezasByOrden(int id, {bool isLocal = true}) async {

    if(_globals.env == 'dev') {
      isLocal = true;
    }

    String uri = await GetPaths.getUri('get_piezas_by_orden', isLocal: isLocal);
    await MyHttp.get('$uri$id/');
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  /// Recuperamos las respuestas de las piezas indicadas por parametro.
  Future<void> getRespuestasByIdPiezas(String ids, {bool isLocal = true}) async {

    if(_globals.env == 'dev') {
      isLocal = true;
    }

    String uri = await GetPaths.getUri('get_resps_by_pzas', isLocal: isLocal);
    await MyHttp.get('$uri$ids/');
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }
  
}