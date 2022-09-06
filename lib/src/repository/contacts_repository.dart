import '../services/get_paths.dart';
import '../services/my_http.dart';

class ContactsRepository {

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> backupContact(Map<String, dynamic> data) async {
    
    // TODO hacer esto via http hacia harbi
    
    // Directory? uri = GetPaths.getPathsFolderTo('udel');
    // if(uri != null) {
    //   File contact = File('${uri.path}${GetPaths.getSep()}${data['curc']}.json');
    //   contact.writeAsStringSync( json.encode(data) );
    // }
  }

  /// Recuperamos desde harbi entre los archivos al cotizador requerido
  Future<void> getCotizadorByIdFromHarbi(int idCot) async {
    
    final uri = await GetPaths.getUriApiHarbi('get_cotz_by_id', '$idCot');
    await MyHttp.getHarbi(uri);
    result = MyHttp.result;
  }

  ///
  Future<void> getAllCotizadores() async {
    
    String uri = await GetPaths.getUri('get_all_cotizadores');
    await MyHttp.get(uri);
    result = MyHttp.result;
  }

  ///
  Future<void> getAllContacts({String tipo = 'noAdmin', bool isLocal = true}) async {
    
    String uri = await GetPaths.getUri('get_all_contactos_by', isLocal: isLocal);
    await MyHttp.get('$uri$tipo');
    result = MyHttp.result;
  }

  ///
  Future<void> deleteContact(int idContac, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('delete_contacto', isLocal: isLocal);
    await MyHttp.get('$uri$idContac');
    result = MyHttp.result;
  }

  ///
  Future<void> safeDataContact(Map<String, dynamic> data, {isLocal = true}) async {

    String uri = await GetPaths.getUri('seve_data_contact', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }
}