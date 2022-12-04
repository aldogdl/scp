import '../entity/contacto_entity.dart';
import '../services/get_paths.dart';
import '../services/my_http.dart';
import '../vars/globals.dart';

class ContactsRepository {

  final _globals = Globals();
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
  Future<void> getAllAvos({bool force = false}) async {

    if(!force) {
      final avos = GetPaths.getContentFileAvos();
      if(avos.isNotEmpty) {
        result = {'abort':false, 'msg': 'ok', 'body': avos};
        return;
      }
    }

    await getAllContacts(tipo: 'anete', isLocal: false);

    if(!result['abort']) {
      List<Map<String, dynamic>> cts = [];
      for (var i = 0; i < result['body'].length; i++) {
        if(result['body'][i]['c_roles'].contains('ROLE_AVO')) {
          final ct = ContactoEntity();
          ct.fromServerWidtEmpresa(result['body'][i]);
          cts.add(ct.toJsonWidtEmpresa());
        }
      }
      if(cts.isNotEmpty) {
        GetPaths.setContentFileAvos(cts);
      }
    }
  }

  ///
  Future<void> getAllContacts(
    {String tipo = 'noAdmin', bool isLocal = false}) async
  {
    if(_globals.env == 'dev') { isLocal = true; }
    String uri = await GetPaths.getUri('get_all_contactos_by', isLocal: isLocal);
    await MyHttp.get('$uri$tipo');
    result = MyHttp.result;
  }

  ///
  Future<void> deleteContact(int idContac, {bool isLocal = true}) async {

    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = await GetPaths.getUri('delete_contacto', isLocal: isLocal);
    await MyHttp.get('$uri$idContac');
    result = MyHttp.result;
  }

  ///
  Future<void> safeDataContact(Map<String, dynamic> data, {isLocal = true}) async {

    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = await GetPaths.getUri('guardar_datos_empcontac', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  ///
  Future<void> getFiltroByEmp(int idEmp) async {

    String uri = await GetPaths.getUriCtc('get_filtros_emp');
    await MyHttp.get('$uri$idEmp');
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  ///
  Future<void> setFiltroCotizador(Map<String, dynamic> data, {bool isLocal = true}) async {

    if(_globals.env == 'dev') {
      isLocal = true;
    }
    String uri = await GetPaths.getUriCtc('set_filtro', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  ///
  Future<void> delFiltroById(int id, {bool isLocal = true}) async {
    
    if(_globals.env == 'dev') {
      isLocal = true;
    }    
    String uri = await GetPaths.getUriCtc('del_filtro_by_id', isLocal: isLocal);
    await MyHttp.get('$uri$id/');
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }
}