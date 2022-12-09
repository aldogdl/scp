
import '../services/get_paths.dart';
import '../services/get_paths_cotiza.dart';
import '../services/my_http.dart';
import '../vars/globals.dart';

class OrdenesRepository {

  final _globals = Globals();
  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  /// Solicitamos al servidor el token del que usa el SCP
  Future<String> getTokenServer(Map<String, dynamic> data) async {

    bool isLocal = false;
    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String domi = await GetPaths.getDominio(isLocal: isLocal);

    final isToken = await MyHttp.makeLogin(domi, data);
    if(isToken.isNotEmpty) {
      return isToken;
    }
    return '';
  }

  ///
  Future<void> getOrdenById(String call, int id, {bool isLocal = true}) async {

    if(_globals.env == 'dev') {
      isLocal = true;
    }

    String uri = await GetPaths.getUri('get_orden_by_id', isLocal: isLocal);
    await MyHttp.get('$uri$id/');
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  ///
  Future<void> editarDataPieza(Map<String, dynamic> data, {bool isLocal = true}) async {

    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = await GetPaths.getUri('editar_data_pieza', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  /// Cambiar el nuevo status en el Servidor remoto asi como el archivo Centinela
  Future<void> changeStatusToServer(Map<String, dynamic> data, {bool isLocal = true}) async {
    
    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = await GetPaths.getUri('change_stt_to_orden', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  /// Cambiar el nuevo status en el Servidor remoto asi como el archivo Centinela
  Future<void> changeStatusOrdsAndPzasToServer(Map<String, dynamic> data, {bool isLocal = true}) async {
    
    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = await GetPaths.getUri('set_ests_stts', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  /// Recuperamos todas las ordenes del avo desde el servidor
  Future<void> getAllOrdenesByAvoFromServer
    (int avo, {String hydra = 'scalar', bool isLocal = true}) 
  async {

    if(_globals.env == 'dev') { isLocal = true; }
    String uri = await GetPaths.getUri('get_ordenes_by_avo', isLocal: isLocal);
    await MyHttp.get('$uri$avo/$hydra/');
    result = MyHttp.result;
  }

  /// Recuperamos todas las ordenes del avo desde el servidor
  Future<void> getAllIdsOrdenesByAvoFromServer(int avo, {bool isLocal = true}) async {

    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = await GetPaths.getUri('get_ids_ordenes_by_avo', isLocal: isLocal);
    await MyHttp.get('$uri$avo/');
    result = MyHttp.result;
  }

  /// Desde la seccion de cotizar, creamos una nueva solicitud de cotizacion
  Future<void> setOrdenByCotiza(Map<String, dynamic> orden, String tk) async {

    bool isLocal = false;
    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = GetPathCotiza.getUri('set_orden', isLocal: isLocal);
    await MyHttp.post(uri, orden, t: tk);
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  /// Desde la seccion de cotizar, creamos una nueva solicitud de cotizacion
  Future<void> setPiezaByCotiza(Map<String, dynamic> pieza, String tk) async {

    bool isLocal = false;
    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = GetPathCotiza.getUri('set_pieza', isLocal: isLocal);
    await MyHttp.post(uri, pieza, t: tk);
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  /// Desde la seccion de cotizar, creamos una nueva solicitud de cotizacion
  Future<void> setFotoCotiza(Map<String, dynamic> data, String tk) async {

    bool isLocal = false;
    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = GetPathCotiza.getUri('upload_img', isLocal: isLocal);
    await MyHttp.upFileByData(uri, tk, metas: data);
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  /// Actualizamos los datos y la version en el centinela para que sepa harbi
  /// que hay una nueva orden.
  Future<void> updateCentinelaServer(int idOrden, String tk) async {

    bool isLocal = false;
    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = GetPathCotiza.getUri('enviar_orden', isLocal: isLocal);
    await MyHttp.get('$uri$idOrden/', t: tk);
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

}