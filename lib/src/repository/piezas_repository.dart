import '../services/get_paths.dart';
import '../services/my_http.dart';

class PiezasRepository {

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> getPiezasByOrden(int id, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('get_piezas_by_orden', isLocal: isLocal);
    await MyHttp.get('$uri$id/');
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }
  
}