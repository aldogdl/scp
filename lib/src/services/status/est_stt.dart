import '../../config/sng_manager.dart';
import '../../services/status/stts_cache.dart';

class EstStt {

  static SttsCache r = getSngOf<SttsCache>();

  String ruta = '';
  String estacion = '';

  // Revisamos que exista, en caso contrario descargamos la ruta adecuada
  static Future<void> init(String ruta) async {
    if(r.status.isEmpty) {
      await r.hidratar();
    }
  }

  // 
  static Future<Map<String, dynamic>> getNextSttByEst(Map<String, dynamic> data) async {

    // Buscamos el status actual
    int? stt = int.tryParse(data['stt']);
    if(stt != null) {
      stt++;
      if(r.status['stt'].containsKey('$stt')) {
        return {'est':data['est'], 'stt':'$stt', 'txtStt':r.status['stt'][data['est']]['$stt']};
      }else{
        // Si no existe siguiente status es el fin de dicha estacion
        // QUE HACER??
      }
    }else{
      return {'error':'No se encuentra es status: ${data['stt']}'};
    }

    return {'error':'Sin ruta'};
  }

  /// Obtenemos el status inicial de la estacion solicitada
  static String getFirstSttByEst(Map<String, dynamic> data) {

    return r.status['est'][data['est']].first;
  }

  /// Obtenemos el primer estatus de la pieza estacion busqueda
  static Future<Map<String, dynamic>> getFirstSttByEstBusqueda(Map<String, dynamic> data) async {

    Map<String, dynamic> rstt = {};

    r.status['est'].forEach((key, value) {
      if(value == 'Buscando Piezas') {
        rstt = {'est':key, 'stt':'1'};
      }
    });
    return rstt;
  }

  /// Obtenemos la siguiente estacion
  static String getNextEst(Map<String, dynamic> data) {

    
    return 'Ruta Desconocida';
  }

  /// Obtenemos la estacion solicitada
  static String getEst(Map<String, dynamic> data) {

    return r.status['est'][data['est']];
  }

  /// Obtenemos el estatus segun su estacion
  static String getSttByEst(Map<String, dynamic> data) {

    return r.status['stt'][data['est']][data['stt']];
  }

}