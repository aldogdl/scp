import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/vars/globals.dart';

class HarbiApi {

  static final Globals _globals = getSngOf<Globals>();

  static getUri(String uri) {

    return 'http://${_globals.ipHarbi}:${_globals.portHarbi}/internal/${_getRutaApi(uri)}';
  }

  ///
  static String _getRutaApi(String api) {

    final map = <String, String>{
      'getIpDb': 'get_ipdb',
      'getAllRutas': 'get_all_rutas'
    };
    return map[api] ?? '';
  }
}