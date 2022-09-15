import 'dart:convert';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;

import '../entity/aldo_entity.dart';
import '../services/scranet/system_file_scrap.dart';

class RadecRepository { 

  final entity = AldoEntity();
  final className = 'aldo';
  
  ///
  Future<List<Map<String, dynamic>>> searchAutopartes(String query) async {

    List<Map<String, dynamic>> results = [];
    final dom = await getContentBy(query);
    if(dom != null) {
      final html = dom.querySelectorAll('div.category-list-products > table > tbody > tr');
      if(html.isNotEmpty) {

        for (var i = 0; i < html.length; i++) {
          final tds = html[i].querySelectorAll('td');
          if(tds.isNotEmpty) {

            var fotoBig = tds[0].querySelector('a')!.attributes['href'] ?? '';
            var fotoThum = tds[0].querySelector('a > img')!.attributes['src'] ?? '';
            var fichaTecnica = tds[3].querySelector('a')!.attributes['href'] ?? '';
            
            if(fotoBig.startsWith('/')) {
              fotoBig = '${entity.uriBase}$fotoBig';
            }

            if(fotoThum.startsWith('/')) {
              fotoThum = '${entity.uriBase}$fotoThum';
            }

            if(fichaTecnica.startsWith('/')) {
              fichaTecnica = '${entity.uriBase}$fichaTecnica';
            }

            results.add({
              'img' : fotoThum,
              'imgB': fotoBig,
              'sap' : tds[1].text.toString().trim(),
              'idP' : tds[2].text.toString().trim(),
              'pza' : tds[3].querySelector('a')!.text,
              'ftc' : fichaTecnica,
              'apps': tds[3].querySelector('div.brands-models')!.text,
              'cost': tds[4].text.toString().trim(),
            });
          }
        }
      }
    }
    return results;
  }

  /// Recuperamos el html de la pagina indicada
  Future<dom.Document?> getContentBy(String uri) async {

    http.Response res = await http.get(Uri.parse(uri));
    if(res.statusCode == 200) {
      return dom.Document.html(res.body);
    }
    return null;
  }

  /// Recuperamos el html de la pagina indicada
  Future<dom.Document?> postContentBy() async {

    final query = entity.getQuery();
    http.Response res = await http.post(
      Uri.parse(query['uri']),
      body: json.encode(query['data']),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json, text/plain, */*'
      }
    );
    if(res.statusCode == 200) {
      return dom.Document.html(res.body);
    }
    return null;
  }

  /// Recuperamos el html de la pagina indicada
  Future<Map<String, dynamic>> getApi(String uri) async {

    http.Response res = await http.get(Uri.parse(uri));
    if(res.statusCode == 200) {
      String result = res.body;
      if(result.contains('status')) {
        final jsonMap = json.decode(res.body);
        return Map<String, dynamic>.from(jsonMap);
      }
    }
    return {};
  }

  /// Recuperamos todas las piezas de la web de Radec
  Future<void> getAllPiezas(Map<String, dynamic> search) async {

    entity.fromMap(search);
    List<Map<String, String>> estruct = [];

    final body = await postContentBy();

    if(body != null) {

      final dom = body.querySelectorAll(
        'body>table:nth-child(3)>tbody>tr>td:nth-child(2)>table>tbody'
      );

      if(dom.isNotEmpty) {

        for (var i = 0; i < dom.length; i++) {

          final idV = dom[i].attributes['value'].toString().trim();
          final valueR = dom[i].innerHtml.toString().trim();
          if(idV.isNotEmpty && valueR.isNotEmpty) {
            if(!idV.contains('TODOS') && !valueR.contains('TODOS')) {
              estruct.add({'id': idV, 'value': valueR});
            }
          }
        }
      }
    }
    
    if(estruct.isNotEmpty) {
      await SystemFileScrap.setPiezasBy(className, estruct);
    }
  }

  /// Recuperamos todas las marcas de la web de Radec
  Future<void> getAllMarcas() async {

    final estruct = <Map<String, dynamic>>[];
    if(estruct.isNotEmpty) {
      await SystemFileScrap.setMarcasBy(className, estruct);
    }
  }

  /// Recuperamos todos los modelos de cada marca de la web de Radec
  Future<Map<String, dynamic>> getModelosByMarca(String marca) async {

    // Recuperamos todas las marcas desde el archivo.
    final modsWeb = await getApi('${entity.getBaseModelos()}$marca');
    if(modsWeb.containsKey('result')) {
      if(modsWeb['result'].isNotEmpty) {
        return Map<String, dynamic>.from(modsWeb['result']);
      }
    }
    return {};
  }

}