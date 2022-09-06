import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

class ScmHttp {

  static Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  static void clean() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  static Future<void> get(String uri) async {

    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var req = http.MultipartRequest('GET', Uri.parse(uri));

    req.headers.addAll(headers);
    late http.Response response;
    try {
      response = await http.Response.fromStream(await req.send());
    } catch (e) {
      result = {'abort':true, 'msg': e.toString(), 'body':'ERROR, Sin conexión con HARBI, intentalo nuevamente.'};
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
  static Future<void> post(String uri, Map<String, dynamic> data) async {

    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
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
      if(result['abort']) {
        debugPrint(result['msg']);
      }
    }else{
      _drawErrorInConsole(response);
    }
  }

  ///
  static void _drawErrorInConsole(http.Response response) {

    debugPrint('[ERROR]::${response.statusCode}');
    debugPrint(response.body);
  }
}