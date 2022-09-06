class ContacsEntity {

  int id = 0;
  String curc = '';
  List<String> roles = [];
  String nombre = '';
  bool isCot = true;
  String cargo = '';
  String celular = '';
  int idEmp = 0;
  String nomEmp = '';
  String domicilio = '';
  int cp = 0;
  bool isLocal = true;
  int telFijo = 0;
  String latLng = '';

  ///
  void fromServer(Map<String, dynamic> data) {

    id = data['c_id'];
    curc = data['c_curc'];
    roles = List<String>.from(data['c_roles']);
    nombre = data['c_nombre'];
    isCot = data['c_isCot'];
    cargo = data['c_cargo'];
    celular = data['c_celular'];
    idEmp = data['e_id'];
    nomEmp = data['e_nombre'];
    domicilio = data['e_domicilio'];
    cp = data['e_cp'];
    isLocal = data['e_isLocal'];
    telFijo = int.tryParse(data['e_telFijo']) ?? 0;
    latLng = data['e_latLng'];
  }
  
}