import '../services/my_http.dart';
import '../entity/aldo_entity.dart';
import '../services/scranet/get_paths_scranet.dart';
import '../services/scranet/system_file_scrap.dart';

class ScranetAnetRepository { 

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  final entity = AldoEntity();
  final className = 'aldo';
  bool isLoading = false;

  ///
  Future<String> setPiezaName(Map<String, dynamic> pieza) async {

    String uri = GetPathScranet.getUri('set_pieza', isLocal: true);
    await MyHttp.post(uri, pieza);
    result = Map<String, dynamic>.from(MyHttp.result);
    if(result['abort']) {
      return '[SL] ${result['body']}';
    }
    pieza['id'] = result['body'];
    MyHttp.clean();

    uri = GetPathScranet.getUri('set_pieza', isLocal: false);
    await MyHttp.post(uri, pieza);
    result = Map<String, dynamic>.from(MyHttp.result);
    if(result['abort']) {
      return '[SR] ${result['body']}';
    }
    MyHttp.clean();
    pieza.remove('stt');
    var res = await SystemFileScrap.setPiezaBy('anet', pieza);
    return res;
  }

  ///
  Future<void> delPiezaName() async {

  }
}