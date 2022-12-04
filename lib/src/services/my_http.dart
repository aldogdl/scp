import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:scp/src/services/get_paths.dart';

import '../config/sng_manager.dart';
import '../vars/globals.dart';

class MyHttp {

  static Globals globals = getSngOf<Globals>();
  static Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  static clean() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  static Future<String> makeLogin(
    String dominio, Map<String, dynamic> credentials
  ) async {

    const base = 'secure-api-check';
    http.Response resp = await http.post(
      Uri.parse('$dominio$base'),
      body: json.encode(credentials),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json'
      }
    );
    if(resp.statusCode == 200) {
      final r = Map<String, dynamic>.from(json.decode(resp.body));
      if(r.containsKey('token')) {
        return r['token'];
      }
    }
    return '';
  }

  ///
  static Future<void> get(String uri, {String t = ''}) async {

    late http.Response response;
    Uri uriParse = Uri.parse(uri);
    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json'
    };

    if(t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
    }

    try {
      response = await http.get(uriParse, headers: headers);
    } catch (e) {
      // 
      if(e.toString().contains('SocketException')) {
        result['abort'] = true;
        result['body'] = 'ERROR, El Host ${ uriParse.host } está sin conexión.';
      }
      return;
    }

    if(response.statusCode == 200) {
      clean();
      try {
        result = Map<String, dynamic>.from(json.decode(response.body));
      } catch (_) {
        result['abort'] = true;
        result['body'] = 'ERROR, El Host ${ uriParse.host } datos corruptos.';
      }
    }else{
      _drawErrorInConsole(response);
    }
  }

  ///
  static Future<void> getHarbi(Uri uri) async {

    late http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      // 
      if(e.toString().contains('SocketException')) {
        result['abort'] = true;
        result['body'] = 'ERROR, El Host ${ uri.host } está sin conexión.';
      }
      return;
    }

    if(response.statusCode == 200) {
      clean();
      result = Map<String, dynamic>.from(json.decode(response.body));
    }else{
      _drawErrorInConsole(response);
    }
  }

  ///
  static Future<void> post(String uri, Map<String, dynamic> data, {String t = ''}) async {

    result.clear();
    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    if(t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
    }

    var req = http.MultipartRequest('POST', Uri.parse(uri));
    req.headers.addAll(headers);
    req.fields['data'] = json.encode(data);
    late http.Response response;
    try {
      response = await http.Response.fromStream(await req.send());
    } catch (e) {
      result = {'abort':true, 'msg': e.toString(), 'body':'ERROR, Sin conexión al servidor, intentalo nuevamente.'};
      return;
    }
    
    if(response.statusCode == 200) {
      clean();
      result = Map<String, dynamic>.from(json.decode(response.body));
    }else{
      result['abort'] = true;
      _drawErrorInConsole(response);
    }
  }

  ///
  static Future<void> postHarbi(Uri uri, Map<String, dynamic> data) async {

    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var req = http.MultipartRequest('POST', uri);

    req.headers.addAll(headers);
    req.fields['data'] = '${utf8.encode(json.encode(data))}';
    late http.Response response;
    try {
      response = await http.Response.fromStream(await req.send());
    } catch (e) {
      result = {'abort':true, 'msg': e.toString(), 'body':'ERROR, Sin conexión al servidor, intentalo nuevamente.'};
      return;
    }

    if(response.statusCode == 200) {
      clean();
      result = Map<String, dynamic>.from(json.decode(response.body));
    }else{
      _drawErrorInConsole(response);
    }
  }

  /// 
  static Future<void> upFileByData(
    String uri, String token,
    {required Map<String, dynamic> metas}
  ) async {

    clean();
    Uri url = Uri.parse(uri);
    var req = http.MultipartRequest('POST', url);
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    };

    String filename = metas['filename'];
    List<String> partes = filename.split('.');
    String ext = partes.last;
    String campo = '${DateTime.now().millisecondsSinceEpoch}';

    if( metas['bytes'].isNotEmpty ) {

      req.files.add(
        http.MultipartFile.fromBytes(
          campo,
          List<int>.from(metas['bytes']),
          filename: filename,
          contentType: MediaType('image', ext)
        )
      );
      req.fields['data'] = json.encode({
        'filename': filename,
        'campo'   : campo,
        'idTmp'   : (metas.containsKey('idTmp')) ? metas['idTmp'] : '',
        'idOrden' : (metas.containsKey('idOrden')) ? metas['idOrden'] : ''
      });
      req.headers.addAll(headers);
      http.Response reServer = await http.Response.fromStream(await req.send());

      if(reServer.statusCode == 200) {
        var body = json.decode(reServer.body);
        if(body.isNotEmpty) {
          try {
            result['body'] = List<Map<String, dynamic>>.from(body);
          } catch (e) {
            result = Map<String, dynamic>.from(body);
            if(body['abort']) {
              _drawErrorInConsole(reServer);
            }
          }
        }
      }else{
        _drawErrorInConsole(reServer);
      }

    }else{
      result['abort']= true;
      result['msg']  = 'err';
      result['body'] = 'Sin Imagenes para enviar.';
    }
  }

  ///
  static void _drawErrorInConsole(http.Response response) {

    switch (response.statusCode) {
      case 401:
        if(response.reasonPhrase != null) {
          if(response.reasonPhrase!.contains('Unauthorized')) {
            result['body'] = 'Invalido Token';
          }
        }
        break;
      default:
    }

    final filename = 'symfony-${DateTime.now().millisecondsSinceEpoch}.html';
    debugPrint('[ERROR]::${response.statusCode}');
    debugPrint('Revisa la carpeta de logs [$filename]');
    final root = GetPaths.getPathRoot();
    File('$root${GetPaths.getSep()}logs${GetPaths.getSep()}$filename').writeAsStringSync(response.body);
    debugPrint(response.reasonPhrase);
  }
}