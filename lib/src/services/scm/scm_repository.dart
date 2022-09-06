import 'scm_paths.dart';
import '../../services/scm/scm_http.dart';
import '../../config/sng_manager.dart';
import '../../vars/globals.dart';

/// El objetivo de crear un pequeño servicio de SCM el cual consta de una 
/// Entidad, un http, un repository y un sistema de path es para poder copiar
/// este servicio y ponerlo en otros sistemas.
class ScmRepository {

  final Globals globals = getSngOf<Globals>();
  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clean() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> setCampaingInDb(Map<String, dynamic> data, {bool isLocal = true}) async {

    String uri = ScmPaths.getUri('newCampaing', isLocal: isLocal);
    await ScmHttp.post(uri, data);
    result = ScmHttp.result;
    ScmHttp.clean();
  }

  /// Obtenemos el id de la campaña para buscar cotizaciones
  Future<void> getIdCampBySlug(String slug) async {

    final uri = ScmPaths.getUriHarbi('getIdCamp');
    await ScmHttp.get('$uri$slug');
    result = ScmHttp.result;
    ScmHttp.clean();
  }

}