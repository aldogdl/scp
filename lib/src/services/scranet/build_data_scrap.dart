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