import '../services/get_paths.dart';
import '../services/my_http.dart';

class OrdenesRepository {

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> getAllOrdenesByAvo(int avo) async {

    String uri = await GetPaths.getUri('get_ordenes_by_avo');
    await MyHttp.get('$uri$avo/');
    result = MyHttp.result;
  }

  ///
  Future<void> getOrdenById(int id) async {

    String uri = await GetPaths.getUri('get_orden_by_id');
    await MyHttp.get('$uri$id/');
    result = MyHttp.result;
  }

  /// Cambiar el nuevo status en el Servidor remoto asi como el archivo Centinela
  /// y dejar que el sistema haga el resto.
  Future<void> changeStatusToRemoto(Map<String, dynamic> data) async {

    String uri = await GetPaths.getUri('change_stt_to_orden');
    await MyHttp.post(uri, data);
    print(MyHttp.result);
    result = MyHttp.result;
  }
}