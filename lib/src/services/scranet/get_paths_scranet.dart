
import '../../config/sng_manager.dart';
import '../../vars/globals.dart';

class GetPathScranet {

  static String base = 'scp/scranet/';
  static String urlL = 'http://localhost/autoparnet/public_html/';
  static String urlR = 'https://autoparnet.com/';

  static final _globals = getSngOf<Globals>();

  ///
  static String getUri(String uri, {bool isLocal = true}) {
     
    final paths = {
      'get_marcas': 'get-all-marcas/',
      'set_marca': 'set-marca/',
      'set_modelo': 'set-modelo/',
      'get_modelos_by_idmrk': 'get-modelos-by-idmrk/',
      'set_pieza': 'set-pieza/',
      'del_pieza': 'del-pieza/',
    };
    
    if(isLocal) {
      if(_globals.ipDbs.containsKey('base_l')) {
        urlL = _globals.ipDbs['base_l'];
      }
    }
    final main = (isLocal) ? urlL : urlR;
    return '$main$base${paths[uri]}';
  }
}