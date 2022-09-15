
class AldoEntity {
  
  final String uriBase = 'http://aldoautopartes.com/';
  final String uriSearch = 'pi_resultados.jsp';
  // El Uri de la ficha tecnica de la pieza parametro "/code_sap" -> Código SAP
  final String uriFt = 'producto';
  // El uri para recuperar los modelos de cada marca parametro "/MARCA"
  final String uriMod= 'marca/';

  // Los campos requeridos para armar el request

  // El Id interno de la pieza
  // String id_articulogrupo = '';
  // // La marca de Auto
  // String id_articulotipo = '';
  // El modelo de Auto
  String model = '';
  // El año de Auto
  String year = '';

  // El año de Auto
  String codeSap = '';


  String getBaseCatalogo() => '$uriBase$uriSearch';
  String getBaseModelos() => '$uriBase$uriSearch$uriMod';

  ///
  String createQuery(Map<String, dynamic> search) {

    // http://www.aldoautopartes.com/pi_resultados.jsp?id_articulogrupo=228&id_articulotipo=968
    // type  = (search.containsKey('pieza')) ? search['pieza']['id'] : '';
    // brand = (search.containsKey('marca')) ? search['marca']['id'] : '';
    // model = (search.containsKey('modelo')) ? search['modelo']['id'] : '';
    // year  = (search.containsKey('anio')) ? search['anio']['id'] : '';
    final base = getBaseCatalogo();
    return ''; // '$base?type=$type&brand=$brand&model=mid_$model&year=$year&btn_search=Buscar';
  }
}