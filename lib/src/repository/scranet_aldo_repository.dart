import 'dart:async';
import 'package:html/dom.dart' as doc;
import 'package:http/http.dart' as http;

import '../entity/aldo_entity.dart';
import '../services/scranet/system_file_scrap.dart';

class ScranetAldoRepository { 

  final entity = AldoEntity();
  final className = 'aldo';
  bool isLoading = false;

  ///
  Future<List<Map<String, dynamic>>> searchAutopartes(String query) async {

    List<Map<String, dynamic>> results = [];
    final dom = await getContentBy(query);
    if(dom != null) {
      results = _scrapFromPageResultOfPiezas(dom);
    }
    return results;
  }

  /// Aldo no cuenta con una forma sencilla de llegar a los nombres de las piezas
  /// por lo tanto necesitamos recuperar primeramente el nombre de la pieza y
  /// entre los resultados buscar en cada marca para ver cual me entrega resultados
  /// la primera que entrege resultados la tomo y saco del ciclo de busqueda.
  Future<List<Map<String, dynamic>>> fetchPiezas(String idPza) async {

    entity.type = idPza;
    List<Map<String, dynamic>> results = [];

    var dom = await getContentBy(entity.getFetchPzas());

    if(dom != null) {

      var trs = _getAllTrsSort(dom);
      if(trs.isNotEmpty) {

        String referenciaDe = '';
        for (var i = 0; i < trs.length; i++) {

          final isA = trs[i].getElementsByTagName('a');
          if(isA.first.attributes['href'] != null) {
            if(isA.first.attributes['href']!.contains('id_articulotipo=$idPza')) {
              dom = await getContentBy('${entity.uriBase}${isA.first.attributes['href']!}');
              if(dom != null) {
                referenciaDe = isA.first.text;
                results = _scrapFromPageResultOfPiezas(dom, referenciaDe: referenciaDe);
                break;
              }
            }
          }
        }
      }
    }
    
    return results;
  }

  ///
  List<Map<String, dynamic>> _scrapFromPageResultOfPiezas
    (doc.Document dom, {String referenciaDe = ''})
  {

    List<Map<String, dynamic>> pzas = [];
    List<doc.Element> trs = _getAllTrsSort(dom);
    if(trs.isNotEmpty) {
      for (var i = 0; i < trs.length; i++) {
        Map<String, dynamic> item = {};
        item = _getImageAndHook(item, trs[i]);
        item = _getPzaNameAndId(item, trs[i]);
        item = _getCostoPza(item, trs[i]);
        if(referenciaDe.isNotEmpty) {
          item['ref'] = referenciaDe;
        }
        pzas.add(item);
      }
    }

    return pzas;
  }

  ///
  Map<String, dynamic> _getImageAndHook(Map<String, dynamic> item, doc.Element e) {

    var tag = e.getElementsByTagName('img');
    if(tag.isNotEmpty) {
      var src = tag.first.attributes['src'];
      if(src!.contains('_thumbs')) {
        item['img'] = src.trim();
        item['imgB'] = src.replaceAll('_thumbs/', '').trim();
        final hook = tag.first.attributes['alt'];
        item['sap'] = '0';
        if(hook != null) {
          item['sap'] = tag.first.attributes['alt']!.trim();
        }
      }
    }

    return item;
  }

  ///
  Map<String, dynamic> _getPzaNameAndId(Map<String, dynamic> item, doc.Element e) {

    var tag = e.getElementsByTagName('a');
    if(tag.isNotEmpty) {
      for (var i = 0; i < tag.length; i++) {
        
        var tag2 = tag[i].getElementsByTagName('img');
        if(tag2.isEmpty) {
          final ftc = tag[i].attributes['href'];
          if(ftc!.contains('id_articulo')) {
            item['ftc'] = '${entity.uriBase}$ftc';
            final partes = ftc.split('=');
            item['idP'] = partes.last.trim();
            item['pza'] = tag[i].text.trim();
            break;
          }
        }
      }
    }

    return item;
  }

  ///
  Map<String, dynamic> _getCostoPza(Map<String, dynamic> item, doc.Element e) {

    item['cost'] = '\$0';
    var tag = e.getElementsByTagName('div');
    if(tag.isNotEmpty) {
      for (var i = 0; i < tag.length; i++) {
        if(tag[i].text.startsWith('\$')) {
          item['cost'] = tag[i].text.trim();
          break;
        }
      }
    }

    return item;
  }

