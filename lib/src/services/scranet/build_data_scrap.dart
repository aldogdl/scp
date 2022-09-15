import '../../repository/radec_repository.dart';

/// Usada solo para construir el sistema de archivos y sus contenidos
class BuildDataScrap {
  
  ///
  static Future<bool> getPiezasOf(String crow) async {

    final radecEm = RadecRepository();
    // final aldoEm = AldoRepository();
    if(crow == 'radec') {
      await radecEm.getAllPiezas();
    }
    if(crow == 'radec') {
      await radecEm.getAllPiezas();
    }
    return false;
  }
  
  ///
  static Future<bool> getMarcasOf(String crow) async {

    final radecEm = RadecRepository();
    if(crow == 'radec') {
      await radecEm.getAllMarcas();
    }
    return false;
  }

  ///
  static Future<Map<String, dynamic>> getModelosOf(String crow, String marca) async {

    final radecEm = RadecRepository();
    if(crow == 'radec') {
      return await radecEm.getModelosByMarca(marca);
    }
    return {};
  }

}