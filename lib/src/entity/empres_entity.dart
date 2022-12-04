class EmpresaEntity {

  int id = 0;
  String nombre = '';
  String domicilio = '';
  int cp = 0;
  bool isLocal = true;
  String telFijo = '';
  String latLng = '';

  ///
  Map<String, dynamic> toJson() {

    return {
      'id':id,
      'nombre':nombre,
      'domicilio':domicilio,
      'cp':cp,
      'isLocal':isLocal,
      'telFijo':telFijo,
      'latLng':latLng
    };
  }

  ///
  void fromFrmToList(Map<String, dynamic> data) {

    id = data['id'];
    nombre = data['nombre'];
    domicilio = data['domicilio'];
    cp = data['cp'];
    isLocal = data['isLocal'];
    telFijo = '${data['telFijo']}';
    latLng = data.containsKey('latLng') ? data['latLng'] : '0';
  }

  ///
  void fromServer(Map<String, dynamic> data) {

    id = data['e_id'];
    nombre = data['e_nombre'];
    domicilio = data['e_domicilio'];
    cp = data['e_cp'];
    isLocal = data['e_isLocal'];
    telFijo = '${data['e_telFijo']}';
    latLng = data['e_latLng'];
  }

  ///
  Map<String, dynamic> toJsonfromServer() {

    return {
      'e_id': id,
      'e_nombre': nombre,
      'e_domicilio': domicilio,
      'e_cp': cp,
      'e_isLocal': isLocal,
      'e_telFijo': telFijo,
      'e_latLng': latLng,
    };
  }
}