  ///
  List<doc.Element> _getAllTrsSort(doc.Document dom) {

    List<doc.Element> trs = [];
    List<doc.Element> trsb = dom.querySelectorAll('tr.tablegridcellb');
    List<doc.Element> trsa = dom.querySelectorAll('tr.tablegridcella');
    for (var i = 0; i < trsb.length; i++) {
      trs.add(trsb[i]);
      try {
        trs.add(trsa[i]);
      } catch (_) {
        break;
      }
    }
    return trs;
  }


  /// Recuperamos el html de la pagina indicada
  Future<doc.Document?> getContentBy(String uri) async {

    http.Response res = await http.get(Uri.parse(uri));
    if(res.statusCode == 200) {
      return doc.Document.html(res.body);
    }
    return null;
  }

  /// Recuperamos el html de la pagina indicada
  Future<doc.Document?> postContentBy({bool byModels = false}) async {

    late final Map<String, dynamic> query;
    if(byModels) {
      query = entity.getQuerySearchModels();
    }else{
      query = entity.getQuery();
    }

    late http.Response res;
    try {
      res = await http.post(
        Uri.parse(query['uri']),
        body: query['data'],
        headers: {
          'Content-type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json, text/plain, */*'
        }
      );
    } catch (e) {
      return null;
    }

    if(res.statusCode == 200) {
      return doc.Document.html(res.body);
    }
    return null;
  }

  /// Recuperamos todas las piezas y marcas de la web de Aldo
  Future<void> getAllPiezasAndMarcas() async {

    List<Map<String, String>> estruct = [];

    final body = await getContentBy(entity.getBasePzasMrks());

    if(body != null) {

      // Buscamos las piezas entre las tablas del body resultante
      var dom = body.querySelectorAll('body>table>tbody');
      dom = dom[2].querySelectorAll('tr');
      dom = dom.first.querySelectorAll('tbody');
      dom = dom.first.querySelectorAll('tr > td');

      if(dom.isNotEmpty) {

        for (var i = 0; i < dom.length; i++) {

          final link = dom[i].getElementsByTagName('a').first.attributes['href'];
          final linkP = link!.split('=');

          final idV = linkP.last.toString().trim();
          final valueR = dom[i].getElementsByTagName('a').first.innerHtml.toUpperCase().trim();

          // Despellejando Piezas
          bool isEspetial = false;
          List<String> idSpetials = ['1041', '1013', '995', '993'];
          
          if(idSpetials.contains(idV)) {

            isEspetial = true;

            // 1041 = Tapas de Defensa, de Depósitos, de Gas y Guantera
            if(idV == '1041') {
              estruct = _espetialScrapWy(estruct, valueR, idV, 'TAPAS', ' Y ');
            }

            // 1013 = Molduras Calavera Canuela Cofre Faro Puerta Rollos
            if(idV == '1013') {
              final partes = valueR.split(' ');
              final tp = partes.first.trim();
              for (var x = 0; x < partes.length; x++) {
                String pza = partes[x].trim();
                if(!pza.startsWith(tp)) {
                  pza = '$tp $pza';
                }
                final has = estruct.where((element) => element['value'] == pza);
                if(has.isEmpty) {
                  estruct.add({'id': idV, 'value': pza});
                }
              }
            }

            // 995 = Manijas Exteriores de Puerta y de Tapa de Caja
            if(idV == '995') {
              estruct = _espetialScrapWy(estruct, valueR, idV, 'MANIJAS EXTERIORES', ' Y ');
            }

            // 993 = Manijas Elevador de Cristal e Interior de Puerta
            if(idV == '995') {
              estruct = _espetialScrapWy(estruct, valueR, idV, 'MANIJAS ELEVADOR', ' E ');
            }

          }

          if(!isEspetial) {

            if(valueR.contains(',')) {

              // Ej. Puertas, Tapas Caja, Tapas Cajuela y Chicotes
              final partes = valueR.split(',');
              if(partes.isNotEmpty) {

                List<String> piezas = [];
                // El primer recorrido es para buscar las Y
                for (var a = 0; a < partes.length; a++) {
                  if(partes[a].contains(' Y ')) {
                    final pedazos = partes[a].split(' Y ');
                    piezas.addAll(pedazos);
                  }else{
                    piezas.add(partes[a]);
                  }
                }

                for (var b = 0; b < piezas.length; b++) {

                  final valor = piezas[b].trim();
                  if(idV.isNotEmpty && valor.isNotEmpty) {
                    if(!idV.contains('TODOS') && !valor.contains('TODOS')) {
                      final has = estruct.where((element) => element['value'] == valor);
                      if(has.isEmpty) {
                        estruct.add({'id': idV, 'value': valor});
                      }
                    }
                  }
                }
              }
              
            }else{

              if(idV.isNotEmpty && valueR.isNotEmpty) {
                if(!idV.contains('TODOS') && !valueR.contains('TODOS')) {
                  estruct.add({'id': idV, 'value': valueR});
                }
              }
            }
          }
        }
      }

      if(estruct.isNotEmpty) {
        await SystemFileScrap.setPiezasBy(className, estruct);
      }

      await _scrapMarcas(body);
    }
    
  }

