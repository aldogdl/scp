import 'dart:convert';

import 'system_file_push.dart';
import '../../services/get_paths.dart';
import '../../services/my_http.dart';

///
Future<Map<String, dynamic>> getPushin(List<String> files) async {

  if(files.isNotEmpty) { return await getFiles('recent', files); }
  return {};
}

///
Future<Map<String, dynamic>> getPushLost(List<String> files) async {

  if(files.isNotEmpty) { return await getFiles('lost', files, delMyLost: true); }
  return {};
}

///
Future<Map<String, dynamic>> getFiles
  (String fold, List<String> files, {bool delMyLost = false}) async
{

  Map<String, dynamic> response = {'process':[], 'lost':[]};

  List<String> losOk = [];
  List<String> losLost = [];
  final uri = await GetPaths.getPathToApiHarbi('push');
  
  for (var i = 0; i < files.length; i++) {

    await MyHttp.getHarbi(Uri.parse('http://$uri/$fold%${files[i]}'));

    String folder = (!MyHttp.result['abort'])
      ? SystemFilePush.foldersPush['pushin']
      : SystemFilePush.foldersPush['pushlost'];

    if(folder == SystemFilePush.foldersPush['pushin']) {
      losOk.add(files[i]);
    }else{
      losLost.add(files[i]);
    }

    SystemFilePush.setContentIn(
      folder, files[i],
      Map<String, dynamic>.from(json.decode(MyHttp.result['body']))
    );

    if(delMyLost) {
      folder = SystemFilePush.foldersPush['pushlost'];
      SystemFilePush.delFileOf(folder, files[i]);
    }
  }

  response['process'] = losOk;
  response['lost'] = losLost;

  return response;
}
