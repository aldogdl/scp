
import '../config/sng_manager.dart';
import '../vars/globals.dart';

class GetPathCotiza {

  static String base = 'api/cotiza/';
  static String urlL = 'http://localhost/autoparnet/public_html/';
  static String urlR = 'https://autoparnet.com/';

  static final _globals = getSngOf<Globals>();

  ///
  static String getUri(String uri, {bool isLocal = true}) {

    final paths = {
      'set_orden': 'set-orden/',
      'upload_img': 'upload-img/',
      'set_pieza': 'set-pieza/',
      'enviar_orden': 'enviar-orden/',
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