class PiezasEntity {

  int id = 0;
  String est = '0';
  String stt = '0';
  String piezaName = '0';
  String origen = '0';
  String lado = '0';
  String posicion = '0';
  List<String> fotos = [];
  String obs = '0';
  int orden = 0;

  ///
  void fromScreen(Map<String, dynamic> json) {

    id = json['id'];
    est = json['est'];
    stt = json['stt'];
    piezaName = json['piezaName'];
    origen = json['origen'];
    lado = json['lado'];
    posicion = json['posicion'];
    fotos = json['fotos'];
    obs = json['obs'];
    orden = json['orden'];
  }

  ///
  void fromServer(Map<String, dynamic> data) {
    id = data['p_id'];
    est = data['p_est'];
    stt = data['p_stt'];
    piezaName = data['p_piezaName'];
    origen = data['p_origen'];
    lado = data['p_lado'];
    posicion = data['p_posicion'];
    fotos = (data['p_fotos'].isNotEmpty) ? List<String>.from(data['p_fotos']) : [];
    obs = data['p_obs'];
    var ordenN = data['o_id'];
    if(ordenN.runtimeType == String) {
      orden = int.tryParse(data['o_id']) ?? 0;
    }else{
      orden = data['o_id'];
    }
  }

  ///
  void fromFile(Map<String, dynamic> json, int indexOrden) {

    id = json['id'];
    est = json['est'];
    stt = json['stt'];
    piezaName = json['piezaName'];
    origen = json['origen'];
    lado = json['lado'];
    posicion = json['posicion'];
    fotos = List<String>.from(json['fotos']);
    obs = json['obs'];
    orden = json['orden'];
    indexOrden = indexOrden;
  }

  ///
  Map<String, dynamic> toJson() {

    return {
      'id': id,
      'est': est,
      'stt': stt,
      'piezaName': piezaName,
      'origen': origen,
      'lado': lado,
      'posicion': posicion,
      'fotos': fotos,
      'obs': obs,
      'orden': orden
    };
  }

  ///
  Map<String, dynamic> status() => {'est': est, 'stt': stt};

}