  /// Escarbamos entre el dom las marcas y las guardamos en el archivo
  Future<void> _scrapMarcas(doc.Document body) async {

    List<Map<String, String>> estruct = [];
    List<doc.Element> dom = body.querySelectorAll('#id_marca > option');
    if(dom.isNotEmpty) {

      for (var i = 0; i < dom.length; i++) {

        List<String> partes = [];
        final idV = dom[i].attributes['value'].toString().trim();
        final valueR = dom[i].innerHtml.toString().trim().toUpperCase();
        if(valueR.contains('/')) {
          partes = valueR.split('/');
          for (var a = 0; a < partes.length; a++) {
            if(idV.isNotEmpty && partes[a].isNotEmpty) {
              if(!idV.contains('TODOS') && !partes[a].contains('TODOS')) {
                estruct.add({'id': idV, 'value': partes[a].trim()});
              }
            }
          }
        }else{
          if(idV.isNotEmpty && valueR.isNotEmpty) {
            if(!idV.contains('TODOS') && !valueR.contains('TODOS')) {
              estruct.add({'id': idV, 'value': valueR});
            }
          }
        }
      }
    }

    if(estruct.isNotEmpty) {
      await SystemFileScrap.setMarcasBy(className, estruct);
    }
  }

  /// Tratamos las piezas que continen el nombre de la refacción como paralabra
  /// inicial y el resto son comas o conjunciones (Y o E = sep)
  /// el parametro p es el nombre de la pieza que hay que adjuntar a las demas 
  List<Map<String, String>> _espetialScrapWy
    (List<Map<String, String>> estruct, String valueR, String idV, String p, String sep)
  {
    var partes = valueR.split(sep);
    var pedazos= partes.first.split(',');
    partes.removeAt(0);
    List<String> piezas = [];
    piezas.addAll(partes);
    piezas.addAll(pedazos);
    for (var a = 0; a < piezas.length; a++) {

      String pza = piezas[a].trim();
      if(!pza.startsWith(p)) {
        pza = '$p $pza';
      }
      final has = estruct.where((element) => element['value'] == pza);
      if(has.isEmpty) {
        estruct.add({'id': idV, 'value': pza});
      }
    }
    return estruct;
  }

  /// Recuperamos todos los modelos de cada marca de la web de Aldo
  Future<List<Map<String, dynamic>>> getModelosByMarca(Map<String, dynamic> marca) async {

    entity.fromMap({'marca': {'id':marca['id']} });
    doc.Document? body;

    if(!isLoading) {
      isLoading = true;
      body = await postContentBy(byModels: true);
      if(body != null) {

        List<Map<String, dynamic>> modelos = [];
        var dom = body.querySelectorAll('#id_modelo option');      
        for (var i = 0; i < dom.length; i++) {

          final idV = dom[i].attributes['value'].toString().trim().toUpperCase();
          var valueR = dom[i].text.toUpperCase().trim();

          if(idV.isNotEmpty) {
            if(valueR.contains(marca['value'])) {
              valueR = valueR.replaceAll(marca['value'], '');
            }
            valueR = valueR.trim();
            if(valueR.isNotEmpty) {
              final has = modelos.where((element) => element['value'] == valueR);
              if(has.isEmpty) {
                modelos.add({'id': idV, 'value': valueR});
              }
            }
          }
        }
        isLoading = false;
        return modelos;
      }
    }
    
    return [];
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