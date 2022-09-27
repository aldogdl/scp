class MarcasEntity {

  int id = 0;
  String marca = '0';
  String logo = '0';
  String grupo = 'b';
  int hasChanges = 0;
  Map<String, String> simyls = {'radec' : '0', 'aldo'  : '0'};

  ///
  void fromFile(Map<String, dynamic> auto) {

    id    = auto['mrk_id'];
    marca = auto['mrk_nombre'];
    logo  = auto['mrk_logo'];
    grupo = (auto['mrk_grupo'] == '') ? 'b' : auto['mrk_grupo'];
    hasChanges = (auto.containsKey('hasChanges')) ? auto['hasChanges'] : 0;
    simyls  = Map<String, String>.from(auto['mrk_simyls']);
  }

  ///
  void fromJson(Map<String, dynamic> auto) {

    id    = auto['id'];
    marca = auto['marca'];
    logo  = auto['logo'];
    grupo = (auto['grupo'] == '') ? 'b' : auto['grupo'];
    hasChanges = auto['hasChanges'];
    simyls= auto['simyls'];
  }

  ///
  void fromFileAuto(Map<String, dynamic> auto) {

    id    = auto['id'];
    marca = auto['nombre'];
    logo  = auto['logo'];
    grupo = (auto['grupo'] == '') ? 'b' : auto['grupo'];
    hasChanges = 0;
    simyls= Map<String, String>.from(auto['simyls']);
  }

  ///
  Map<String, dynamic> toJson() {

    return {
      'id'     : id,
      'marca'  : marca,
      'logo'   : logo,
      'grupo'  : grupo,
      'simyls' : simyls,
      'hasChanges': hasChanges,
    };
  }

  ///
  String getTipoCambio(int change) {

    switch (change) {
      case 1:
        return 'Cambios de Edición';
      case 2:
        return 'Nueva Marca';
      case 3:
        return 'Agregando Crawler';
      case 4:
        return 'Marca Eliminada';
      default:
        return 'Sin Cambios';
    }
  }

  ///
  void fromAddNew(Map<String, dynamic> marcaNew, String similar) {

    id    = 0;
    marca = marcaNew['value'];
    logo  = '0';
    grupo = 'b';
    hasChanges = 2;
    simyls = {'radec': '0', 'aldo': '0'};
    simyls[similar] = marcaNew['id'];
  }
}