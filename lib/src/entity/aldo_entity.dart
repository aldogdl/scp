
class AldoEntity {
  
  final String uriBase = 'http://aldoautopartes.com/';
  final String uriSearch = 'pi_resultados.jsp';
  final String uriPzasMrks = 'pi_busqueda.jsp';
  
  // El Uri de la ficha tecnica de la pieza parametro "/code_sap" -> Código SAP
  final String uriFt = 'producto';
  // El uri para recuperar los modelos de cada marca parametro "/MARCA"
  final String uriMod= 'marca/';

  // Los campos requeridos para armar el request

  // El Id interno de la pieza
  String type = '';
  // La marca de Auto
  String brand = '';
  // El modelo de Auto
  String model = '';
  // El año de Auto
  String year = '';

  // El Id interno de la pieza
  String codeSap = '';

  String getBaseCatalogo() => '$uriBase$uriSearch';
  String getBaseModelos() => '$uriBase$uriSearch$uriMod';
  String getBasePzasMrks() => '$uriBase$uriPzasMrks';

  ///
  void fromMap(Map<String, dynamic> search) {

    type  = (search.containsKey('pieza')) ? search['pieza']['id'] : '';
    brand = (search.containsKey('marca')) ? search['marca']['id'] : '';
    model = (search.containsKey('modelo')) ? search['modelo']['id'] : '';
    year  = (search.containsKey('anio')) ? search['anio']['id'] : '';
  }

  /// 
  Map<String, dynamic> getQuerySearchModels() {

    return {
      'uri' : getBasePzasMrks(),
      'data': {
        '_action': '1', 'id_marca': brand, 'id_modelo': model, 'anio': year
      }
    };
  }

  /// http://www.aldoautopartes.com/pi_resultados.jsp?id_articulogrupo=228&id_articulotipo=968
  Map<String, dynamic> getQuery() {

    return {
      'uri' : getBaseCatalogo(),
      'data': {
        '_action': '1', 'id_marca': brand, 'id_modelo': model, 'anio': year
      }
    };
  }
}