import 'package:flutter/foundation.dart' show compute;

import '../../entity/contacto_entity.dart';
import '../../providers/socket_conn.dart';
import '../../repository/socket_centinela.dart';
import '../../services/push_in/get_pushin.dart';
import '../../services/push_in/system_file_push.dart';

class GestPushIn {

  final SocketConn socket;
  final ContactoEntity user;
  GestPushIn({
    required this.socket,
    required this.user
  }){
    SystemFilePush.makeSystemFiles();
  }

  /// 
  Future<Map<String, dynamic>> getRecents(List<String> pushs) async {

    if(pushs.isNotEmpty) {
      return compute(getPushin, pushs);
    }
    return {};
  }

  /// 
  Future<Map<String, dynamic>> getLost(List<String> pushs) async {

    if(pushs.isNotEmpty) {
      return compute(getPushLost, pushs);
    }
    return {};
  }

  ///
  List<String> isForMy(List<String> pushs) {

    List<String> forGet = [];
    List<String> currents = SystemFilePush.getListFilesBy(
      SystemFilePush.foldersPush['pushin']
    );
    
    for (var i = 0; i < pushs.length; i++) {

      bool fileIn = false;
      final partes = pushs[i].split('-');

      if(partes.first == 'centinela_update') {
        if(!currents.contains(pushs[i])) {
          forGet.add(pushs[i]);
          fileIn = true;
        }
      }

      if(partes.first == '${user.id}') {
        if(!currents.contains(pushs[i])) {
          forGet.add(pushs[i]);
          fileIn = true;
        }
      }
      
      if(!fileIn) {
        if(user.roles.contains('ROLE_${partes.first.toUpperCase()}')) {
          if(!currents.contains(pushs[i])) {
            forGet.add(pushs[i]);
          }
        }
      }
    }

    return forGet;
  }

  ///
  void categorizar() => SystemFilePush.sortPerPriority();

  ///
  List<String> sufixFiles() => SystemFilePush.sufix;

  ///
  Map<String, String> cuantificar(Map<String, String> currents)
    => SystemFilePush.cuantificar(currents);

  ///
  Map<String, String> cleanAll(Map<String, String> currents)
    => SystemFilePush.cleanAll(currents);

  ///
  List<Map<String, dynamic>> getNotifByFolder(String folder)
    => SystemFilePush.getMetadatosBy(folder);

  ///
  void setFilesLost(List<String> files)
    => SystemFilePush.setFilesLost(files);

  /// Lista de ids que fueron afectados en su IRIS
  List<int> idsOrdsChanged = [];

  /// Todos las notificaciones que necesitan trabajar en background 
  Stream<String> processBackground() async* {

    List<String> process = ['centinela_update'];

    List<String> forGet = [];
    List<String> forMy = [];
    String fold = SystemFilePush.foldersPriority['baja'];
    List<String> currents = SystemFilePush.getListFilesBy(fold, getForWork: true);

    for (var i = 0; i < currents.length; i++) {
      
      final partes = currents[i].split('-');
      // si el primer elemento es un numero, significa que el push comienza con el 
      // identificador del avo de este SCP
      int? isForMi = int.tryParse(partes.first);
      if(isForMi != null) {
        forMy.add(currents[i]);
      }else{
        if(!forGet.contains(partes.first)) {
          forGet.add(partes.first);
        }
      }
    }

    final soC = SocketCentinela();
    if(forGet.contains(process[0])) {

      yield 'Acualizando Centinela File...';
      await Future.delayed(const Duration(milliseconds: 250));
      final ver = await soC.getFromApiHarbi(onlyVersion: true);

      if(ver.isNotEmpty) {
        yield 'Versionando a: ${ver['ver']}';
        await Future.delayed(const Duration(milliseconds: 150));
        // OJO: Las ordenes asignadas se calculan directamente en el archivo del
        // centinela, en caso de que exista, la misma SCP, crea una simulacion de
        // push notification para ser avisado el AVO de esta SCP.
        yield 'Checando Asignaciones...';
        await Future.delayed(const Duration(milliseconds: 250));

        final hasAsigns = await soC.checkNewAsigns(from: 'file');
        if(hasAsigns.containsKey('ordAsign')) {
          if(hasAsigns['ordAsign'].isNotEmpty) {
            SystemFilePush.crearFileNewAsign(
              List<String>.from(hasAsigns['ordAsign']), user.id
            );
            yield 'Asignación Nueva';
            await Future.delayed(const Duration(milliseconds: 250));
            yield 'Listo...';
            return;
          }
        }
      }
    }

    if(forMy.isNotEmpty) {

      yield 'Procesando Archivos Push';
      await Future.delayed(const Duration(milliseconds: 250));
      for (var i = 0; i < forMy.length; i++) {
        final content = SystemFilePush.getContentIn(fold, forMy[i]);

        if(content.isNotEmpty) {
          
          switch (content['secc']) {
            case 'metrix':
              yield 'Actualizando Métricas #${i+1}';
              await Future.delayed(const Duration(milliseconds: 250));
              final data = Map<String, dynamic>.from(content['data']);
              data['avo'] = '${user.id}';
              await soC.updateMetrix(data);
              break;
            case 'iris':
              idsOrdsChanged = [];
              yield 'Datos Dasboard #${i+1}';
              await Future.delayed(const Duration(milliseconds: 250));
              final data = Map<String, dynamic>.from(content['data']);
              idsOrdsChanged = await soC.updateIris(data);
              yield 'Datos IRIS Actualizados';
              await Future.delayed(const Duration(milliseconds: 250));
              break;
            default:
          }
        }
      }
    }

    yield '<BG>';
  }

}