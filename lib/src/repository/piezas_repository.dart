import '../services/get_paths.dart';
import '../services/my_http.dart';

class PiezasRepository {

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> getPiezasByOrden(int id) async {

    String uri = await GetPaths.getUri('get_piezas_by_orden');
    await MyHttp.get('$uri$id/');
    result = MyHttp.result;
  }
  
}