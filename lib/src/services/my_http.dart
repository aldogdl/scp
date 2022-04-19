import 'dart:convert';

import '../config/sng_manager.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../vars/globals.dart';

class MyHttp {

  static Globals globals = getSngOf<Globals>();
  static Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  static clean() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  static Future<void> get(String uri) async {

    http.Response response = await http.get(Uri.parse(uri));
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
      result = {'abort':true, 'msg': e.toString(), 'body':'ERROR, Sin conección al servidor, intentalo nuevamente.'};
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
  static void _drawErrorInConsole(http.Response response) {

    debugPrint('[ERROR]::${response.statusCode}');
    debugPrint(response.body);
  }
}