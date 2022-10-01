import 'dart:convert';
import 'package:html/dom.dart' as doc;
import 'package:http/http.dart' as http;

import '../entity/radec_entity.dart';
import '../services/scranet/system_file_scrap.dart';

class ScranetRadecRepository { 

  final entity = RadecEntity();
  final className = 'radec';
  
  /// Buscamos la pieza con marca modelo y todo
  Future<List<Map<String, dynamic>>> searchAutopartes(String query) async {

    final dom = await getContentBy(query);
    return _extraerContenidoDeTabla(dom);
  }
  
  /// Buscamos todos los resultados que conincidan con el nomnre de la pieza
  Future<List<Map<String, dynamic>>> fetchPiezas(String pieza) async {

    entity.type = pieza;

    final dom = await getContentBy(entity.getBaseFetchPzas());
    return _extraerContenidoDeTabla(dom);
  }

  ///
  List<Map<String, dynamic>> _extraerContenidoDeTabla(doc.Document? dom) {

    List<Map<String, dynamic>> results = [];

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
  Future<doc.Document?> getContentBy(String uri) async {

    late http.Response res;
    try {
      res = await http.get(Uri.parse(uri));
    } catch (_) {
      return null;
    }

    if(res.statusCode == 200) {
      
      return doc.Document.html(res.body);
    }
    return null;
  }

  /// Recuperamos el html de la pagina indicada
  Future<List<Map<String, dynamic>>> getAllElement(String tag) async {

    List<Map<String, String>> estruct = [];

    final body = await getContentBy(entity.getBaseCatalogo());

    if(body != null) {
      final dom = body.querySelectorAll(tag);
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

    return estruct;
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
  Future<void> getAllPiezas() async {

    final estruct = await getAllElement('#product_type_term > option');
    if(estruct.isNotEmpty) {
      await SystemFileScrap.setPiezasBy(className, estruct);
    }
  }

  /// Recuperamos todas las marcas de la web de Radec
  Future<void> getAllMarcas() async {

    final estruct = await getAllElement('#product_brand_term > option');
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

  ///
  Future<Map<String, dynamic>> findMarca(String marca) async {

    marca = marca.toUpperCase().trim();
    final mrks = await SystemFileScrap.getAllMarcasBy(className);
    if(mrks.isNotEmpty) {
      return mrks.firstWhere((element) => element['value'] == marca, orElse: () => {});
    }
    return {};
  }

  ///
  Future<Map<String, dynamic>> findModeloAndMarca(String modelo) async {

    modelo = modelo.toUpperCase().trim();
    final autos = await SystemFileScrap.getAllModelosBy(className);
    Map<String, dynamic> model = {};
    if(autos.isNotEmpty) {
      autos.forEach((marca, mods) {
        final fm = List<Map<String, dynamic>>.from(mods);
        var has = fm.firstWhere(
          (element) => element['value'] == modelo, orElse: () => {}
        );
        if(has.isNotEmpty) {
          model = Map<String, dynamic>.from(has);
          model['marca'] = marca;
          return;
        }
      });
    }
    return model;
  }
}