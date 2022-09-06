import '../../config/sng_manager.dart';
import '../../vars/globals.dart';

class ScmPaths {

  static final Globals _globals = getSngOf<Globals>();

  ///  
  static String getUri(String uri, {bool isLocal = false}) {

    final tipo = (isLocal) ? 'base_l' : 'base_r';
    return '${_globals.ipDbs[tipo]}${_paths[uri]}';
  }

  ///  
  static getUriHarbi(String uri) {

    return 'http://${_globals.ipHarbi}:${_globals.portHarbi}/${_paths[uri]}';
  }

  ///
  static const Map<String, String> _paths = {
    'newCampaing':'scp/solicitudes/set-reg-campaing-scm/',
    'getIdCamp':'scp/get-id-campaing-by-slug/',
  };

}