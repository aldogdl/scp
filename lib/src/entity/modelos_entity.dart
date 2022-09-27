class ModelosEntity {

  int id = 0;
  int mrkId = 0;
  String modelo = '';
  int hasChanges = 0;
  Map<String, dynamic> simyls = {'radec':'0', 'aldo':'0'};

  ///
  void fromFileAuto(Map<String, dynamic> auto, int idMrk) {

    id    = auto['id'];
    modelo = auto['nombre'];
    mrkId = idMrk;
    hasChanges = 0;
    if(auto['simyls'] != null) {
      simyls= Map<String, String>.from(auto['simyls']);
    }
  }

  ///
  void fromServer(Map<String, dynamic> auto) {

    id = auto['md_id'];
    mrkId = auto['mrk_id'];
    modelo = auto['md_nombre'];
    if(auto['md_simyls'] == null) {
      simyls = simyls;
    }else{
      simyls = Map<String, String>.from(auto['md_simyls']);
    }
    hasChanges = 0;
  }

  ///
  void fromAddNew(Map<String, dynamic> auto, int idMrk, String craw) {

    id = 0;
    mrkId = idMrk;
    modelo = auto['value'];
    hasChanges = 2;
    var sym = Map<String, String>.from(simyls);
    sym[craw] = auto['id'];
    simyls = sym;
  }

  ///
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mrkId': mrkId,
      'modelo': modelo,
      'simyls': simyls,
      'hasChanges': hasChanges
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
}