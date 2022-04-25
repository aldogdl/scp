import '../services/get_paths.dart';
import '../services/my_http.dart';

class OrdenesRepository {

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> getAllOrdenesByAvo(int avo, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('get_ordenes_by_avo', isLocal: isLocal);
    await MyHttp.get('$uri$avo/');
    result = MyHttp.result;
  }

  ///
  Future<void> getOrdenById(int id, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('get_orden_by_id', isLocal: isLocal);
    await MyHttp.get('$uri$id/');
    result = MyHttp.result;
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

  /// Construimos en el Archivo del centinela la seccion de busqueda o 
  /// rastreo de contizaciones entre los Cotizadores seleccionados.
  Future<void> buildStatusForBuscarPiezas(
    Map<String, dynamic> data, {bool isLocal = true}
  ) async {

    String uri = await GetPaths.getUri('build_status_bskpzas', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }
}