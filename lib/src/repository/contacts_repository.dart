import 'dart:convert';
import 'dart:io';

import 'package:scp/src/entity/contacts_entity.dart';
import 'package:scp/src/services/get_paths.dart';
import 'package:scp/src/services/my_http.dart';

class ContactsRepository {

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> backupContact(Map<String, dynamic> data) async {
    
    Directory? uri = GetPaths.getPathsFolderTo('udel');
    if(uri != null) {
      File contact = File('${uri.path}${GetPaths.getSep()}${data['curc']}.json');
      contact.writeAsStringSync( json.encode(data) );
    }
  }

  ///
  Future<void> getAllContacts({String tipo = 'noAdmin'}) async {
    
    String uri = await GetPaths.getUri('get_all_contactos_by');
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