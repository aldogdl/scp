import '../services/get_paths.dart';
import '../services/my_http.dart';

class OrdenesRepository {

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> getOrdenById(int id, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('get_orden_by_id', isLocal: isLocal);
    await MyHttp.get('$uri$id/');
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  ///
  Future<void> editarDataPieza(Map<String, dynamic> data, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('editar_data_pieza', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  /// Cambiar el nuevo status en el Servidor remoto asi como el archivo Centinela
  Future<void> changeStatusToServer(Map<String, dynamic> data, {bool isLocal = true}) async {
    
    String uri = await GetPaths.getUri('change_stt_to_orden', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  /// Cambiar el nuevo status en el Servidor remoto asi como el archivo Centinela
  Future<void> changeStatusOrdsAndPzasToServer(Map<String, dynamic> data, {bool isLocal = true}) async {
    
    String uri = await GetPaths.getUri('set_ests_stts', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  /// Recuperamos todas las ordenes del avo desde el servidor
  Future<void> getAllOrdenesByAvoFromServer
    (int avo, {String hydra = 'scalar', bool isLocal = true}) 
  async {

    String uri = await GetPaths.getUri('get_ordenes_by_avo', isLocal: isLocal);
    await MyHttp.get('$uri$avo/$hydra/');
    result = MyHttp.result;
  }

  /// Recuperamos todas las ordenes del avo desde el servidor
  Future<void> getAllIdsOrdenesByAvoFromServer
    (int avo, {bool isLocal = true}) 
  async {

    String uri = await GetPaths.getUri('get_ids_ordenes_by_avo', isLocal: isLocal);
    await MyHttp.get('$uri$avo/');
    result = MyHttp.result;
  }

}