import 'package:scp/src/entity/aldo_entity.dart';
import 'package:scp/src/entity/radec_entity.dart';

import 'system_file_scrap.dart';
import '../../repository/scranet_aldo_repository.dart';
import '../../repository/scranet_radec_repository.dart';

/// Usada solo para construir el sistema de archivos y sus contenidos
class BuildDataScrap {
  
  static Stream<String> buildData() async* {

    yield 'Sistema de Archivos ScraNet';
    await SystemFileScrap.buildFileSystem();

    yield 'Revisando datos principales [ScraNet]';
    String res = await SystemFileScrap.chekSystem(craw: 'radec');
    if(res != 'ok') {
      yield '...';
      return;
    }
    yield 'Datos de Proveedor Aldo-[ScraNet]';
    res = await SystemFileScrap.chekSystem(craw: 'aldo');
    // if(res != 'ok') {
    //   yield '...';
    //   return;
    // }
  }

  ///
  static Future<bool> getPiezasOf(String crow) async {

    if(crow == 'radec') {
      final radecEm = ScranetRadecRepository();
      await radecEm.getAllPiezas();
    }

    if(crow == 'aldo') {
      final aldoEm = ScranetAldoRepository();
      await aldoEm.getAllPiezasAndMarcas();
    }
    return false;
  }
  
  ///
  static Future<List<Map<String, dynamic>>> fetchPiezasOf
    (String crow, String idPza, String mrkMod) async
  {

    String query = '';
    mrkMod = mrkMod.toUpperCase().trim();

    if(crow == 'radec') {

      final radecEm = ScranetRadecRepository();
      if(mrkMod.isNotEmpty) {

        final entity = RadecEntity();
        var auto = await radecEm.findMarca(mrkMod);
        if(auto.isEmpty) {
          auto = await radecEm.findModeloAndMarca(mrkMod);
          if(auto.isNotEmpty) {
            query  = entity.createQuery({
              'pieza': {'id': idPza}, 'marca': {'id': auto['marca']},
              'modelo': {'id': auto['id']}
            });
          }
        }else{
          query  = entity.createQuery({
            'pieza': {'id': idPza}, 'marca': {'id': auto['id']},
          });
        }
        return await radecEm.searchAutopartes(query);
      }else{
        return await radecEm.fetchPiezas(idPza);
      }
    }

    if(crow == 'aldo') {

      final aldoEm = ScranetAldoRepository();
      if(mrkMod.isNotEmpty) {

        final entity = AldoEntity();
        var auto = await aldoEm.findMarca(mrkMod);
        if(auto.isEmpty) {

          auto = await aldoEm.findModeloAndMarca(mrkMod);
          if(auto.isNotEmpty) {
            entity.fromMap({
              'pieza': {'id': idPza}, 'marca': {'id': auto['marca']},
              'modelo': {'id': auto['id']}
            });
          }
        }else{
          entity.fromMap({
            'pieza': {'id': idPza}, 'marca': {'id': auto['id']},
          });
        }

        query = entity.getPzasDeUnMarca();
        return await aldoEm.searchAutopartes(query);
      }else{
        return await aldoEm.fetchPiezas(idPza);
      }
    }
    return [];
  }
  
  ///
  static Future<bool> getMarcasOf(String crow) async {

    if(crow == 'radec') {
      final radecEm = ScranetRadecRepository();
      await radecEm.getAllMarcas();
    }
    return false;
  }

  ///
  static Future<Map<String, dynamic>> getModelosOf(String crow, Map<String, dynamic> marca) async {

    if(crow == 'radec') {
      final radecEm = ScranetRadecRepository();
      return await radecEm.getModelosByMarca(marca['id']);
    }

    if(crow == 'aldo') {
      final aldoEm = ScranetAldoRepository();
      final mods = await aldoEm.getModelosByMarca(marca);
      return {'m': mods};
    }
    return {};
  }

}