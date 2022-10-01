
class RadecEntity {

  final String uriBase = 'https://www.radec.com.mx/';
  final String uriSearch = 'catalogo/';
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

  // El año de Auto
  String codeSap = '';

  String getBaseCatalogo() => '$uriBase$uriSearch';
  String getBaseModelos() => '$uriBase$uriSearch$uriMod';
  // Ej. https://www.radec.com.mx/catalog/?type=46
  String getBaseFetchPzas() => '$uriBase$uriSearch?type=$type';

  ///
  String createQuery(Map<String, dynamic> search) {
    // https://www.radec.com.mx/catalogo?type=19&brand=AUDI&model=mid_A3&year=&btn_search=Buscar
    type  = (search.containsKey('pieza')) ? search['pieza']['id'] : '';
    brand = (search.containsKey('marca')) ? search['marca']['id'] : '';
    model = (search.containsKey('modelo')) ? 'mid_${search['modelo']['id']}' : '';
    year  = (search.containsKey('anio')) ? search['anio']['id'] : '';
    final base = getBaseCatalogo();
    return '$base?type=$type&brand=$brand&model=$model&year=$year&btn_search=Buscar';
  }
}