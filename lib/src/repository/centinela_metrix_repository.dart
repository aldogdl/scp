import 'package:scp/src/services/my_http.dart';

import '../services/get_paths.dart';

class CentinelaMetrixRepository {

  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> getCotizadores(String query) async {

    final uri = await GetPaths.getUriApiHarbi('centinela_get', 'get_metrix_of_file=$query');
    await MyHttp.getHarbi(uri);
    result = MyHttp.result;
  }
}